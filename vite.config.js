import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// https://vitejs.dev/config/
export default defineConfig({
  // GitHub Pages serves this project from /rescript-cube/, so every asset URL
  // needs that prefix. Applied unconditionally: making it build-only would leave
  // `vite preview` serving root-relative URLs against a prefixed bundle.
  base: "/rescript-cube/",
  plugins: [
    tailwindcss(),
    react({
      include: ["**/*.res.mjs"],
    }),
  ],
  server: {
    watch: {
      // We ignore ReScript build artifacts to avoid unnecessarily triggering HMR on incremental compilation
      ignored: ["**/lib/bs/**", "**/lib/ocaml/**", "**/lib/rescript.lock"],
    },
  },
});
