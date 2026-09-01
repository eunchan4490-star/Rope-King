import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{js,ts,jsx,tsx,mdx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          bg: "#0e1320",
          panel: "#161d2e",
          gold: "#ffd23f",
          accent: "#73f7b4",
          danger: "#ff7892",
        },
      },
    },
  },
  plugins: [],
};

export default config;
