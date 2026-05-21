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
  webpack: (config) => {
    config.resolve.fallback = { fs: false, net: false, tls: false };
    // Use explicit CommonJS format so webpack generates require("pkg") instead of
    // treating the package name as a JS identifier. Scoped packages like
    // @react-native-async-storage/async-storage start with '@' which is not a valid
    // JS token outside decorator context, causing every minifier to fail with a
    // syntax error when the var-type external stub is parsed.
    config.externals.push(
      { "pino-pretty": "commonjs pino-pretty" },
      { lokijs: "commonjs lokijs" },
      { encoding: "commonjs encoding" },
      { "@react-native-async-storage/async-storage": "commonjs @react-native-async-storage/async-storage" },
    );
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
