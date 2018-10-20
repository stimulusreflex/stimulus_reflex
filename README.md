# StimulusReflex

#### Server side reactive behavior for Stimulus controllers

## Usage

```ruby
# Gemfile
gem "stimulus_reflex"
```

```
// app/assets/javascripts/cable.js
//= require cable_ready
//= require stimulus_reflex
```




## JavaScript Development

The JavaScript source is located in `vendor/assets/javascripts/stimulus_reflex/src`
& transpiles to `vendor/assets/javascripts/stimulus_reflex/stimulus_reflex.js` via Webpack.

```sh
cd vendor/assets/javascripts/stimulus_reflex/src
node_modules/webpack/bin/webpack.js
```
