const { merge } = require("webpack-merge");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");

const common = {
  entry: {
    index: "./src/index.ts",
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        exclude: /node_modules/,
        use: "ts-loader",
      },
    ],
  },
  output: {
    path: `${__dirname}/dist`,
    library: "textusm",
    libraryTarget: "umd",
  },
  resolve: {
    extensions: [".ts", ".js"],
  },
};

if (process.env.NODE_ENV === "production") {
  module.exports = merge(common, {
    plugins: [
      new CleanWebpackPlugin({
        root: `${__dirname}/dist`,
        exclude: [],
        verbose: true,
        dry: false,
      }),
    ],
    optimization: {
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
      ],
    },
  });
} else {
  module.exports = common;
}
