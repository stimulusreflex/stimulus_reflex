[![Lines of Code](http://img.shields.io/badge/lines_of_code-123-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)

# StimulusReflex

#### Server side reactive behavior for Stimulus controllers

## TODO

- [ ] Support send without render

## Usage

```ruby
# Gemfile
gem "stimulus_reflex"
```

```javascript
// app/assets/javascripts/cable.js
//= require cable_ready
//= require stimulus_reflex
```

```javascript
// app/javascript/controllers/example.js
import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    StimulusReflex.register(this);
  }

  doStuff() {
    send('Example#do_stuff', arg1, arg2, ...);
  }
}
```

```ruby
# app/stimulus_controllers
class ExampleStimulusController < StimulusReflex::Controller
  def do_stuff(arg1, arg2, ...)
    # hard work...
    # - the page that triggered this call will rererender
    # - the HTML will be sent over the ActionCable socket
    # - client side JavaScript will DOM diff and mutate only the changed nodes
  end
end
```

## JavaScript Development

The JavaScript source is located in `vendor/assets/javascripts/stimulus_reflex/src`
& transpiles to `vendor/assets/javascripts/stimulus_reflex/stimulus_reflex.js` via Webpack.

```sh
cd vendor/assets/javascripts/stimulus_reflex/src
node_modules/webpack/bin/webpack.js
```
