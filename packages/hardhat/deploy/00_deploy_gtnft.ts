import { deployScript, artifacts } from "../rocketh/deploy.js";

export default deployScript(
  async env => {
    const { deployer } = env.namedAccounts;

    await env.deploy("GTNFT", {
      account: deployer,
      artifact: artifacts.GTNFT,
      args: [],
    });
  },
  {
    tags: ["GTNFT"],
  },
);
