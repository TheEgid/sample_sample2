import type { NextConfig } from "next";

const nextConfig: NextConfig = {
    experimental: { webpackBuildWorker: true },
    reactStrictMode: true,
    distDir: "build",
    onDemandEntries: { maxInactiveAge: 25 * 10000 },
    devIndicators: false,
    // output: "standalone",
    images: {
        domains: ["media.istockphoto.com"],
    },
};

export default nextConfig;
