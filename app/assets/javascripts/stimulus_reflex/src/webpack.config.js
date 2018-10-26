module.exports = {
  mode: 'production',
  target: 'web',
  entry: './index.js',
  plugins: [],
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: 'babel-loader',
        options: {
          presets: ['@babel/preset-env']
        }
      }
    ],
  },
  output: {
    filename: '../../../stimulus_reflex.js',
    library: 'StimulusReflex',
    libraryTarget: "global"
  }
};
