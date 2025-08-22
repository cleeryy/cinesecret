/** @type {import('next').NextConfig} */

import "./src/env/index.js"

const nextConfig = {
  // if you want to use standalone output, uncomment the following line
  output: "standalone",
  transpilePackages: ["@t3-oss/env-nextjs", "@t3-oss/env-core"],
  experimental: {
    serverComponentsExternalPackages: ['@prisma/client']
  }
};

export default nextConfig;
