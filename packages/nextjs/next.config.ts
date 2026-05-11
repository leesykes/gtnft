import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  devIndicators: false,
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  webpack: (config, { dev }) => {
    config.resolve.fallback = { fs: false, net: false, tls: false };
    config.externals.push("pino-pretty", "lokijs", "encoding", "@react-native-async-storage/async-storage");
    if (!dev) {
      // Replace Next.js's SWC minimizer (which crashes on viem/appkit code with
      // '_webpack.WebpackError is not a constructor') with Terser, which handles
      // all modern JS without misinterpreting identifiers as TypeScript keywords.
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const TerserPlugin = require("terser-webpack-plugin");
      config.optimization.minimizer = [
        new TerserPlugin({
          parallel: true,
          terserOptions: {
            ecma: 2020,
            compress: { passes: 1 },
            mangle: true,
          },
        }),
      ];
    }
    return config;
  },
};

const isIpfs = process.env.NEXT_PUBLIC_IPFS_BUILD === "true";

if (isIpfs) {
  nextConfig.output = "export";
  nextConfig.trailingSlash = true;
  nextConfig.images = {
    unoptimized: true,
  };
}

module.exports = nextConfig;
