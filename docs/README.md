---
description: Build reactive applications with the Rails tooling you already know and love.
---

# StimulusReflex

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

**Build reactive applications with the Rails tooling you already know and love.** StimulusReflex is designed to work perfectly with [server rendered HTML](https://guides.rubyonrails.org/action_view_overview.html), [Russian doll caching](https://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), [Stimulus](https://stimulusjs.org/), [Turbolinks](https://www.youtube.com/watch?v=SWEts0rlezA), etc... and strives to live up to the vision outlined in [The Rails Doctrine](https://rubyonrails.org/doctrine/).

> Ship projects faster... with smaller teams.

## Before you Begin

A great user experience can be created with Rails alone. Tools like [UJS remote elements](https://guides.rubyonrails.org/working_with_javascript_in_rails.html#remote-elements) , [Stimulus](https://stimulusjs.org/), and [Turbolinks](https://github.com/turbolinks/turbolinks) are incredibly powerful when combined. Try building your application using these tools before introducing StimulusReflex.

{% hint style="info" %}
See the [Stimulus TodoMVC](https://github.com/hopsoft/stimulus_todomvc) example application if you are unsure how to do this.
{% endhint %}

## Benefits

StimulusReflex offers 3 primary benefits over the traditional Rails request/response cycle.

1. **All communication happens via web socket** - avoids the overhead of traditional HTTP connections
2. **The controller action is invoked directly** - skips framework overhead like the middleware chain
3. **DOM diffing is used to update the page** - provides faster rendering and less jitter

## Setup

```bash
yarn add stimulus_reflex
```

{% code-tabs %}
{% code-tabs-item title="app/javascript/controllers/index.js" %}
```javascript
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'
import StimulusReflex from 'stimulus_reflex'

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/)
application.load(definitionsFromContext(context))
StimulusReflex.initialize(application)
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="Gemfile" %}
```ruby
gem "stimulus_reflex"
```
{% endcode-tabs-item %}
{% endcode-tabs %}

## Quick Start

Here are a few small contrived examples to get you started.

### No JavaScript

It's possible to build a reactive application without writing any JavaScript. This requires 2 steps.

1. Declare the appropriate data attributes in HTML.
2. Create a server side reflex object with Ruby.

This example will automatically update the page with the latest count whenever the anchor is clicked.

{% code-tabs %}
{% code-tabs-item title="app/views/pages/example.html.erb" %}
```text
<head></head>
  <body>
    <a href="#"
       data-reflex="click->ExampleReflex#increment"
       data-step="1"
       data-count="<%= @count.to_i %>">
      Increment <%= @count.to_i %>
    </a>
  </body>
</html>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  def increment
    @count = element.dataset[:count].to_i + element.dataset[:step].to_i
  end
end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% hint style="success" %}
**Concerns like managing state and template rendering are handled server side.** This technique works regardless of how complex the UI becomes. For example, we could render multiple instances of `@count` in unrelated sections of the page and they will all update.
{% endhint %}

{% hint style="danger" %}
Do not create server side reflex methods named `reflex` as this is a reserved word.
{% endhint %}

### Some JavaScript

Real world applications typically warrant setting up finer grained control. This requires 3 steps.

1. Declare the appropriate data attributes in HTML.
2. Create a client side StimulusReflex controller with JavaScript.
3. Create a server side reflex object with Ruby.

This example will automatically update the page with the latest count whenever the anchor is clicked.

{% code-tabs %}
{% code-tabs-item title="app/views/pages/example.html.erb" %}
```text
<head></head>
  <body>
    <a href="#"
       data-controller="example"
       data-action="click->example#increment">
      Increment <%= @count.to_i %>
    </a>
  </body>
</html>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

```javascript
import { Controller } from 'stimulus';
import StimulusReflex from 'stimulus_reflex';

export default class extends Controller {
  connect() {
    StimulusReflex.register(this);
  }

  increment() {
    // trigger a server-side reflex and a client-side page update
    // pass the step argument with a value of `1` to the reflex method
    this.stimulate('ExampleReflex#increment', 1);
  }
}
```

{% code-tabs %}
{% code-tabs-item title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  def increment(step = 1)
    # In a typical Rails app the Rails controller would set the value of @count
    # after fetching it from a persistent data store
    # @count = @count.to_i + step

    # To keep this example simple, we use session to store the value
    session[:count] = session[:count].to_i + step
    @count = session[:count]
  end
end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

## How it Works

Here's what happens whenever a `StimulusReflex::Reflex` is invoked.

1. The page that triggered the reflex is re-rerendered.
2. The re-rendered HTML is sent to the client over the ActionCable socket.
3. The page is updated via fast DOM diffing courtesy of morphdom.

{% hint style="success" %}
All instance variables created in the reflex are made available to the Rails controller and view.
{% endhint %}

{% hint style="info" %}
**The entire body is re-rendered and sent over the socket.** Smaller scoped DOM updates may come in a future release.
{% endhint %}

## Example Applications

* [TodoMVC](https://stimulus-reflex-todomvc.herokuapp.com) - An implementation of [TodoMVC](http://todomvc.com/) using [Ruby on Rails](https://rubyonrails.org/), [StimulusJS](https://stimulusjs.org/), and [StimulusReflex](https://github.com/hopsoft/stimulus_reflex). [https://github.com/hopsoft/stimulus\_reflex\_todomvc](https://github.com/hopsoft/stimulus_reflex_todomvc)

