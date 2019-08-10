[![Lines of Code](http://img.shields.io/badge/lines_of_code-171-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://api.codeclimate.com/v1/badges/2b24fdbd1ae37a24bedb/maintainability)](https://codeclimate.com/github/hopsoft/stimulus_reflex/maintainability)

# StimulusReflex

### Reactive user interfaces with Rails and Stimulus

#### No need for a complex frontend framework

This project aims to support the building of [Single Page Applications (SPAs)](https://en.wikipedia.org/wiki/Single-page_application)
with standard Rails tooling. Think server rendered HTML, Stimulus, Turbolinks, etc...

Inspired by [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670). 🙌

## How it Works

1. Use [ActionCable](https://edgeguides.rubyonrails.org/action_cable_overview.html) to invoke a method on the server
1. Watch the page automatically render updates via fast [DOM diffing](https://github.com/patrick-steele-idem/morphdom)
1. That's it...

__Yes, it really is that simple.__
Just create a server rendered HTML page and send RPC calls to the server via web socket.
There are no hidden gotchas.

## Setup

### JavaScript

```
yarn add stimulus_reflex
```

### Gemfile

```ruby
gem "stimulus_reflex"
```

## Basic Usage

### app/views/pages/example.html.erb

```erb
<head></head>
  <body>
    <a href="#" data-controller="example" data-action="click->example#increment">
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

1. The page that triggered the reflex is re-rerendered. _Note that instance variables created in the reflex are available to both the controller and view templates._
2. The re-rendered HTML is sent to the client over the ActionCable socket.
3. The page is updated via fast DOM diffing courtesy of morphdom. _While future versions of StimulusReflex might support more granular updates, today the entire body is re-rendered and sent over the socket._

## Advanced Usage

### ActionCable

StimulusReflex will use the Rails' ActionCable defaults `window.App` and `App.cable` if they exist.
If these defaults do not exist, StimulusReflex will establish a new socket connection.

### ActionCable Rooms

You may find the need to restrict notifications to a specific room.
This can be accomplished by setting the `data-room` attribute on the StimulusController element.

```
<a href="#" data-controller="example" data-action="click->example#increment" data-room="12345">
```

### Render Delay

An attempt is made to reduce repaint/reflow jitter when users may trigger lots of updates.

You can control how long to wait (think debounce) prior to updating the page.
Simply set the `renderDelay` _(milliseconds)_ option when registering the controller.

```javascript
StimulusReflex.register(this, {renderDelay: 200});
```

The default value is `25`.
