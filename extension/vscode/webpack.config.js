const merge = require('webpack-merge');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const nodeExternals = require('webpack-node-externals');

const common = {
  entry: "./src/extension.ts",
  module: {
    rules: [{
      test: /\.ts$/,
      exclude: /node_modules/,
      use: "ts-loader"
    }]
  },
  output: {
    path: `${__dirname}/dist`,
    filename: 'extension.js',
    libraryTarget: 'commonjs2',
    devtoolModuleFilenameTemplate: '../[resource-path]'
  },
  resolve: {
    extensions: [".ts", ".js"]
  },
  target: 'node',
  devtool: 'cheap-module-source-map',
  externals: [{
    vscode: "commonjs vscode"
  }, nodeExternals()],
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