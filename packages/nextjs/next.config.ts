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
      // Replace Next.js's SWC minimizer (which crashes with '_webpack.WebpackError
      // is not a constructor') with TerserPlugin using SWC's minifier. SWC's minifier
      // is built on the SWC TypeScript parser, so it handles 'abstract class' and
      // TC39 '@decorator' syntax from packages that ship partially-TS compiled output.
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const TerserPlugin = require("terser-webpack-plugin");
      config.optimization.minimizer = [
        new TerserPlugin({
          minify: TerserPlugin.swcMinify,
          terserOptions: {
            compress: true,
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
