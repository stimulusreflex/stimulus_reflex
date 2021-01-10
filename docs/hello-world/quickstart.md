---
description: How to use StimulusReflex in your app
---

# Quick Start

## Before you begin...

**A great user experience can be created with Rails alone.** Tools such as [Russian Doll caching](https://www.speedshop.co/2015/07/15/the-complete-guide-to-rails-caching.html), [UJS](https://guides.rubyonrails.org/working_with_javascript_in_rails.html#remote-elements), [Stimulus](https://stimulusjs.org/), and [Turbo Drive](https://turbo.hotwire.dev/handbook/drive) are incredibly powerful when combined. Could you build your application using these tools without introducing StimulusReflex?

{% hint style="warning" %}
We are only alive for a short while and learning any new technology is a sacrifice of time spent with those you love, creating art or walking in the woods. 👨‍👨‍👧‍👧🎨🌲

Every framework you learn is a lost opportunity to build something that could really matter to the world. **Please choose responsibly.** ⏳
{% endhint %}

It might strike you as odd that we would start by questioning whether you need this library at all. Our motivations are an extension of the question we hope more people will ask.

Instead of _"Which Single Page App framework should I use?"_ we believe that StimulusReflex can empower people to wonder "**Do we still need React, given what we now know is possible?**" 🤯

## Video Tutorial: Introduction to StimulusReflex

[Chris ](https://twitter.com/excid3)from [GoRails ](https://gorails.com)has released the first of hopefully many tutorial videos demonstrating how to get up and running with StimulusReflex in about ten minutes: ⏱️👍

![](https://gblobscdn.gitbook.com/assets%2F-Lpnm81iPOBUa9lAmLxg%2F-M6sksqaSV7fV1MX_89U%2F-M6slxV1wY8azS1XCRxn%2Fgorails.jpg)

{% embed url="https://gorails.com/episodes/stimulus-reflex-basics" caption="" %}

## Hello, Reflex World!

There are two ways to enable StimulusReflex in your projects: use the `data-reflex` attribute to declare a reflex without any code, or call the `stimulate` method inside of a Stimulus controller. We can use these techniques interchangeably, and both of them trigger a server-side _"Reflex action"_ in response to users interacting with your UI.

Let's dig into it!

### Trigger Reflex actions with data-reflex attributes

This example updates the page with the latest count when the link is clicked:

{% code title="app/views/pages/index.html.erb" %}
```text
<a href="#"
  data-reflex="click->Counter#increment"
  data-step="1" 
  data-count="<%= @count.to_i %>"
>Increment <%= @count.to_i %></a>
```
{% endcode %}

We use data attributes to declaratively tell StimulusReflex to pay special attention to this anchor link. The `data-reflex` attribute allows us to map an action on the client to code that will be executed on the server.

The syntax follows Stimulus format: `[DOM-event]->[ReflexClass]#[action]`

{% hint style="success" %}
While `click` and `change` are two of the most common events used to initiate Reflex actions, you can use `mouseover`, `drop`, `play` and [any others](https://developer.mozilla.org/en-US/docs/Web/Events) that makes sense for your application.

We do caution you to be careful with events that can trigger many times in a short period such as `scroll`, `drag`, `resize` or `mousemove`. It's possible to use a [debounce strategy](../appendices/events.md#throttle-and-debounce) to reduce how many events are emitted. 
{% endhint %}

The other two attributes `data-step` and `data-count` are used to pass data to the server. You can think of them as arguments.

{% code title="app/reflexes/counter\_reflex.rb" %}
```ruby
class CounterReflex < ApplicationReflex
  def increment
    @count = element.dataset[:count].to_i + element.dataset[:step].to_i
  end
end
```
{% endcode %}

StimulusReflex maps your requests to Reflex classes that live in your `app/reflexes` folder. In this example, the `increment` action is called and the count is incremented by 1. The `@count` instance variable is passed to the template when it is re-rendered.

{% hint style="success" %}
**Concerns like managing state and rendering views are handled server side.** Instance variables set in the Reflex action can be combined with cached fragments and potentially updated data fetched from ActiveRecord to modify the UI.

_The magic is that there is no magic_. What the user sees is exactly what they will see if they refresh the page in their browser.

StimulusReflex keeps a 1:1 relationship between application state and what is visible in the browser so that you simply don't have to manage state on the client. This translates to a massive reduction in application complexity and frees you to spend your time on features instead of state synchronization.
{% endhint %}

{% hint style="warning" %}
If you change the code in a Reflex class, you must refresh the page in your browser to interact with the new version of your code.
{% endhint %}

### Trigger Reflex actions inside Stimulus controllers

Real-world applications will benefit from additional structure and more granular control. Building on the solid foundation that Stimulus provides, we can import StimulusReflex into our Stimulus controllers and build complex functionality.

Let's build on our increment counter example by adding a Stimulus controller and manually triggering a Reflex action by calling the `stimulate` method.

1. Declare the appropriate data attributes in HTML.
2. Create a client side StimulusReflex controller with JavaScript.
3. Create a server side Reflex object with Ruby.
4. Create a server side Example controller with Ruby.

We can use the standard Stimulus `data-controller` and `data-action` attributes, which can be [changed if you have a conflict](../appendices/troubleshooting.md#modifying-the-default-data-attribute-schema). There's no StimulusReflex-specific markup required:

{% code title="app/views/pages/index.html.erb" %}
```text
<a href="#"
  data-controller="counter"
  data-action="click->counter#increment"
>Increment <%= @count %></a>
```
{% endcode %}

Now we can create a simple Stimulus controller that extends `ApplicationController`, which is installed with StimulusReflex. It takes care of making your controller automatically inherit the `stimulate` method:

{% code title="app/javascript/controllers/counter\_controller.js" %}
```javascript
import ApplicationController from './application_controller.js'

export default class extends ApplicationController {
  increment(event) {
    event.preventDefault()
    this.stimulate('Counter#increment', 1)
  }
}
```
{% endcode %}

{% hint style="warning" %}
If you extend `ApplicationController` and need to create a `connect` method, make sure that the first line of your method is `super.connect()` or else you can't call `stimulate`.
{% endhint %}

When the user clicks the anchor, the Stimulus event system calls the `increment` method on our controller. In this example, we pass two parameters: the first one follows the format `[ReflexClass]#[action]` and informs the server which Reflex action in which Reflex class we want to trigger. Our second parameter is an optional argument that is passed to the Reflex action as a parameter.

{% hint style="warning" %}
If you're responding to an event like click on an element that would have a default action \(such as an anchor, button or submit element\) it's very important that you call `preventDefault()` on that event, or else you will experience undesirable side effects such as page navigation or form submission.
{% endhint %}

{% code title="app/reflexes/counter\_reflex.rb" %}
```ruby
class CounterReflex < ApplicationReflex
  def increment(step = 1)
    session[:count] = session[:count].to_i + step
  end
end
```
{% endcode %}

Here, you can see how we accept a `step` argument to our `increment` Reflex action. We're also now switching to using the Rails session object to persist our values across multiple page load operations. Note that you can only provide parameters to Reflex actions by calling the `stimulate` method with arguments; there is no equivalent for Reflexes declared with data attributes.

{% code title="app/controllers/pages\_controller.rb" %}
```ruby
class PagesController < ApplicationController
  def index
    @count = session[:count].to_i
  end
end
```
{% endcode %}

Finally, we set the value of the `@count` instance variable in the controller action. When the page is first loaded, there will be no `session[:count]` value and `@count` will be `nil`, which converts to an integer as 0... our initial value.

{% hint style="success" %}
In a typical Rails app, we would set the value of `@count` after fetching it from a persistent data store such as Postgres or Redis. To keep this example simple, we use Rails' `session` to store our counter value.
{% endhint %}

## StimulusReflex Generator

We provide a generator that performs a scaffold-like functionality for StimulusReflex. It will generate files and classes appropriate to whether you specify a singular or pluralized name for your reflex class. For example, `user` and `users` are both valid and useful in different situations.

```bash
bundle exec rails generate stimulus_reflex user
```

This will create but not overwrite the following files:

1. `app/javascript/controllers/application_controller.js`
2. `app/javascript/controllers/user_controller.js`
3. `app/reflexes/application_reflex.rb`
4. `app/reflexes/user_reflex.rb`

{% hint style="info" %}
If you later destroy a stimulus\_reflex "scaffold" using `bundle exec rails destroy stimulus_reflex user` your `application_reflex.rb` and `application_controller.js` will be preserved.
{% endhint %}

## StimulusReflex Cheatsheet

If you're going to be working with StimulusReflex, you might want to bookmark [Rafe Rosen](https://github.com/existentialmutt)'s excellent reference for frequently used method names and callbacks: [https://devhints.io/stimulus-reflex](https://devhints.io/stimulus-reflex)

