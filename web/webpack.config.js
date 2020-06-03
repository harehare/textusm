const path = require("path");
const webpack = require("webpack");
const merge = require("webpack-merge");

const CopyWebpackPlugin = require("copy-webpack-plugin");
const HTMLWebpackPlugin = require("html-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const MonacoWebpackPlugin = require("monaco-editor-webpack-plugin");
const WorkboxWebpackPlugin = require("workbox-webpack-plugin");
const ClosurePlugin = require("closure-webpack-plugin");
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
        ]),
        new PreloadWebpackPlugin({
            rel: "preload",
            include: ["runtime", "vendors"],
        }),
        new MonacoWebpackPlugin({
            languages: ["markdown"],
            features: ["folding"],
        }),
    ],
    resolve: {
        modules: [path.join(__dirname, "src"), "node_modules"],
        extensions: [".js", ".ts", ".elm", ".scss", ".css"],
        alias: {
            "monaco-editor": "monaco-editor/esm/vs/editor/editor.api.js",
        },
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
                loaders: [
                    "style-loader",
                    "css-loader?url=false",
                    "sass-loader",
                ],
            },
            {
                test: /\.css$/,
                exclude: [/elm-stuff/],
                loaders: ["style-loader", "css-loader?url=false"],
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "url-loader",
                options: {
                    limit: 10000,
                    mimetype: "application/font-woff",
                },
            },
            {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader",
            },
            {
                test: /\.(jpe?g|png|gif|svg)$/i,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader",
            },
            {
                test: /\.svg$/,
                loader: "svg-inline-loader",
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
                    use: [
                        {
                            loader: MiniCssExtractPlugin.loader,
                            options: {
                                esModule: true,
                            },
                        },
                        "css-loader?url=false",
                    ],
                },
                {
                    test: /\.scss$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loaders: [
                        MiniCssExtractPlugin.loader,
                        "css-loader?url=false",
                        "sass-loader",
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
                },
            },
            runtimeChunk: {
                name: "runtime",
            },
            minimize: true,
            minimizer: [
                new ClosurePlugin(
                    {
                        mode: "STANDARD",
                    },
                    {}
                ),
                new TerserPlugin({
                    parallel: true,
                    sourceMap: false,
                    terserOptions: {
                        compress: {
                            drop_console: true,
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
