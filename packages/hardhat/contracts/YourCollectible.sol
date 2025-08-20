//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

import "./HexStrings.sol";
import "./ToColor.sol";

import "hardhat/console.sol";

//learn more: https://docs.openzeppelin.com/contracts/5.x/erc721

contract YourCollectible is ERC721Enumerable {
    using Strings for uint256;
    using HexStrings for uint160;
    using ToColor for bytes3;
    uint256 private _currentTokenId;

    //const for svg image
    uint16 private constant CANVAS_SIZE = 200;

    // all funds go to leesykes.eth
    address payable public constant recipient = payable(0x22386b2cDF019E327Fbd007790a1c27a1411C9A2);

    uint256 public constant limit = 3728;
    uint256 public constant curve = 1002; // price increase 0,2% with each purchase
    uint256 public price = 0.001 ether;
    // the 1154th optimistic GTNFT cost 0.01 ETH, the 2306th cost 0.1ETH, the 3459th cost 1 ETH and the last ones cost 1.7 ETH

    uint8 constant CHANCE_OF_SPLIT = 70; // 70% chance of splitting a tile into 4 smaller tiles
    uint8 constant CHANCE_OF_DRAW = 40;


      // --- TRAIT DEFINITIONS ---
    string[] backgrounds = ["#1a1a1a", "#2d2d2d", "#22333b"];
    string[] backgroundNames = ["Obsidian", "Charcoal", "Deep Water"];
//    uint8[] backgroundWeights = [50, 15, 15];
    
    string[][] palettes = [
        ["#ffbe0b", "#ff006e", "#8338ec", "#3a86ff"], // Vibrant
        ["#264653", "#2a9d8f", "#e9c46a", "#2a9d8f"], // Forest
        ["#ff006e", "#3a86ff", "#ff006e", "#3a86ff"], // Synthwave
        ["#FFFFFF", "#000000", "#FFFFFF", "#000000"]  // Yin & Yang
    ];
    string[] paletteNames = ["Vibrant", "Forest", "Synthwave Gradient", "Yin & Yang"];

    string[] styleNames = ["Bold","Detailed", "Hyper-Detailed", "Infinite Detail"];
//    uint8[] paletteWeights = [40, 40, 5, 10];

enum Feature {
    Plain,
    Gradient,
    Shimmer
}

    string[] featureNames = ["Plain", "Gradient", "Shimmer"];

    struct Traits {
      //  bytes3 color;
        uint8 palette;
        uint8 complexity;
        Feature feature;
    }
    mapping(uint256 => Traits) public traits;

    constructor() ERC721("GenerativeTilingNFT", "GTNFT") {
        // RELEASE THE TITLES!!
    }

    function mintItem() public payable returns (uint256) {
        require(_currentTokenId < limit, "DONE MINTING");
        require(msg.value >= price, "NOT ENOUGH");

        price = (price * curve) / 1000;

        _currentTokenId += 1;

        _mint(msg.sender, _currentTokenId);

        bytes32 predictableRandom = keccak256(
            abi.encodePacked(_currentTokenId, blockhash(block.number - 1), msg.sender, address(this))
        );

        traits[_currentTokenId].palette = uint8(( paletteNames.length * uint256(uint8(predictableRandom[0]))) / 255);
        traits[_currentTokenId].complexity  = (uint8(( 4 * uint256(uint8(predictableRandom[1]))) / 255) );
        traits[_currentTokenId].feature  = Feature((( 3 * uint256(uint8(predictableRandom[2]))) / 255));

        (bool success, ) = recipient.call{ value: msg.value }("");
        require(success, "could not send");

        return _currentTokenId;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf(id) != address(0), "not exist");

        Traits memory trait = traits[id];

        string memory name = string(abi.encodePacked("GenerativeTilingNFT #", id.toString()));
        string memory description = string(
            abi.encodePacked(
                "This GTNFT is pallette: ",
                paletteNames[ trait.palette ],
                " with style: ",
                styleNames[ trait.complexity ],
                " and feature: ",
                featureNames[ uint8(trait.feature) ],
                "."
            )
        );
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

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
                                '", "external_url":"https://burnyboys.com/token/',
                                id.toString(),
                                '", "attributes": [{"trait_type": "pallette", "value":"',
                                paletteNames[ trait.palette ],
                                '"},{"trait_type": "style", "value":"',
                                styleNames[ trait.complexity ],
                                '"},{"trait_type": "feature", "value":"',
                                featureNames[ uint8(trait.feature) ],
                                '"}], "owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

   function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
           string memory svg = string(abi.encodePacked(
            //   '<?xml version="1.0" standalone="no"?>',
            '<svg width="', uint256(CANVAS_SIZE).toString(), '" height="', uint256(CANVAS_SIZE).toString(), 
                '" viewBox="0 0 ', uint256(CANVAS_SIZE).toString(), ' ', uint256(CANVAS_SIZE).toString(), 
                '" xmlns="http://www.w3.org/2000/svg">',
                // '<rect width="100%" height="100%" fill="', dna.background, '"/>'
                '<rect width="100%" height="100%" fill="#1a1a1a"/>',
                renderTokenById(id),
            '</svg>'
        ));

        return svg;
   }


    function renderTokenById(uint256 id) public view returns (string memory) {
    Traits memory nftTrait = traits [id];
    string memory svg;

    // keccak-based predictable random seed array
    bytes32 base = keccak256(
    //  abi.encodePacked(id, blockhash(block.number - 1), msg.sender, address(this))
        abi.encodePacked(id, address(this))
    );
        

     if (nftTrait.feature != Feature.Plain) {
            svg = string(abi.encodePacked(
                svg,
                '<defs>',
                '<linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">',
                    '<stop offset="0%" stop-color="', palettes[nftTrait.palette][0], '" stop-opacity="1"/>',
                    '<stop offset="50%" stop-color="', palettes[nftTrait.palette][1], '" stop-opacity="0.6"/>',
                    '<stop offset="100%" stop-color="', palettes[nftTrait.palette][2], '" stop-opacity="1"/>',
                '</linearGradient>',
                '</defs>',
                 ' <style>',
                    ' .twinkle {',
                    ' animation: twinkle 3s infinite;',
                    '}',
                    '@keyframes twinkle {',
                    '0%   { fill: ', palettes[nftTrait.palette][0], '; }',
                    '33%  { fill: ', palettes[nftTrait.palette][1], '; }',
                    '66%  { fill: ', palettes[nftTrait.palette][2], '; }',
                    '100%  { fill: ', palettes[nftTrait.palette][3], '; }',
                    '}',
                    '</style>'
            ));
     }

      
        (string memory content, ) = _renderRecursive( nftTrait, base, 0, 0, 0, CANVAS_SIZE, 0);
        svg = string(abi.encodePacked(svg, content));
        return svg;
    }

        // Keccak-based number generator (derives a uint from a base seed and nonce)
    function _rand(bytes32 base, uint256 nonce) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(base, nonce)));
    }

    function _renderRecursive(
        Traits memory nftTrait,
        bytes32 base,
        uint32 nonce,
        uint16 x,
        uint16 y,
        uint16 size,
        uint8 depth
    ) internal view returns (string memory out, uint32 nextNonce) {

        //Should we end or sub divide (and always diveide on first level)
        if ((!(depth < 1)) && (depth > nftTrait.complexity || ((_rand( base, nonce  ) % 100 ) > CHANCE_OF_SPLIT ) )) {

            

            //What should we draw - shoudl select from tile type set not just yes or no
            if ((_rand( base, nonce + 1 ) % 100 ) >   CHANCE_OF_DRAW )
             {

//Select random colour for tile from pallette trait or use gradient
            uint256 colorIdx = _rand(base, nonce + 1) % palettes[ nftTrait.palette ].length;
            string memory fill =  nftTrait.feature == Feature.Gradient ? 'url(#grad)' : palettes[nftTrait.palette][colorIdx];


            return (
                string(abi.encodePacked(
                    '<circle cx="', uint256(x + size / 2).toString(),
                    '" cy="', uint256(y + size / 2).toString(),
                    '" r="', uint256(size / 2).toString(),
                   nftTrait.feature == Feature.Shimmer ? '" class="twinkle' : "",
                   '" style="animation-delay: ', (_rand(base, nonce + 1) % 1500).toString() , 'ms ',
                    '" fill="', fill, '"/>'
          
                )),
                nonce + 2
            );
             }
            else{
                return("", nonce + 2);
            }
        }

        uint16 newSize = size / 2;
        uint8 newDepth = depth + 1;

        string memory a; string memory b; string memory c; string memory d;
        uint32 n;
        (a, n) = _renderRecursive( nftTrait, base, nonce + 3, x, y, newSize, newDepth);
        (b, n) = _renderRecursive( nftTrait, base, n, x + newSize, y, newSize, newDepth);
        (c, n) = _renderRecursive( nftTrait, base, n, x, y + newSize, newSize, newDepth);
        (d, n) = _renderRecursive( nftTrait, base, n, x + newSize, y + newSize, newSize, newDepth);

        return (string(abi.encodePacked(a, b, c, d)), n);
    }

}

