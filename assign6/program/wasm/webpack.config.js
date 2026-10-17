const HtmlWebpackPlugin = require('html-webpack-plugin')

const path = require("path");

module.exports = {
  entry: "./src/index.js",
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "bundle.js",
  },
  mode: "development",
  module: {
    rules: [
      { test: /\.wat$/, type: "asset/source" },
      { test: /\.wasm$/, type: "asset/resource" },
    ],
  },
  resolve: {
    fallback: { fs: false },
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: 'src/index.html'
    }),
  ],
};
