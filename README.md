[![Lines of Code](http://img.shields.io/badge/lines_of_code-120-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://api.codeclimate.com/v1/badges/2b24fdbd1ae37a24bedb/maintainability)](https://codeclimate.com/github/hopsoft/stimulus_reflex/maintainability)
[![Ruby Dependency Graph](https://img.shields.io/badge/deps-ruby-informational.svg?style=flat)](https://github.com/hopsoft/stimulus_reflex/blob/master/gem_graph.svg)

# StimulusReflex

#### Build rich interactive UIs with standard Rails... no need for a complex frontend framework

Add the benefits of single page apps (SPA) to server rendered Rails/Stimulus projects with a minimal investment of time, resources, and complexity.
_The goal is to provide 80% of the benefits of SPAs with 20% of the typical effort._

1. Use [ActionCable](https://edgeguides.rubyonrails.org/action_cable_overview.html) to invoke a method on the server
1. Watch the page automatically render updates via fast [DOM diffing](https://github.com/patrick-steele-idem/morphdom)
1. That's it

> This library provides functionality similar to [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670) for Rails applications.

## Setup

### JavaScript

```
yarn add stimulus_reflex
```

### Gemfile

```ruby
gem "stimulus_reflex"
```

## Usage

### app/views/pages/example.html.erb

```erb
<head></head>
  <body>
    <a href="#" data-controller="example" data-action="click->example#doStuff">
      Increment <%= @count.to_i %>
    </a>
  </body>
</html>
```

### app/javascript/controllers/example.js

```javascript
import { Controller } from "stimulus"
import StimulusReflex from "stimulus_reflex"

export default class extends Controller {
  connect() {
    StimulusReflex.register(this);
  }

  increment() {
    // trigger a server side reflex and a re-render
    this.stimulate('ExampleReflex#increment', 1);
  }
}
```

### app/reflexes/example_reflex.rb

```ruby
class ExampleReflex < StimulusReflex::Reflex
  def increment(step = 1)
    @count = @count.to_i += step
  end
end
```

The following happens after the `StimulusReflex::Reflex` method call finishes.

1. The page that triggered the reflex is re-rerendered
1. The re-rendered HTML is sent to the client over the ActionCable socket
1. JavaScript on the client updates the page with any changes via fast DOM diffing

### ActionCable

StimulusReflex will use the Rails' ActionCable defaults `window.App` and `App.cable` if they exist.
If these defaults do not exist, StimulusReflex will attempt to establish a new socket connection.

## Advanced Usage

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

The JavaScript library is hosted at: https://github.com/hopsoft/stimulus_reflex_client
