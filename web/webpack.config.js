const path = require('path');
const fs = require('fs');
const webpack = require('webpack');
const { merge } = require('webpack-merge');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const HTMLWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const { default: MiniCssExtractPlugin } = require('mini-css-extract-plugin');
const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');
const WorkboxWebpackPlugin = require('workbox-webpack-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const PreloadWebpackPlugin = require('preload-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const HTMLInlineCSSWebpackPlugin =
    require('html-inline-css-webpack-plugin').default;
const SentryWebpackPlugin = require('@sentry/webpack-plugin');

const mode =
    process.env.NODE_ENV === 'production' ? 'production' : 'development';
const dist = path.join(__dirname, 'dist');
const day = 60 * 60 * 24;

const common = {
    mode,
    devtool: 'source-map',
    entry: './src/ts/index.ts',
    output: {
        path: dist,
        publicPath: '/',
        filename: mode === 'production' ? '[name]-[hash].js' : 'index.js',
    },
    plugins: [
        new HTMLWebpackPlugin({
            template: 'src/index.html',
            inject: 'body',
            inlineSource: '.css$',
        }),
        new webpack.EnvironmentPlugin([
            'API_ROOT',
            'WEB_ROOT',
            'FIREBASE_API_KEY',
            'FIREBASE_AUTH_DOMAIN',
            'FIREBASE_PROJECT_ID',
            'FIREBASE_STORAGE_BUCKET',
            'FIREBASE_APP_ID',
            'SENTRY_ENABLE',
            'SENTRY_DSN',
            'SENTRY_RELEASE',
            'NODE_ENV',
            'FIREBASE_AUTH_EMULATOR_URL',
        ]),
        new PreloadWebpackPlugin({
            rel: 'preload',
            include: ['runtime', 'vendors'],
        }),
        new MonacoWebpackPlugin({
            languages: [],
            features: ['clipboard'],
        }),
    ],
    resolve: {
        modules: [path.join(__dirname, 'src'), 'node_modules'],
        extensions: ['.js', '.ts', '.elm', '.scss', '.css'],
        alias: {
            'monaco-editor': 'monaco-editor/esm/vs/editor/editor.api.js',
        },
        fallback: {
            path: false,
            stream: false,
            buffer: false,
        },
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                },
            },
            {
                test: /\.ts$/,
                exclude: /node_modules/,
                use: 'ts-loader',
            },
            {
                test: /\.scss$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [
                    'style-loader',
                    'css-loader',
                    {
                        loader: 'sass-loader',
                        options: {
                            implementation: require('sass'),
                        },
                    },
                ],
            },
            {
                test: /\.css$/,
                exclude: [/elm-stuff/],
                use: ['style-loader', 'css-loader'],
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                type: 'asset',
                mimetype: 'application/font-woff',
                parser: {
                    dataUrlCondition: {
                        maxSize: 10 * 1024,
                    },
                },
            },
            {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                type: 'asset',
                parser: {
                    dataUrlCondition: {
                        maxSize: 10 * 1024,
                    },
                },
            },
            {
                test: /\.(jpe?g|png|gif|svg)$/i,
                exclude: [/elm-stuff/, /node_modules/],
                type: 'asset',
                parser: {
                    dataUrlCondition: {
                        maxSize: 10 * 1024,
                    },
                },
            },
            {
                test: /\.svg$/,
                use: 'svg-inline-loader',
            },
        ],
    },
};

