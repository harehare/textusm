import { sentryVitePlugin } from '@sentry/vite-plugin';
import path from 'node:path';
import { defineConfig, splitVendorChunkPlugin } from 'vite';
import elmPlugin from 'vite-plugin-elm';
import { createHtmlPlugin } from 'vite-plugin-html';
import { VitePWA } from 'vite-plugin-pwa';
import EnvironmentPlugin from 'vite-plugin-environment'


const outDir = path.join(__dirname, 'dist');
const day = 60 * 60 * 24;

export default defineConfig(({ mode }) => ({
  root: './src',
  build: {
    outDir,
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
  },
  plugins: [
    EnvironmentPlugin([
      'FIREBASE_API_KEY',
      'FIREBASE_AUTH_DOMAIN',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_APP_ID',
      'SENTRY_ENABLE',
      'SENTRY_DSN',
      'SENTRY_RELEASE',
      'MONITOR_ENABLE',
      'FIREBASE_AUTH_EMULATOR_HOST',
    ]),
    elmPlugin({
      optimize: false,
      // @ts-ignore
      nodeElmCompilerOptions: {
        pathToElm: mode === 'production' ? 'node_modules/elm-optimize-level-2/bin/elm-optimize-level-2' : undefined,
      },
    }),
    createHtmlPlugin({
      minify: true,
      entry: 'ts/index.ts',
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
          VitePWA({
            injectRegister: null,
            workbox: {
              swDest: `${outDir}/sw.js`,
              clientsClaim: true,
              skipWaiting: true,
              maximumFileSizeToCacheInBytes: 1024 * 1024 * 5,
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
                env: 'production'
              },
            },
            sourcemaps: {
              ignore: ['node_modules', 'vite.config.js'],
            },
          }),
        ]
      : []),
  ],
  server: {
    host: true,
    port: 3000,
    https: process.env.USE_HTTPS === '1'
      ? {
          key: '../certs/localhost.key',
          cert: '../certs/localhost.cert',
        }
      : false,
  },
}));
