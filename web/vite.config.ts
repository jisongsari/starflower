import { resolve } from "path";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, "index.html"),
        privacy: resolve(__dirname, "privacy-policy.html"),
        support: resolve(__dirname, "support.html"),
        web: resolve(__dirname, "web.html"),
      },
    },
  },
});