if (mode === 'development') {
    module.exports = merge(common, {
        plugins: [],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [
                        {
                            loader: 'elm-hot-webpack-loader',
                        },
                        {
                            loader: 'elm-webpack-loader',
                            options: {
                                debug: true,
                            },
                        },
                    ],
                },
            ],
        },
        devServer: {
            hot: true,
            historyApiFallback: true,
            static: path.join(__dirname, 'src/assets'),
            https:
                process.env.TLS_CERT_FILE && process.env.TLS_KEY_FILE
                    ? {
                          key: fs.readFileSync(process.env.TLS_KEY_FILE),
                          cert: fs.readFileSync(process.env.TLS_CERT_FILE),
                      }
                    : false,
        },
    });
}
if (mode === 'production') {
    module.exports = merge(common, {
        plugins: [
            ...[
                new WorkboxWebpackPlugin.GenerateSW({
                    swDest: dist + '/sw.js',
                    clientsClaim: true,
                    skipWaiting: true,
                    maximumFileSizeToCacheInBytes: 1024 * 1024 * 5,
                    navigateFallback: '/index.html',
                    navigateFallbackAllowlist: [
                        /^\/($|new|edit|view|public|list|settings|help|share|notfound|embed)/,
                    ],
                    runtimeCaching: [
                        {
                            urlPattern:
                                /^https:\/\/fonts\.gstatic\.com.*\.woff2.*$/,
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
                }),
                new HTMLInlineCSSWebpackPlugin(),
                new CleanWebpackPlugin({
                    root: __dirname,
                    exclude: [],
                    verbose: false,
                    dry: false,
                }),
                new CopyWebpackPlugin({
                    patterns: [
                        {
                            from: 'src/assets',
                        },
                    ],
                }),
                new MiniCssExtractPlugin({
                    filename: '[name]-[hash].css',
                    chunkFilename: '[id]-[contenthash].css',
                }),
            ],
            ...(process.env.SENTRY_ENABLE === '1'
                ? [
                      new SentryWebpackPlugin({
                          authToken: process.env.SENTRY_AUTH_TOKEN,
                          org: process.env.SENTRY_ORG,
                          project: process.env.SENTRY_PROJECT,
                          release: process.env.SENTRY_RELEASE,
                          include: './dist',
                          ignore: ['node_modules', 'webpack.config.js'],
                      }),
                  ]
                : []),
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: {
                        loader: 'elm-webpack-loader',
                        options: {
                            optimize: true,
                        },
                    },
                },
                {
                    test: /\.css$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [MiniCssExtractPlugin.loader, 'css-loader'],
                },
                {
                    test: /\.scss$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [
                        MiniCssExtractPlugin.loader,
                        'css-loader',
                        {
                            loader: 'sass-loader',
                            options: {
                                implementation: require('sass'),
                            },
                        },
                    ],
                },
            ],
        },
        optimization: {
            splitChunks: {
                chunks: 'async',
                cacheGroups: {
                    vendors: {
                        test: /[\\/]node_modules[\\/]/i,
                        chunks: 'all',
                    },
                    editor: {
                        test: /[\\/]node_modules\/(monaco-editor\/esm\/vs\/(nls\.js|editor|platform|base|basic-languages|language\/(css|html|json|typescript)\/monaco\.contribution\.js)|style-loader\/lib|css-loader\/lib\/css-base\.js)/,
                        name: 'monaco-editor',
                        chunks: 'async',
                    },
                    languages: {
                        test: /[\\/]node_modules\/monaco-editor\/esm\/vs\/language\/(css|html|json|typescript)\/(_deps|lib|fillers|languageFeatures\.js|workerManager\.js|tokenization\.js|(tsMode|jsonMode|htmlMode|cssMode)\.js|(tsWorker|jsonWorker|htmlWorker|cssWorker)\.js)/,
                        name: 'monaco-languages',
                        chunks: 'async',
                    },
                },
            },
            runtimeChunk: {
                name: 'runtime',
            },
            minimize: true,
            minimizer: [
                new TerserPlugin({
                    test: /\.(js|ts)$/i,
                    parallel: true,
                    terserOptions: {
                        compress: {
                            drop_console: true,
                        },
                    },
                }),
                new TerserPlugin({
                    test: /elm\.js$/,
                    parallel: true,
                    terserOptions: {
                        compress: {
                            pure_funcs: [
                                'F2',
                                'F3',
                                'F4',
                                'F5',
                                'F6',
                                'F7',
                                'F8',
                                'F9',
                                'A2',
                                'A3',
                                'A4',
                                'A5',
                                'A6',
                                'A7',
                                'A8',
                                'A9',
                            ],
                            pure_getters: true,
                            keep_fargs: false,
                            unsafe_comps: true,
                            drop_console: true,
                            unsafe: true,
                            passes: 3,
                        },
                    },
                }),
                new CssMinimizerPlugin({
                    minimizerOptions: {
                        preset: [
                            'advanced',
                            {
                                discardComments: { removeAll: true },
                            },
                        ],
                    },
                }),
            ],
        },
    });
}
