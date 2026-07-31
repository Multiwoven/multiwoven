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
        '/enterprise': { target: upstream, changeOrigin: true },
        '/saml': { target: upstream, changeOrigin: true },
      },
    },
  };
>>>>>>> 511039ec2 (chore(CE): revert to just the admin UI changes (#2127))
});
