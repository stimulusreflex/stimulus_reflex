---
description: How to use StimulusReflex in your app
---

# Quick Start

## Before you begin...

**A great user experience can be created with Rails alone.** Tools such as [UJS remote elements](https://guides.rubyonrails.org/working_with_javascript_in_rails.html#remote-elements), [Stimulus](https://stimulusjs.org/), and [Turbolinks](https://github.com/turbolinks/turbolinks) are incredibly powerful when combined. Could you build your application using these tools without introducing StimulusReflex?

{% hint style="warning" %}
See the [Stimulus TodoMVC](https://github.com/hopsoft/stimulus_todomvc) example application if you are unsure how to do this. **Important note**: this link _does not make use of StimulusReflex_. It is presented for technical comparison and soulful reflection.

We are only alive for a short while and learning any new technology is a sacrifice of time spent with those you love, creating art or walking in the woods.

Every framework you learn is a lost opportunity to build something that could really matter to the world. **Please choose responsibly.**
{% endhint %}

It might strike you as odd that we would start by questioning whether you need this library at all. Our motivations are an extension of the question we hope more people will ask.

Instead of "_Which Single Page App framework should I use?_" we believe that StimulusReflex can empower people to wonder "Do we still need React, given what we now know is possible?"

## Hello, Reflex

Bringing your first Reflex to life couldn't be simpler:

1. Declare the appropriate data attributes in HTML.
2. Create a server side reflex object with Ruby.

### Look mom... no JavaScript!

This example will automatically update the page with the latest count whenever the anchor is clicked.

{% code-tabs %}
{% code-tabs-item title="app/views/pages/example.html.erb" %}
```text
<a href="#"
  data-reflex="click->ExampleReflex#increment"
  data-step="1" 
  data-count="<%= @count.to_i %>"
>Increment <%= @count.to_i %></a>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

We use data attributes to declaratively tell StimulusReflex to pay special attention to this anchor link. `data-reflex` is the command you'll use on almost every action. The format follows the Stimulus convention of `[browser-event]->[ServerSideClass]#[action]`. The other two attributes, `data-step` and `data-count` are used to pass data to the server. You can think of them as arguments.

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

StimulusReflex maps your requests to Reflex classes that live in your `app/reflexes` folder. In this example, the increment method is executed and the count is incremented by 1. The `@count` instance variable is passed to the template when it is re-rendered.

Yes, it really is that simple.

{% hint style="success" %}
**Concerns like managing state and rendering views are handled server side.** This technique works regardless of how complex the UI becomes. For example, we could render multiple instances of `@count` in unrelated sections of the page and they will all update.
{% endhint %}

### Automatic transmission vs manual transmission

Real world applications will benefit from additional structure and more granular control. Building on the solid foundation that Stimulus provides, we can use Controllers to build complex functionality and respond to events.

Let's build on our increment counter example by adding a Controller and manually calling a Reflex action.

1. Declare the appropriate data attributes in HTML.
2. Create a client side StimulusReflex controller with JavaScript.
3. Create a server side Reflex object with Ruby.

{% code-tabs %}
{% code-tabs-item title="app/views/pages/example.html.erb" %}
```text
<a href="#"
  data-controller="example"
  data-action="click->example#increment"
>Increment <%= @count.to_i %></a>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

Here, we rely on the standard Stimulus `data-controller` and `data-action` attributes. There's no StimulusReflex-specific markup required.

```javascript
import { Controller } from 'stimulus';
import StimulusReflex from 'stimulus_reflex';

export default class extends Controller {
  connect() {
    StimulusReflex.register(this)
  }

  increment() {
    this.stimulate('ExampleReflex#increment', 1)
  }
}
```

The Controller connects during the page load process and we tell StimulusReflex that this Controller is going to be calling server-side Reflex actions. The `register` method has an optional 2nd argument that accepts options, but we'll cover that later.

When the user clicks the anchor, Stimulus calls the `increment` method. All StimulusReflex Controllers have access to the `stimulate` method. The first parameter is the `[ServerSideClass]#[action]` syntax, which tells the server which Reflex class and method to call. The second parameter is an optional argument which is passed to the Reflex method. If you need to pass multiple arguments, consider using a JavaScript object `{}` to do so.

{% code-tabs %}
{% code-tabs-item title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  def increment(step = 1)
    session[:count] = session[:count].to_i + step
    @count = session[:count]
  end
end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

Here, you can see how we accept an optional argument to our `increment` Reflex action.

{% hint style="success" %}
In a typical Rails app, we would set the value of `@count` after fetching it from a persistent data store such as Postgres or Redis. To keep this example simple, we use Rails' `session` to store our counter value.
{% endhint %}

