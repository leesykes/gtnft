//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./HexStrings.sol";

contract GTNFT is ERC721Enumerable {
    using Strings for uint256;
    using HexStrings for uint160;

    uint256 private _currentTokenId;

    // --- CONFIGURATION ---
    // NOTE: For production, consider making the recipient and limit configurable in the constructor.
    address payable public constant RECIPIENT = payable(0x22386b2cDF019E327Fbd007790a1c27a1411C9A2);
    uint256 public constant COLLECTION_LIMIT = 3728;
    uint256 public constant CURVE_BPS = 1002; // Price increase 0.2% with each purchase (100.2%)
    uint256 public price = 0.001 ether;

    // --- ART CONSTANTS ---
    uint16 private constant CANVAS_SIZE = 512;
    uint8 constant CHANCE_OF_SPLIT = 70; // 70%
    uint8 constant CHANCE_OF_DRAW = 40; // 40%

    // --- TRAITS MAPPING ---
    // GAS SAVING: Traits are packed into a single uint8 to save storage slots.
    // Bits 0-1: palette (4 options)
    // Bits 2-3: complexity (4 options)
    // Bits 4-5: feature (3 options)
    mapping(uint256 => uint8) public traits;

    // NOTE: ERC721Enumerable adds significant gas overhead to mint and transfers.
    // Do we need on-chain enumeration, using the base ERC721 ischeaper.
    constructor() ERC721("GenerativeTilingNFT", "GTNFT") {}

    function mintItem() public payable returns (uint256) {
        require(_currentTokenId < COLLECTION_LIMIT, "Collection is fully minted");
        require(msg.value >= price, "Not enough Ether sent");

        price = (price * CURVE_BPS) / 1000;
        _currentTokenId += 1;

        // --- TRAIT GENERATION & PACKING ---
        // SECURITY/GAS: Hash is based on the immutable tokenId.
        bytes32 predictableRandom = keccak256(abi.encodePacked(_currentTokenId, address(this)));

        uint8 palette = uint8(uint256(uint8(predictableRandom[0])) % 4);
        uint8 complexity = uint8(uint256(uint8(predictableRandom[1])) % 4);
        uint8 feature = uint8(uint256(uint8(predictableRandom[2])) % 3);

        // GAS SAVING: Pack all traits into one uint8 and write to storage once.
        uint8 packedTraits = (feature << 4) | (complexity << 2) | palette;
        traits[_currentTokenId] = packedTraits;

        _mint(msg.sender, _currentTokenId);

        // SECURITY: Follows Checks-Effects-Interactions pattern.
        (bool success, ) = RECIPIENT.call{ value: msg.value }("");
        require(success, "Failed to send Ether");

        return _currentTokenId;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf(id) != address(0), "Token does not exist");

        // --- TRAIT UNPACKING ---
        uint8 packedTraits = traits[id];
        uint8 paletteId = packedTraits & 0x03; // 00000011
        uint8 complexityId = (packedTraits >> 2) & 0x03; // 00001100 -> 00000011
        uint8 featureId = (packedTraits >> 4) & 0x03; // 00110000 -> 00000011

        // --- IN-MEMORY DATA (Saves gas) ---
        string[4] memory paletteNames = ["Vibrant", "Forest", "Synthwave Gradient", "Yin & Yang"];
        string[4] memory styleNames = ["Bold", "Detailed", "Hyper-Detailed", "Infinite Detail"];
        string[3] memory featureNames = ["Plain", "Gradient", "Shimmer"];

        string memory name = string(abi.encodePacked("Generative Tiling NFT #", id.toString()));

        string memory description = string(
            abi.encodePacked(
                "A unique, on-chain generative artwork. Style: ",
                styleNames[complexityId],
                ", Palette: ",
                paletteNames[paletteId],
                ", Feature: ",
                featureNames[featureId],
                "."
            )
        );

        string memory image = Base64.encode(bytes(generateSVGofTokenById(id, paletteId, complexityId, featureId)));

        // GAS SAVING: Build the final JSON in fewer, larger steps.
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "attributes": [',
                                '{"trait_type": "Palette", "value": "',
                                paletteNames[paletteId],
                                '"},',
                                '{"trait_type": "Style", "value": "',
                                styleNames[complexityId],
                                '"},',
                                '{"trait_type": "Feature", "value": "',
                                featureNames[featureId],
                                '"}',
                                '], "image": "data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    struct RenderContext {
        uint256 id;
        uint8 paletteId;
        uint8 complexityId;
        uint8 featureId;
    }

    function generateSVGofTokenById(
        uint256 id,
        uint8 paletteId,
        uint8 complexityId,
        uint8 featureId
    ) internal view returns (string memory) {
        RenderContext memory ctx = RenderContext(id, paletteId, complexityId, featureId);
        string memory artContent = _renderRecursive(ctx, 0, 0, CANVAS_SIZE, 0);
        string memory defsAndStyles = _getDefsAndStyles(paletteId, featureId);

        return
            string(
                abi.encodePacked(
                    '<svg width="',
                    uint256(CANVAS_SIZE).toString(),
                    '" height="',
                    uint256(CANVAS_SIZE).toString(),
                    '" viewBox="0 0 ',
                    uint256(CANVAS_SIZE).toString(),
                    " ",
                    uint256(CANVAS_SIZE).toString(),
                    '" xmlns="http://www.w3.org/2000/svg">',
                    defsAndStyles,
                    '<rect width="100%" height="100%" fill="#1a1a1a"/>',
                    artContent,
                    "</svg>"
                )
            );
    }

    function _getPaletteColors(uint8 paletteId) internal pure returns (string[] memory) {
        string[] memory colors;

        if (paletteId == 0) {
            // Vibrant
            colors = new string[](4);
            colors[0] = "#ffbe0b";
            colors[1] = "#ff006e";
            colors[2] = "#8338ec";
            colors[3] = "#3a86ff";
        } else if (paletteId == 1) {
            // Forest
            colors = new string[](4);
            colors[0] = "#264653";
            colors[1] = "#2a9d8f";
            colors[2] = "#e9c46a";
            colors[3] = "#2a9d8f";
        } else if (paletteId == 2) {
            // Synthwave
            colors = new string[](4);
            colors[0] = "#ff006e";
            colors[1] = "#3a86ff";
            colors[2] = "#ff006e";
            colors[3] = "#3a86ff";
        } else {
            // Yin & Yang
            colors = new string[](4);
            colors[0] = "#FFFFFF";
            colors[1] = "#000000";
            colors[2] = "#FFFFFF";
            colors[3] = "#000000";
        }

        return colors;
    }

    function _getDefsAndStyles(uint8 paletteId, uint8 featureId) internal pure returns (string memory) {
        if (featureId == 0) return ""; // Plain

        string[] memory colors = _getPaletteColors(paletteId);
        string memory defs;
        string memory styles;

        if (featureId == 1) {
            // Gradient
            defs = string(
                abi.encodePacked(
                    '<defs><linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">',
                    '<stop offset="0%" stop-color="',
                    colors[0],
                    '"/>',
                    '<stop offset="100%" stop-color="',
                    colors[1],
                    '"/>',
                    "</linearGradient></defs>"
                )
            );
        }
        if (featureId == 2) {
            // Shimmer
            styles = string(
                abi.encodePacked(
                    "<style>.s { animation: shimmer 4s infinite ease-in-out; } @keyframes shimmer {",
                    "0% { fill: ",
                    colors[0],
                    "; }",
                    "33% { fill: ",
                    colors[1],
                    "; }",
                    "66% { fill: ",
                    colors[2],
                    "; }",
                    "100% { fill: ",
                    colors[0],
                    "; }",
                    "}</style>"
                )
            );
        }
        return string(abi.encodePacked(defs, styles));
    }
    function _renderRecursive(
        RenderContext memory ctx,
        uint16 x,
        uint16 y,
        uint16 size,
        uint8 depth
    ) internal view returns (string memory) {
        bytes32 seed = keccak256(abi.encodePacked(ctx.id, x, y));
        if (depth > 0 && (depth > ctx.complexityId || (uint8(seed[0]) % 100) > CHANCE_OF_SPLIT)) {
            if ((uint8(seed[1]) % 100) > CHANCE_OF_DRAW) {
                return _drawLeaf(ctx, x, y, size, seed);
            }
            return "";
        }

        uint16 newSize = size / 2;
        uint8 newDepth = depth + 1;
        return
            string(
                abi.encodePacked(
                    _renderRecursive(ctx, x, y, newSize, newDepth),
                    _renderRecursive(ctx, x + newSize, y, newSize, newDepth),
                    _renderRecursive(ctx, x, y + newSize, newSize, newDepth),
                    _renderRecursive(ctx, x + newSize, y + newSize, newSize, newDepth)
                )
            );
    }

    function _drawLeaf(
        RenderContext memory ctx,
        uint16 x,
        uint16 y,
        uint16 size,
        bytes32 seed
    ) internal pure returns (string memory) {
        string[] memory colors = _getPaletteColors(ctx.paletteId);
        string memory fill = ctx.featureId == 1 ? "url(#grad)" : colors[uint8(seed[2]) % colors.length];
        string memory cssClass = ctx.featureId == 2 ? ' class="s"' : "";
        string memory delay = ctx.featureId == 2
            ? string(
                abi.encodePacked(' style="animation-delay:', uint256((uint8(seed[3]) % 1500) * 10).toString(), 'ms"')
            )
            : "";

        return
            string(
                abi.encodePacked(
                    '<circle cx="',
                    uint256(x + size / 2).toString(),
                    '" cy="',
                    uint256(y + size / 2).toString(),
                    '" r="',
                    uint256(size / 2).toString(),
                    '" fill="',
                    fill,
                    '"',
                    cssClass,
                    delay,
                    "/>"
                )
            );
    }
}
