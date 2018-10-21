[![Lines of Code](http://img.shields.io/badge/lines_of_code-131-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://img.shields.io/codeclimate/maintainability/hopsoft/stimulus_reflex.svg)](https://codeclimate.com/github/hopsoft/stimulus_reflex)

# StimulusReflex

#### Server side reactive behavior for Stimulus controllers

Add the benefits of single page app (SPA) behavior to your Rails/Stimulus app with a minimal investment in time, resources, and complexity.
_The goal is to provide 80% of the benefits of SPAs with 20% of the typical effort._

> This library provides functionality similar to [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670) for Rails applications.

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
# app/stimulus_controllers/example_stimulus_controller.rb
class ExampleStimulusController < StimulusReflex::Controller
  def do_stuff(arg1, arg2, ...)
    # hard work...
    # 1. the page that triggered this call will rererender
    # 2. the HTML will be sent over the ActionCable socket
    # 3. client side JavaScript will DOM diff and mutate only the changed nodes
  end
end
```

## Advanced Usage

### Page Rerender

The page is always rerendered after triggering a `StimulusReflex`.
The client side JavaScript debounces this render via `setTimeout` to prevent a jarring user experience.
The default delay of `400ms` can be overriddend with the following JavaScript.

```javascript
StimulusReflex.renderDelay = 200;
```

## Instrumentation

SEE: https://guides.rubyonrails.org/active_support_instrumentation.html

```ruby
# wraps the stimulus controller method invocation
ActiveSupport::Notifications.subscribe "delegate_call.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end

# instruments the page rerender
ActiveSupport::Notifications.subscribe "render_page.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end

# wraps the web socket broadcast
ActiveSupport::Notifications.subscribe "broadcast.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end

# wraps the entire receive operation which includes everything above
ActiveSupport::Notifications.subscribe "receive.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end
```

## JavaScript Development

The JavaScript source is located in `vendor/assets/javascripts/stimulus_reflex/src`
& transpiles to `vendor/assets/javascripts/stimulus_reflex/stimulus_reflex.js` via Webpack.

```sh
cd vendor/assets/javascripts/stimulus_reflex/src
node_modules/webpack/bin/webpack.js
```