/*


pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./HexStrings.sol";

// This contract is an example and has not been audited. Use at your own risk.

contract YourCollectible is ERC721Enumerable {
    using Strings for uint256;
    using HexStrings for uint160;

    uint256 private _currentTokenId;

    // --- CONFIGURATION ---
    // NOTE: For production, consider making the recipient and limit configurable in the constructor.
    address payable public constant RECIPIENT = payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);
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

    // NOTE: ERC721Enumerable adds significant gas overhead to mints and transfers.
    // If you don't need on-chain enumeration, using the base ERC721 is much cheaper.
    constructor() ERC721("GenerativeTilingNFT", "GTNFT") {}

    function mintItem() public payable returns (uint256) {
        require(_currentTokenId < COLLECTION_LIMIT, "Collection is fully minted");
        require(msg.value >= price, "Not enough Ether sent");

        price = (price * CURVE_BPS) / 1000;
        _currentTokenId += 1;

        // --- TRAIT GENERATION & PACKING ---
        // SECURITY/GAS: Hash is based on the immutable tokenId, which is safer than blockhash and cheaper.
        bytes32 predictableRandom = keccak256(abi.encodePacked(_currentTokenId, address(this)));

        // Modulo is slightly cheaper and clearer than the previous division method.
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
        require(_exists(id), "Token does not exist");

        // --- TRAIT UNPACKING ---
        uint8 packedTraits = traits[id];
        uint8 paletteId = packedTraits & 0x03;        // 00000011
        uint8 complexityId = (packedTraits >> 2) & 0x03; // 00001100 -> 00000011
        uint8 featureId = (packedTraits >> 4) & 0x03;   // 00110000 -> 00000011

        // --- IN-MEMORY DATA (Saves huge amounts of gas) ---
        string[4] memory paletteNames = ["Vibrant", "Forest", "Synthwave Gradient", "Yin & Yang"];
        string[4] memory styleNames = ["Bold", "Detailed", "Hyper-Detailed", "Infinite Detail"];
        string[3] memory featureNames = ["Plain", "Gradient", "Shimmer"];

        string memory name = string(abi.encodePacked("Generative Tiling NFT #", id.toString()));
        string memory description = string(
            abi.encodePacked(
                "A unique, on-chain generative artwork. Style: ", styleNames[complexityId],
                ", Palette: ", paletteNames[paletteId],
                ", Feature: ", featureNames[featureId], "."
            )
        );
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id, paletteId, complexityId, featureId)));

        // GAS SAVING: Build the final JSON in fewer, larger steps.
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', name,
                            '", "description":"', description,
                            '", "attributes": [',
                                '{"trait_type": "Palette", "value": "', paletteNames[paletteId], '"},',
                                '{"trait_type": "Style", "value": "', styleNames[complexityId], '"},',
                                '{"trait_type": "Feature", "value": "', featureNames[featureId], '"}',
                            '], "image": "data:image/svg+xml;base64,', image, '"}'
                        )
                    )
                )
            )
        );
    }

    function generateSVGofTokenById(uint256 id, uint8 paletteId, uint8 complexityId, uint8 featureId) internal view returns (string memory) {
        string memory artContent = _renderRecursive(id, paletteId, complexityId, featureId, 0, 0, CANVAS_SIZE, 0);
        string memory defsAndStyles = _getDefsAndStyles(paletteId, featureId);
        
        return string(
            abi.encodePacked(
                '<svg width="', CANVAS_SIZE.toString(), '" height="', CANVAS_SIZE.toString(),
                '" viewBox="0 0 ', CANVAS_SIZE.toString(), ' ', CANVAS_SIZE.toString(),
                '" xmlns="http://www.w3.org/2000/svg">',
                defsAndStyles,
                '<rect width="100%" height="100%" fill="#1a1a1a"/>',
                artContent,
                '</svg>'
            )
        );
    }

    function _getPaletteColors(uint8 paletteId) internal pure returns (string[] memory) {
        if (paletteId == 0) return ["#ffbe0b", "#ff006e", "#8338ec", "#3a86ff"]; // Vibrant
        if (paletteId == 1) return ["#264653", "#2a9d8f", "#e9c46a", "#2a9d8f"]; // Forest
        if (paletteId == 2) return ["#ff006e", "#3a86ff", "#ff006e", "#3a86ff"]; // Synthwave
        return ["#FFFFFF", "#000000", "#FFFFFF", "#000000"]; // Yin & Yang
    }

    function _getDefsAndStyles(uint8 paletteId, uint8 featureId) internal pure returns (string memory) {
        if (featureId == 0) return ""; // Plain

        string[] memory colors = _getPaletteColors(paletteId);
        string memory defs;
        string memory styles;

        if (featureId == 1) { // Gradient
            defs = string(abi.encodePacked(
                '<defs><linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">',
                '<stop offset="0%" stop-color="', colors[0], '"/>',
                '<stop offset="100%" stop-color="', colors[1], '"/>',
                '</linearGradient></defs>'
            ));
        }
        if (featureId == 2) { // Shimmer
            styles = string(abi.encodePacked(
                '<style>.s { animation: shimmer 4s infinite ease-in-out; } @keyframes shimmer {',
                '0% { fill: ', colors[0], '; }',
                '33% { fill: ', colors[1], '; }',
                '66% { fill: ', colors[2], '; }',
                '100% { fill: ', colors[0], '; }',
                '}</style>'
            ));
        }
        return string(abi.encodePacked(defs, styles));
    }

    function _renderRecursive(
        uint256 id, uint8 paletteId, uint8 complexityId, uint8 featureId,
        uint16 x, uint16 y, uint16 size, uint8 depth
    ) internal view returns (string memory) {
        // Base case: Stop recursing
        bytes32 seed = keccak256(abi.encodePacked(id, x, y));
        if (depth > 0 && (depth > complexityId || (uint8(seed[0]) % 100) > CHANCE_OF_SPLIT)) {
            // GAS SAVING: Use one hash to derive multiple random values
            if ((uint8(seed[1]) % 100) > CHANCE_OF_DRAW) {
                string[] memory colors = _getPaletteColors(paletteId);
                string memory fill;
                if (featureId == 1) { // Gradient
                    fill = "url(#grad)";
                } else {
                    fill = colors[uint8(seed[2]) % colors.length];
                }

                string memory class = featureId == 2 ? ' class="s"' : "";
                string memory delay = string(abi.encodePacked(' style="animation-delay:', (uint8(seed[3]) % 150 * 10).toString(), 'ms"'));

                // For this example, we only draw circles. This can be expanded.
                return string(abi.encodePacked(
                    '<circle cx="', (x + size / 2).toString(),
                    '" cy="', (y + size / 2).toString(),
                    '" r="', (size / 2).toString(),
                    '" fill="', fill, '"', class, featureId == 2 ? delay : "", '/>'
                ));
            }
            return ""; // Empty tile
        }

        // Recursive step: Split into four quadrants
        uint16 newSize = size / 2;
        uint8 newDepth = depth + 1;
        return string(abi.encodePacked(
            _renderRecursive(id, paletteId, complexityId, featureId, x, y, newSize, newDepth),
            _renderRecursive(id, paletteId, complexityId, featureId, x + newSize, y, newSize, newDepth),
            _renderRecursive(id, paletteId, complexityId, featureId, x, y + newSize, newSize, newDepth),
            _renderRecursive(id, paletteId, complexityId, featureId, x + newSize, y + newSize, newSize, newDepth)
        ));
    }
}
*/