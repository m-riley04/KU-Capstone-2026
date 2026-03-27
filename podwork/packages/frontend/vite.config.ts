import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate', // automatically updates app when new code is pushed
      devOptions: {
        enabled: true 
      },
      manifest: {
        name: 'Podwork',
        short_name: 'Podwork',
        description: 'Preference tracking and capstone project management',
        theme_color: '#1e293b',
        background_color: '#1e293b',
        display: 'standalone', // hides the url bar
        icons: [
          {
            src: '/icon-192x192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: '/icon-512x512.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'any maskable'
          }
        ]
      }
    })
  ]
});