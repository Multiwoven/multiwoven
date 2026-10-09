import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
<<<<<<< HEAD
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: [{ find: '@', replacement: '/src' }],
  },
  server: {
    port: 8000,
  },
=======
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const upstream = env.VITE_API_HOST || 'http://localhost:3000';
  return {
    plugins: [react()],
    resolve: {
      alias: [{ find: '@', replacement: '/src' }],
    },
    server: {
      port: 8000,
      proxy: {
        '/api': { target: upstream, changeOrigin: true },
        // Forward the AppGen ActionCable connection.
        '/enterprise': {
          target: upstream,
          changeOrigin: true,
          ws: true,
          rewriteWsOrigin: true,
        },
        '/saml': { target: upstream, changeOrigin: true },
      },
    },
  };
>>>>>>> e03f7c173 (chore(CE): clickjacking issue revert (#2134))
});
