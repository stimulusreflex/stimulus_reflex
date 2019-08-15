[![Lines of Code](http://img.shields.io/badge/lines_of_code-171-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://api.codeclimate.com/v1/badges/2b24fdbd1ae37a24bedb/maintainability)](https://codeclimate.com/github/hopsoft/stimulus_reflex/maintainability)

# StimulusReflex

### Reactive user interfaces with [Rails](https://rubyonrails.org) and [Stimulus](https://stimulusjs.org)

This project aims to support the building of [Single Page Applications (SPAs)](https://en.wikipedia.org/wiki/Single-page_application)
with the Rails tooling you already know and love.
Works perfectly with server rendered HTML, [Stimulus](https://stimulusjs.org), [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA), etc...

#### No need for a complex frontend framework

> The lifecycle of a "modern" SPA app is so convoluted, it requires a team to build and support.
> The wire size and computation demands of these heavy client sites frequently run slower than the server-rendered pages that they replaced.
> With Stimulus Reflex, a Rails developer can build Single Page Applications without the need for client rendering or heavy JS frameworks.

Inspired by [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670). 🙌

## How it Works

1. Render a standard Rails view template
1. Use [Stimulus](https://stimulusjs.org) and [ActionCable](https://edgeguides.rubyonrails.org/action_cable_overview.html) to invoke a method on the server
1. Watch the page automatically render updates via fast [DOM diffing](https://github.com/patrick-steele-idem/morphdom)
1. That's it...

__Yes, it really is that simple.__
There are no hidden gotchas.

![How it Works](https://raw.githubusercontent.com/hopsoft/stimulus_reflex/master/docs/diagram.png)

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
    // trigger a server-side reflex and a client-side page update
    this.stimulate('ExampleReflex#increment', 1);
  }
}
```

### app/reflexes/example_reflex.rb

```ruby
class ExampleReflex < StimulusReflex::Reflex
  def increment(step = 1)
    @count = @count.to_i + step
  end
end
```

The following happens after the `StimulusReflex::Reflex` method call finishes.

1. The page that triggered the reflex is re-rerendered. _Instance variables created in the reflex are available to both the controller and view templates._
2. The re-rendered HTML is sent to the client over the ActionCable socket.
3. The page is updated via fast DOM diffing courtesy of morphdom. _While future versions of StimulusReflex might support more granular updates, today the entire body is re-rendered and sent over the socket._

## Advanced Usage

### ActionCable

StimulusReflex will use the ActionCable defaults of `window.App` and `App.cable` if they exist.
If these defaults do not exist, StimulusReflex will establish a new socket connection.

### ActionCable Rooms

You may find the need to restrict notifications to a specific room.
This can be accomplished by setting the `data-room` attribute on the StimulusController element.

```html
<a href="#" data-controller="example" data-action="click->example#increment" data-room="12345">
```

### Render Delay

An attempt is made to reduce repaint/reflow jitter when users trigger lots of updates.

You can control how long to wait _(think debounce)_ prior to updating the page.
Simply set the `renderDelay` _(milliseconds)_ option when registering the controller.

```javascript
export default class extends Controller {
  connect() {
    StimulusReflex.register(this, {renderDelay: 200});
  }
}
```

The default value is `25`.

## Demo Applications

Building apps with StimulusReflex should evoke your memories of the original [Rails demo video](https://www.youtube.com/watch?v=Gzj723LkRJY).

> Look at all the things I'm **not** doing. -DHH

- [TodoMVC](https://github.com/hopsoft/stimulus_reflex_todomvc)
