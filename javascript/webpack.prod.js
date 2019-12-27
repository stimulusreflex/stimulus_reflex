const path = require("path");

module.exports = {
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: "babel-loader",

        options: {
          presets: ["@babel/preset-env"]
        }
      }
    ]
  },

  entry: "./stimulus_reflex.js",

  output: {
    filename: "stimulus_reflex.min.js",
    path: path.resolve(__dirname, "dist")
  },

  mode: "production"
};
