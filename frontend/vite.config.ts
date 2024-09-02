import path from 'node:path';
import elmPlugin from 'vite-plugin-elm';
import { sentryVitePlugin } from '@sentry/vite-plugin';
import { defineConfig, splitVendorChunkPlugin } from 'vite';
import { VitePWA } from 'vite-plugin-pwa';
import { createHtmlPlugin } from 'vite-plugin-html';

const outDirectory = path.join(import.meta.dirname, 'dist');
const day = 60 * 60 * 24;
const env = [
  'FIREBASE_API_KEY',
  'FIREBASE_AUTH_DOMAIN',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_APP_ID',
  'SENTRY_ENABLE',
  'SENTRY_DSN',
  'SENTRY_RELEASE',
  'MONITOR_ENABLE',
  'FIREBASE_AUTH_EMULATOR_HOST',
];

export default defineConfig(({ mode }) => ({
  root: './src',
  build: {
    outDir: outDirectory,
    sourcemap: mode === 'production',
    minify: 'terser',
    terserOptions: {
      compress: {
        pure_funcs: ['F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9'],
        pure_getters: true,
        keep_fargs: false,
        unsafe_comps: true,
        drop_console: true,
        unsafe: true,
        passes: 3,
      },
    },
    chunkSizeWarningLimit: 1024,
    // rollupOptions: {
    //   output: {
    //     manualChunks(id) {
    //       if (id.includes('jspdf') || id.includes('html2canvas')) {
    //         return 'vendor-pdf';
    //       }

    //       if (id.includes('svgo')) {
    //         return 'vendor-svgo';
    //       }

    //       if (id.includes('monaco-editor')) {
    //         return 'vendor-monaco';
    //       }

    //       if (id.includes('node_modules')) {
    //         return 'vendor';
    //       }
    //     },
    //   },
    // },
  },
  define: Object.fromEntries(env.map((key) => [`process.env.${key}`, JSON.stringify(process.env[key])])),
  plugins: [
    // eslint-disable-next-line @typescript-eslint/no-unsafe-call
    elmPlugin({
      optimize: false,
      nodeElmCompilerOptions: {
        pathToElm: mode === 'production' ? 'node_modules/elm-optimize-level-2/bin/elm-optimize-level-2' : undefined,
      },
    }),
    createHtmlPlugin({
      minify: true,
      entry: '/ts/index.ts',
      template: 'index.html',
      inject: {
        data: {
          title: 'index',
          injectScript: `<script src="./inject.js"></script>`,
        },
        tags: [
          {
            injectTo: 'body-prepend',
            tag: 'div',
            attrs: {
              id: 'main',
            },
          },
        ],
      },
    }),
    splitVendorChunkPlugin(),
    ...(mode === 'production'
      ? [
          // eslint-disable-next-line new-cap
          VitePWA({
            injectRegister: null,
            workbox: {
              swDest: `${outDirectory}/sw.js`,
              clientsClaim: true,
              skipWaiting: true,
              maximumFileSizeToCacheInBytes: 1024 * 1024 * 10,
              navigateFallback: '/index.html',
              navigateFallbackAllowlist: [/^\/($|new|edit|view|public|list|settings|help|share|notfound|embed)/],
              runtimeCaching: [
                {
                  urlPattern: /^https:\/\/fonts\.gstatic\.com.*\.woff2.*$/,
                  handler: 'CacheFirst',
                  options: {
                    cacheName: 'google-font-file-cache',
                    cacheableResponse: {
                      statuses: [0, 200, 307],
                    },
                    expiration: {
                      maxAgeSeconds: 31 * day,
                    },
                  },
                },
              ],
            },
          }),
        ]
      : []),
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    ...(mode === 'production' && process.env.SENTRY_ENABLE === '1'
      ? [
          sentryVitePlugin({
            telemetry: false,
            authToken: process.env.SENTRY_AUTH_TOKEN ?? '',
            org: process.env.SENTRY_ORG ?? '',
            project: process.env.SENTRY_PROJECT ?? '',
            release: {
              name: process.env.SENTRY_RELEASE ?? '',
              deploy: {
                env: 'production',
              },
            },
            sourcemaps: {
              ignore: ['node_modules'],
            },
          }),
        ]
      : []),
  ],
  preview: {
    port: 3001,
  },
  server: {
    host: true,
    port: 3000,
    https:
      process.env.USE_HTTPS === '1'
        ? {
            key: '../certs/localhost.key',
            cert: '../certs/localhost.cert',
          }
        : undefined,
  },
}));
