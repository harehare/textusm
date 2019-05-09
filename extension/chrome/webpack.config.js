const merge = require('webpack-merge');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');


const common = {
  entry: {
    background: "./src/background.ts",
    content: "./src/content.ts",
    popup: "./src/popup.ts",
  },
  module: {
    rules: [{
      test: /\.ts$/,
      exclude: /node_modules/,
      use: "ts-loader"
    }]
  },
  output: {
    path: `${__dirname}/dist`,
  },
  resolve: {
    extensions: [".ts", ".js"]
  },
  devtool: 'cheap-module-source-map'
};

if (process.env.NODE_ENV === 'production') {
  module.exports = merge(common, {
    devtool: 'none',
    plugins: [
      new CleanWebpackPlugin({
        root: `${__dirname}/dist`,
        exclude: [],
        verbose: true,
        dry: false
      })
    ],
    optimization: {
      minimizer: [
        new TerserPlugin({
          cache: false,
          parallel: true,
          sourceMap: false,
        }),
      ],
    }
  });
} else {
  module.exports = common;
}