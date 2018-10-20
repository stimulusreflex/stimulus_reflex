[![Lines of Code](http://img.shields.io/badge/lines_of_code-128-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)

# StimulusReflex

#### Server side reactive behavior for Stimulus controllers

## TODO

- [ ] Allow Ruby channels to override the stream_name
- [ ] Support send without render

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

```javascript
// javascript/controllers/example.js
import { Controller } from "stimulus"

export default class extends Controller {
  initialize() {
    StimulusReflex.register(this);
  }

  doStuff() {
    send('Example#do_stuff', arg1, arg2, ...);
  }
}
```


## JavaScript Development

The JavaScript source is located in `vendor/assets/javascripts/stimulus_reflex/src`
& transpiles to `vendor/assets/javascripts/stimulus_reflex/stimulus_reflex.js` via Webpack.

```sh
cd vendor/assets/javascripts/stimulus_reflex/src
node_modules/webpack/bin/webpack.js
```
