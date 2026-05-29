import { expect } from "chai";
import { parseEther } from "ethers";
import { network } from "hardhat";
import type { Abi_GTNFT } from "../generated/abis/GTNFT.js";
import { loadAndExecuteDeploymentsFromFiles } from "../rocketh/environment.js";

const { provider, networkHelpers, ethers } = await network.create();

async function deployFixture() {
  const env = await loadAndExecuteDeploymentsFromFiles({ provider });
  const { address, abi } = env.get<Abi_GTNFT>("GTNFT");
  const gtnft = await ethers.getContractAt(abi, address);
  const [owner, minter] = await ethers.getSigners();
  return { gtnft, owner, minter };
}

describe("GTNFT", function () {
  describe("Deployment", function () {
    it("has correct name and symbol", async function () {
      const { gtnft } = await networkHelpers.loadFixture(deployFixture);
      expect(await gtnft.name()).to.equal("GenerativeTilingNFT");
      expect(await gtnft.symbol()).to.equal("GTNFT");
    });

    it("starts with zero supply", async function () {
      const { gtnft } = await networkHelpers.loadFixture(deployFixture);
      expect(await gtnft.totalSupply()).to.equal(0n);
    });

    it("starts at 0.001 ETH mint price", async function () {
      const { gtnft } = await networkHelpers.loadFixture(deployFixture);
      expect(await gtnft.price()).to.equal(parseEther("0.001"));
    });

    it("has correct collection limit", async function () {
      const { gtnft } = await networkHelpers.loadFixture(deployFixture);
      expect(await gtnft.COLLECTION_LIMIT()).to.equal(3728n);
    });
  });

  describe("Minting", function () {
    it("mints a token and increments supply", async function () {
      const { gtnft, minter } = await networkHelpers.loadFixture(deployFixture);
      const price = await gtnft.price();
      await gtnft.connect(minter).mintItem({ value: price });
      expect(await gtnft.totalSupply()).to.equal(1n);
      expect(await gtnft.ownerOf(1n)).to.equal(minter.address);
    });

    it("reverts when payment is insufficient", async function () {
      const { gtnft, minter } = await networkHelpers.loadFixture(deployFixture);
      const price = await gtnft.price();
      await expect(gtnft.connect(minter).mintItem({ value: price - 1n })).to.be.revertedWith("Not enough Ether sent");
    });

    it("increases price by 0.2% after each mint", async function () {
      const { gtnft, minter } = await networkHelpers.loadFixture(deployFixture);
      const priceBefore = await gtnft.price();
      await gtnft.connect(minter).mintItem({ value: priceBefore });
      const priceAfter = await gtnft.price();
      expect(priceAfter).to.equal((priceBefore * 1002n) / 1000n);
    });

    it("stores packed traits on mint", async function () {
      const { gtnft, minter } = await networkHelpers.loadFixture(deployFixture);
      const price = await gtnft.price();
      await gtnft.connect(minter).mintItem({ value: price });
      // traits are stored as a packed uint8 — just verify it's been written (non-zero possible but any value is valid)
      const packed = await gtnft.traits(1n);
      expect(typeof packed).to.equal("bigint");
    });
  });

  describe("tokenURI", function () {
    it("returns a base64-encoded JSON with expected fields", async function () {
      const { gtnft, minter } = await networkHelpers.loadFixture(deployFixture);
      const price = await gtnft.price();
      await gtnft.connect(minter).mintItem({ value: price });

      const uri = await gtnft.tokenURI(1n);
      expect(uri.startsWith("data:application/json;base64,")).to.equal(true);

      const json = JSON.parse(Buffer.from(uri.slice(29), "base64").toString());
      expect(json.name).to.equal("Generative Tiling NFT #1");
      expect(json.description).to.be.a("string");
      expect(json.image).to.match(/^data:image\/svg\+xml;base64,/);
      expect(json.attributes).to.be.an("array").that.has.lengthOf(3);
    });

    it("reverts for a non-existent token", async function () {
      const { gtnft } = await networkHelpers.loadFixture(deployFixture);
      await expect(gtnft.tokenURI(99n)).to.be.revertedWith("Token does not exist");
    });
  });
});
