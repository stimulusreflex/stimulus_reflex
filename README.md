[![Lines of Code](http://img.shields.io/badge/lines_of_code-120-brightgreen.svg?style=flat)](http://blog.codinghorror.com/the-best-code-is-no-code-at-all/)
[![Maintainability](https://api.codeclimate.com/v1/badges/2b24fdbd1ae37a24bedb/maintainability)](https://codeclimate.com/github/hopsoft/stimulus_reflex/maintainability)
[![Ruby Dependency Graph](https://img.shields.io/badge/deps-ruby-informational.svg?style=flat)](https://github.com/hopsoft/stimulus_reflex/blob/master/gem_graph.svg)

# StimulusReflex

#### Build rich interactive UIs with standard Rails... no need for a complex frontend framework

This library provides functionality similar to [Phoenix LiveView](https://youtu.be/Z2DU0qLfPIY?t=670) for Rails applications.

Add the benefits of single page apps (SPA) to server rendered Rails/Stimulus projects with a minimal investment of time, resources, and complexity.
_The goal is to provide 80% of the benefits of SPAs with 20% of the typical effort._

1. Use [ActionCable](https://edgeguides.rubyonrails.org/action_cable_overview.html) to invoke a method on the server.
1. Watch the page automatically render updates via fast [DOM diffing](https://github.com/patrick-steele-idem/morphdom).
1. That's it...

  - Yes, it really is that simple. Just write your HTML page.
  - If you hit refresh, that works, too.
  - There's no hidden gotcha.

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
3. The page is updated via fast DOM diffing courtesy of morphdom. _While future versions of StimulusReflex might support more granular updates, today the entire body re-rendered and sent over the socket._

### ActionCable

StimulusReflex will use the Rails' ActionCable defaults `window.App` and `App.cable` if they exist.
If these defaults do not exist, StimulusReflex will attempt to establish a new socket connection.

## JavaScript Development

The JavaScript library is hosted at: https://github.com/hopsoft/stimulus_reflex_client
