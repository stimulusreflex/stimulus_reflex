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

You might find the need to restrict communication to a specific room. This can be accomplished by setting the `data-room`attribute on the StimulusController element.

```markup
<a href="#"
   data-controller="example"
   data-reflex="click->ExampleReflex#do_stuff"
   data-room="12345">
```

## Render Delay

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

