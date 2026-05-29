const buildHardhatEslintCommand = filenames => {
  const path = require("path");
  return `yarn hardhat:lint-staged --fix ${filenames
    .map(f => path.relative(path.join("packages", "hardhat"), f))
    .join(" ")}`;
};

module.exports = {
  // Run full nextjs lint — eslint-plugin-react (via eslint-config-next) does not
  // support per-file invocation with ESLint 10 flat config, so we lint the whole package.
  "packages/nextjs/**/*.{ts,tsx}": [() => "yarn next:lint", () => "yarn next:check-types"],
  "packages/hardhat/**/*.{ts,tsx}": [buildHardhatEslintCommand],
};
