[![Lines of Code](http://img.shields.io/badge/lines_of_code-160-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://api.codeclimate.com/v1/badges/2b24fdbd1ae37a24bedb/maintainability)](https://codeclimate.com/github/hopsoft/stimulus_reflex/maintainability)

# StimulusReflex

__Effortlessly create rich interactive UIs with standard Rails... no need for a complex frontend framework.__

#### Server side reactive behavior for Stimulus

Add the benefits of single page apps (SPA) to server rendered Rails/Stimulus projects with a minimal investment of time, resources, and complexity.
_The goal is to provide 80% of the benefits of SPAs with 20% of the typical effort._

> This library provides functionality similar to [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670) for Rails applications.

## Usage

### Gemfile

```ruby
gem "stimulus_reflex"
```

### app/views/layouts/application.html.erb

```erb
<html>
  <head></head>
  <body data-cable>
    <%= yield %>
  </body>
</html>
```

Pages must opt in to establish the ActionCable connection.
This eliminates unauthorized connection attempts.

SEE: https://gist.github.com/hopsoft/02dfdf4456b3ac52f4eaf242289bdd36

### app/assets/javascripts/cable.js

```javascript
//= require action_cable
//= require cable_ready
//= require stimulus_reflex
//= require_self
//= require_tree ./channels

(function() {
  document.addEventListener('DOMContentLoaded', function () {
    if (document.querySelector('body[data-cable]')) {
      // be defensive since stimulus_reflex also initializes this.App and App.cable
      this.App || (this.App = {});
      App.cable || (App.cable = ActionCable.createConsumer());
    }
  });
}.call(this));
```

### app/javascript/controllers/example.js

```javascript
import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    StimulusReflex.register(this);
  }

  doStuff() {
    // trigger a server side reflex and a re-render
    this.stimulate('ExampleReflex#do_stuff', arg1, arg2, ...);
  }
}
```

### app/reflexes/example_reflex.rb

```ruby
class ExampleReflex < StimulusReflex::Reflex
  def do_stuff(arg1, arg2, ...)
    # stuff...
  end
end
```

The magic happens after the `StimulusReflex::Reflex` method call finishes.

1. The page that triggered the reflex is re-rerendered
1. The re-rendered HTML is sent over the ActionCable socket
1. The client side DOM diffs the existing page's HTML with the fresh HTML and applies DOM updates for the change delta

### ActionCable Defaults Expected

StimulusReflex will use or create `window.App` and `App.cable`
and is typically loaded before the default ActionCable initialization code.

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
# wraps the stimulus reflex method invocation
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

The JavaScript source is located in `app/assets/javascripts/stimulus_reflex/src`
& transpiles to `app/assets/javascripts/stimulus_reflex.js` via Webpack.

```sh
# build the javascript
./bin/yarn
./bin/webpack
```
