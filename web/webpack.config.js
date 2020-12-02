const path = require("path");
const webpack = require("webpack");
const { merge } = require("webpack-merge");

const CopyWebpackPlugin = require("copy-webpack-plugin");
const HTMLWebpackPlugin = require("html-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const MonacoWebpackPlugin = require("monaco-editor-webpack-plugin");
const WorkboxWebpackPlugin = require("workbox-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const PreloadWebpackPlugin = require("preload-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const HTMLInlineCSSWebpackPlugin = require("html-inline-css-webpack-plugin")
    .default;
const ImageminPlugin = require("imagemin-webpack-plugin").default;
const mode =
    process.env.NODE_ENV === "production" ? "production" : "development";
const withDebug = !process.env.NODE_ENV;
const dist = path.join(__dirname, "dist");

const common = {
    mode,
    entry: "./src/index.ts",
    output: {
        path: dist,
        publicPath: "/",
        filename: mode === "production" ? "[name]-[hash].js" : "index.js",
    },
    plugins: [
        new HTMLWebpackPlugin({
            template: "src/index.html",
            inject: "body",
            inlineSource: ".css$",
        }),
        new webpack.EnvironmentPlugin([
            "API_ROOT",
            "FIREBASE_API_KEY",
            "FIREBASE_AUTH_DOMAIN",
            "FIREBASE_PROJECT_ID",
            "FIREBASE_STORAGE_BUCKET",
            "FIREBASE_APP_ID",
            "SENTRY_ENABLE",
            "SENTRY_DSN",
        ]),
        new PreloadWebpackPlugin({
            rel: "preload",
            include: ["runtime", "vendors"],
        }),
        new MonacoWebpackPlugin({
            languages: [],
            features: ["folding"],
        }),
    ],
    resolve: {
        modules: [path.join(__dirname, "src"), "node_modules"],
        extensions: [".js", ".ts", ".elm", ".scss", ".css"],
        alias: {
            "monaco-editor": "monaco-editor/esm/vs/editor/editor.api.js",
        },
        fallback: { stream: false },
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: "babel-loader",
                },
            },
            {
                test: /\.ts$/,
                exclude: /node_modules/,
                use: "ts-loader",
            },
            {
                test: /\.scss$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [
                    "style-loader",
                    "css-loader?url=false",
                    "sass-loader",
                    "postcss-loader",
                ],
            },
            {
                test: /\.css$/,
                exclude: [/elm-stuff/],
                use: ["style-loader", "css-loader?url=false"],
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                type: "asset",
                mimetype: "application/font-woff",
                parser: {
                    dataUrlCondition: {
                        maxSize: 10 * 1024,
                    },
                },
            },
            {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                type: "asset",
                parser: {
                    dataUrlCondition: {
                        maxSize: 10 * 1024,
                    },
                },
            },
            {
                test: /\.(jpe?g|png|gif|svg)$/i,
                exclude: [/elm-stuff/, /node_modules/],
                type: "asset",
                parser: {
                    dataUrlCondition: {
                        maxSize: 10 * 1024,
                    },
                },
            },
            {
                test: /\.svg$/,
                use: "svg-inline-loader",
            },
        ],
    },
};

if (mode === "development") {
    module.exports = merge(common, {
        plugins: [],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [
                        {
                            loader: "elm-hot-webpack-loader",
                        },
                        {
                            loader: "elm-webpack-loader",
                            options: {
                                debug: withDebug,
                                forceWatch: true,
                            },
                        },
                    ],
                },
            ],
        },
        devServer: {
            inline: true,
            stats: "errors-only",
            contentBase: path.join(__dirname, "src/assets"),
            historyApiFallback: true,
            before(app) {
                app.get("/test", function (_, res) {
                    res.json({
                        result: "OK",
                    });
                });
            },
        },
    });
}
if (mode === "production") {
    module.exports = merge(common, {
        plugins: [
            new WorkboxWebpackPlugin.GenerateSW({
                swDest: dist + "/sw.js",
                clientsClaim: true,
                skipWaiting: true,
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
                        from: "src/assets",
                    },
                ],
            }),
            new ImageminPlugin({ test: /\.(jpe?g|png|gif|svg)$/i }),
            new MiniCssExtractPlugin({
                filename: "[name]-[hash].css",
                chunkFilename: "[id]-[contenthash].css",
            }),
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: {
                        loader: "elm-webpack-loader",
                        options: {
                            optimize: true,
                        },
                    },
                },
                {
                    test: /\.css$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [MiniCssExtractPlugin.loader, "css-loader?url=false"],
                },
                {
                    test: /\.scss$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [
                        MiniCssExtractPlugin.loader,
                        "css-loader?url=false",
                        "sass-loader",
                        "postcss-loader",
                    ],
                },
            ],
        },
        optimization: {
            splitChunks: {
                chunks: "async",
                cacheGroups: {
                    vendors: {
                        test: /[\\/]node_modules[\\/]/i,
                        chunks: "all",
                    },
                    editor: {
                        test: /[\\/]node_modules\/(monaco-editor\/esm\/vs\/(nls\.js|editor|platform|base|basic-languages|language\/(css|html|json|typescript)\/monaco\.contribution\.js)|style-loader\/lib|css-loader\/lib\/css-base\.js)/,
                        name: "monaco-editor",
                        chunks: "async",
                    },
                    languages: {
                        test: /[\\/]node_modules\/monaco-editor\/esm\/vs\/language\/(css|html|json|typescript)\/(_deps|lib|fillers|languageFeatures\.js|workerManager\.js|tokenization\.js|(tsMode|jsonMode|htmlMode|cssMode)\.js|(tsWorker|jsonWorker|htmlWorker|cssWorker)\.js)/,
                        name: "monaco-languages",
                        chunks: "async",
                    },
                },
            },
            runtimeChunk: {
                name: "runtime",
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
                                "F2",
                                "F3",
                                "F4",
                                "F5",
                                "F6",
                                "F7",
                                "F8",
                                "F9",
                                "A2",
                                "A3",
                                "A4",
                                "A5",
                                "A6",
                                "A7",
                                "A8",
                                "A9",
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
                new OptimizeCSSAssetsPlugin({
                    cssProcessor: require("cssnano"),
                    cssProcessorPluginOptions: {
                        preset: [
                            "advanced",
                            {
                                discardComments: { removeAll: true },
                                cssDeclarationSorter: { order: "smacss" },
                            },
                        ],
                    },
                    canPrint: true,
                }),
            ],
        },
    });
}
