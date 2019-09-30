---
description: How to get the most out of StimulusReflex
---

# Advanced Use

## ActionCable

StimulusReflex leverages [Rails ActionCable](https://guides.rubyonrails.org/action_cable_overview.html). Understanding what Rails provides out of the box will help you get the most value from this library.

{% hint style="info" %}
ActionCable defaults of `window.App` and `App.cable` are used if they exist. **A new socket connection will be established if these do not exist.**
{% endhint %}

### Performance

ActionCable emits verbose log messages. Disabling ActionCable logs _may_ improve performance.

{% code-tabs %}
{% code-tabs-item title="config/initializers/action\_cable.rb" %}
```ruby
ActionCable.server.config.logger = Logger.new(nil)
```
{% endcode-tabs-item %}
{% endcode-tabs %}

### Rooms

You might find the need to restrict communication to a specific room. This can be accomplished in 2 ways.

1. Passing the room name as an option to `register`.

{% code-tabs %}
{% code-tabs-item title="app/javascript/controllers/example\_controller.js" %}
```javascript
export default class extends Controller {
  connect() {
    StimulusReflex.register(this, { room: 'ExampleRoom12345' });
  }
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

2. Setting the `data-room` attribute on the StimulusController element.

```markup
<a href="#"
   data-controller="example"
   data-reflex="click->ExampleReflex#do_stuff"
   data-room="12345">
```

{% hint style="danger" %}
**Setting `room` in the DOM's `body` may pose a security risk.** Consider assigning `room` when registering the Stimulus controller instead.
{% endhint %}

## Stimulus Controllers

### Render Delay

An attempt is made to reduce repaint jitter when users trigger several updates in succession.

You can control how long to wait prior to updating the DOM - _think debounce_. Simply set the `renderDelay` option in milliseconds when registering the controller.

{% code-tabs %}
{% code-tabs-item title="app/javascript/controllers/example\_controller.js" %}
```javascript
export default class extends Controller {
  connect() {
    StimulusReflex.register(this, { renderDelay: 200 });
  }
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% hint style="info" %}
`renderDelay` defaults to`25`milliseconds.
{% endhint %}

## Reflexes

Server side reflexes inherit from `StimulusReflex::Reflex` and hold logic responsible for performing operations like writing to your backend data stores. Reflexes are not concerned with rendering because rendering is delegated to the Rails controller and action that originally rendered the page.

### Properties

* `connection` - the ActionCable connection
* `channel` - the ActionCable channel
* `request` - an `ActionDispatch::Request` proxy for the socket connection
* `session` - the `ActionDispatch::Session` store for the current visitor
* `url` - the URL of the page that triggered the reflex
* `element` - a Hash like object that represents the HTML element that triggered the reflex

#### `element`

The `element` property contains all of the Stimulus controller's [DOM element attributes](https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes) as well as other properties like `checked` and `value`.

{% hint style="info" %}
**Most values are strings.** The only exceptions are `checked` and `selected` which are booleans.
{% endhint %}

Here's an example that outlines how you can interact with the `element` property in your reflexes.

{% code-tabs %}
{% code-tabs-item title="app/views/examples/show.html.erb" %}
```text
<checkbox id="example" label="Example" checked
  data-reflex="ExampleReflex#work" data-value="123" />
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  def work()
    element[:id]    # => the HTML element's id attribute value
    element.dataset # => a Hash that represents the HTML element's dataset

    element[:id]                 # => "example"
    element[:checked]            # => true
    element[:label]              # => "Example"
    element["data-reflex"]       # => "ExampleReflex#work"
    element.dataset[:reflex]     # => "ExampleReflex#work"
    element["data-value"]        # => "123"
    element.dataset[:value]      # => "123"
  end
end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

