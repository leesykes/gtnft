import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployGTNFT: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("GTNFT", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });
};

export default deployGTNFT;

deployGTNFT.tags = ["GTNFT"];
