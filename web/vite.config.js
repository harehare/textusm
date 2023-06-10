import { sentryVitePlugin } from '@sentry/vite-plugin';
import path from 'node:path';
import { defineConfig, splitVendorChunkPlugin } from 'vite';
import elmPlugin from 'vite-plugin-elm';
import { createHtmlPlugin } from 'vite-plugin-html';
import { VitePWA as vitePWA } from 'vite-plugin-pwa';

const outDir = path.join(__dirname, 'dist');
const day = 60 * 60 * 24;

export default defineConfig(({ mode }) => ({
  root: './src',
  build: {
    outDir,
    sourcemap: true,
    minify: 'terser',
    terserOptions: {
      compress: {
        // eslint-disable-next-line camelcase
        pure_funcs: ['F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9'],
        // eslint-disable-next-line camelcase
        pure_getters: true,
        // eslint-disable-next-line camelcase
        keep_fargs: false,
        // eslint-disable-next-line camelcase
        unsafe_comps: true,
        // eslint-disable-next-line camelcase
        drop_console: true,
        unsafe: true,
        passes: 3,
      },
    },
  },
  envDir: '../',
  rollupOptions: {
    output: {
      manualChunks: {
        editor: [
          /[\\/]node_modules\/(monaco-editor\/esm\/vs\/(nls\.js|editor|platform|base|basic-languages|language\/(css|html|json|typescript)\/monaco\.contribution\.js)|style-loader\/lib|css-loader\/lib\/css-base\.js)/,
        ],
        languages: [
          /[\\/]node_modules\/monaco-editor\/esm\/vs\/language\/(css|html|json|typescript)\/(_deps|lib|fillers|languageFeatures\.js|workerManager\.js|tokenization\.js|(tsMode|jsonMode|htmlMode|cssMode)\.js|(tsWorker|jsonWorker|htmlWorker|cssWorker)\.js)/,
        ],
      },
    },
  },
  plugins: [
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
              id: 'tag',
            },
          },
        ],
      },
    }),

    splitVendorChunkPlugin(),
    ...(mode === 'production'
      ? [
          vitePWA({
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
            authToken: process.env.SENTRY_AUTH_TOKEN ?? '',
            org: process.env.SENTRY_ORG ?? '',
            project: process.env.SENTRY_PROJECT ?? '',
            release: { name: process.env.SENTRY_RELEASE ?? '' },
            sourcemaps: {
              assets: './dist',
              ignore: ['node_modules', 'vite.config.js'],
            },
          }),
        ]
      : []),
  ],
  server: {
    https: process.env.USE_HTTPS
      ? {
          key: '../certs/localhost.key',
          cert: '../certs/localhost.cert',
        }
      : {},
  },
}));
