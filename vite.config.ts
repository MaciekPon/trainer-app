import path from 'node:path'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  // GitHub Pages serwuje projekt pod /<nazwa-repo>/, więc w tym jednym
  // przypadku trzeba przestawić bazową ścieżkę assetów i routingu.
  base: process.env.GITHUB_PAGES ? '/trainer-app/' : '/',
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(import.meta.dirname, './src'),
    },
  },
})
