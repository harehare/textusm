const path = require("path");
const webpack = require("webpack");
const merge = require("webpack-merge");

const CopyWebpackPlugin = require("copy-webpack-plugin");
const HTMLWebpackPlugin = require("html-webpack-plugin");
const CleanWebpackPlugin = require("clean-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const MonacoWebpackPlugin = require("monaco-editor-webpack-plugin");
const WorkboxWebpackPlugin = require("workbox-webpack-plugin");
const ClosurePlugin = require("closure-webpack-plugin");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const PreloadWebpackPlugin = require("preload-webpack-plugin");
const HtmlWebpackInlineSourcePlugin = require("html-webpack-inline-source-plugin");
const Dotenv = require("dotenv-webpack");
const MODE =
    process.env.NODE_ENV === "production" ? "production" : "development";
const withDebug = !process.env.NODE_ENV;
const dist = path.join(__dirname, "dist");

const common = {
    mode: MODE,
    entry: "./src/index.js",
    output: {
        path: dist,
        publicPath: "/",
        filename: MODE === "production" ? "[name]-[hash].js" : "index.js"
    },
    plugins: [
        new Dotenv(),
        new HTMLWebpackPlugin({
            template: "src/index.html",
            inject: "body",
            inlineSource: ".css$"
        }),
        new PreloadWebpackPlugin({
            rel: "preload",
            include: ["runtime", "vendors"]
        }),
        new MonacoWebpackPlugin({
            languages: ["json", "markdown"],
            features: ["find"]
        })
    ],
    resolve: {
        modules: [path.join(__dirname, "src"), "node_modules"],
        extensions: [".js", ".elm", ".scss", ".css"],
        alias: {
            "monaco-editor": "monaco-editor/esm/vs/editor/editor.api.js"
        }
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: "babel-loader"
                }
            },
            {
                test: /\.scss$/,
                exclude: [/elm-stuff/, /node_modules/],
                loaders: ["style-loader", "css-loader?url=false", "sass-loader"]
            },
            {
                test: /\.css$/,
                exclude: [/elm-stuff/],
                loaders: ["style-loader", "css-loader?url=false"]
            },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "url-loader",
                options: {
                    limit: 10000,
                    mimetype: "application/font-woff"
                }
            },
            {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader"
            },
            {
                test: /\.(jpe?g|png|gif|svg)$/i,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader"
            }
        ]
    }
};

if (MODE === "development") {
    module.exports = merge(common, {
        plugins: [
            new webpack.NamedModulesPlugin(),
            new webpack.NoEmitOnErrorsPlugin()
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [
                        {
                            loader: "elm-hot-webpack-loader"
                        },
                        {
                            loader: "elm-webpack-loader",
                            options: {
                                debug: withDebug,
                                forceWatch: true
                            }
                        }
                    ]
                }
            ]
        },
        devServer: {
            inline: true,
            stats: "errors-only",
            contentBase: path.join(__dirname, "src/assets"),
            historyApiFallback: true,
            before(app) {
                app.get("/test", function(req, res) {
                    res.json({
                        result: "OK"
                    });
                });
            }
        }
    });
}
if (MODE === "production") {
    module.exports = merge(common, {
        plugins: [
            new WorkboxWebpackPlugin.GenerateSW({
                globDirectory: dist,
                globPatterns: [
                    "*.{html,js,css}",
                    "images/**/*.{jpg,jpeg,png,gif,webp,svg}"
                ],
                swDest: dist + "/sw.js",
                clientsClaim: true,
                skipWaiting: true
            }),
            new CleanWebpackPlugin({
                root: __dirname,
                exclude: [],
                verbose: false,
                dry: false
            }),
            new CopyWebpackPlugin([
                {
                    from: "src/assets"
                }
            ]),
            new MiniCssExtractPlugin({
                filename: "[name]-[hash].css"
            }),
            new HtmlWebpackInlineSourcePlugin()
        ],
        module: {
            rules: [
                {
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: {
                        loader: "elm-webpack-loader",
                        options: {
                            optimize: true
                        }
                    }
                },
                {
                    test: /\.css$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loaders: [
                        MiniCssExtractPlugin.loader,
                        "css-loader?url=false"
                    ]
                },
                {
                    test: /\.scss$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    loaders: [
                        MiniCssExtractPlugin.loader,
                        "css-loader?url=false",
                        "sass-loader"
                    ]
                }
            ]
        },
        optimization: {
            splitChunks: {
                cacheGroups: {
                    vendors: {
                        test: /[\\/]node_modules[\\/]/i,
                        chunks: "all"
                    }
                }
            },
            runtimeChunk: {
                name: "runtime"
            },
            minimizer: [
                new ClosurePlugin(
                    {
                        mode: "STANDARD"
                    },
                    {}
                ),
                new UglifyJsPlugin({
                    uglifyOptions: {
                        compress: true,
                        sourceMap: false
                    }
                }),
                new OptimizeCSSAssetsPlugin()
            ]
        }
    });
}
