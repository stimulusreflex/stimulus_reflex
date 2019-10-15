---
description: Reflex classes are like before_filters for your page renders
---

# Reflexes

Server side reflexes inherit from `StimulusReflex::Reflex` and hold logic responsible for performing operations like writing to your backend data stores. Reflexes are not concerned with rendering because rendering is delegated to the Rails controller and action that originally rendered the page.

{% hint style="danger" %}
Do not create server side reflex methods named `reflex` as this is a reserved word.
{% endhint %}

## Calling a Reflex

Regardless of whether you use declarative Reflex calls via `data-reflex` attributes in your HTML or if you are using JavaScript, ultimately the `stimulate` method on your Stimulus controller is being called. We touched on this briefly in the **Quick Start** chapter; now we are going to document the function signature so that you fully understand what's happening behind the scenes.

All Stimulus controllers that have had `StimulusReflex.register(this)` called in their `connect` method gain a `stimulate` method.

```text
this.stimulate(string target, [DOMElement element], [JSONObject argument])
```

**target**, required: a string containing the server Reflex class and method, in the form "ExampleReflex\#increment".

**element**, optional: a reference to a DOM element which will provide both attributes and scoping selectors. Frequently pointed to `event.target` in Javascript. **Defaults to the DOM element of the controller in scope**.

**argument**, optional: any JSON-compliant Javascript datatype including an array, object, string, numeric or boolean that is received by the server Reflex method as an argument. Defaults to no argument.

## Reflex Properties

StimulusReflex makes the following properties available to the developer in the Reflex methods.

* `connection` - the ActionCable connection
* `channel` - the ActionCable channel
* `request` - an `ActionDispatch::Request` proxy for the socket connection
* `session` - the `ActionDispatch::Session` store for the current visitor
* `url` - the URL of the page that triggered the reflex
* `element` - a Hash like object that represents the HTML element that triggered the reflex

### `element`

The `element` property contains all of the Stimulus controller's [DOM element attributes](https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes) as well as other properties like `checked` and `value`.

{% hint style="info" %}
**Most values are strings.** The only exceptions are `checked` and `selected` which are booleans.
{% endhint %}

Here's an example that outlines how you can interact with the `element` property in your reflexes.

{% code-tabs %}
{% code-tabs-item title="app/views/examples/show.html.erb" %}
```markup
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

