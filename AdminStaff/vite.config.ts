import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 5173,
    open: true,
    proxy: {
      '/api': { target: 'http://localhost:8081', changeOrigin: true },
      '/ws': { target: 'http://localhost:8081', ws: true, changeOrigin: true },
    },
  },
  build: {
    chunkSizeWarningLimit: 500,
  },
  test: {
    environment: 'happy-dom',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/lib/utils.ts'],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 60,
      },
    },
  },
})
