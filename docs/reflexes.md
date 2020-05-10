---
description: "Reflex classes are full of Reflex actions. Reflex actions? Full of love. \U0001F3E9"
---

# Reflexes

What is a Reflex, really? Is it a transactional UI update that takes place over a persistent open connection to the server? Is it a new tool on your belt that operates adjacent to and in tandem with concepts like REST and Ajax? Is it the smug feelings associated with successfully achieving a massive productivity arbitrage? Is it the boundless potential for unironic good in every child?

A thousand times, _yes_.

## Glossary

* StimulusReflex: the name of this project, which has a JS client and a Ruby based server component that rides along on top of Rails' ActionCable websockets framework
* Stimulus: an incredibly simple yet powerful JS framework by the creators of Rails
* "a Reflex": used to describe the full, round-trip life-cycle of a StimulusReflex operation, from client to server and back again
* Reflex class: a Ruby class that inherits from `StimulusReflex::Reflex` and lives in your `app/reflexes` folder, this is where your Reflex actions are implemented
* Reflex action: a method in a Reflex class, called in response to activity in the browser. It has access to several special accessors containing all of the Reflex controller element's attributes
* Reflex controller: a Stimulus controller that imports the StimulusReflex client library. It has a `stimulate` method for triggering Reflexes and like all Stimulus controllers, it's aware of the element it is attached to - as well as any Stimulus [targets](https://stimulusjs.org/reference/targets) in its DOM hierarchy
* Reflex controller element: the DOM element upon which the `data-reflex` attribute is placed, which often has data attributes intended to be delivered to the server during a Reflex action

## Calling a Reflex

Regardless of whether you use declarative Reflex calls via `data-reflex` attributes in your HTML or if you are using JavaScript, ultimately the `stimulate` method on your Stimulus controller is being called. We touched on this briefly in the **Quick Start** chapter; now we are going to document the function signature so that you fully understand what's happening behind the scenes.

All Stimulus controllers that have had `StimulusReflex.register(this)` called in their `connect` method gain a `stimulate` method.

```javascript
this.stimulate(string target, [DOMElement element], ...[JSONObject argument])
```

**target**, required \(exception: see "Requesting a Refresh" below\): a string containing the server Reflex class and method, in the form "ExampleReflex\#increment".

**element**, optional: a reference to a DOM element which will provide both attributes and scoping selectors. Frequently pointed to `event.target` in Javascript. **Defaults to the DOM element of the controller in scope**.

**argument**, optional: a **splat** of JSON-compliant Javascript datatypes - array, object, string, numeric or boolean - can be received by the server Reflex action as one or many ordered arguments. Defaults to no argument\(s\). **Note: the method signature has to match.** If the Reflex action is expecting two arguments and doesn't receive two arguments, it will raise an exception.

### Requesting a "refresh"

If you are building advanced workflows, there are edge cases where you may want to initiate a Reflex action that does nothing but re-render the view template and morph any new changes into the DOM. While this shouldn't be your primary tool, it's possible for your data to be mutated by destructive external side effects. 🧟

```javascript
this.stimulate()
```

Calling `stimulate` with no parameters invokes a special global Reflex that allows you to force a re-render of the current state of your application UI. This is the same thing that the user would see if they hit their browser's Refresh button, except without the painfully slow round-trip cycle.

It's also possible to trigger this global Reflex by passing nothing but a browser event to the `data-reflex` attribute. For example, the following button element will refresh the page content every time the user presses it:

```markup
<button data-reflex="click">Refresh</button>
```

### Scanning for new data-reflex attributes

StimulusReflex scans the DOM looking for instances of the `data-reflex` attribute. When it finds one, it attaches a `stimulus-reflex` Stimulus controller to that element.

By default, scans happen in response to four events:

| Object | Event |
| :--- | :--- |
| window | load |
| document | turbolinks:load |
| document | cable-ready:after-morph |
| document | ajax:complete |

While those should cover the vast majority of cases, there are scenarios such as client JSX or Handlebars template rendering which require a re-scan of the DOM to pick up new `data-reflex` instances. You can manually request a re-scan in any Stimulus controller that has **already called** `StimulusReflex.register(this)`.

```javascript
StimulusReflex.setupDeclarativeReflexes()
```

If you need to re-scan the DOM after a jQuery operation, you'll need to use the [jquery-events-to-dom-events](https://www.npmjs.com/package/jquery-events-to-dom-events) npm package. This library lets you delegate the events you need so that you can write a DOM event handler for it. In that event handler, call StimulusReflex.setupDeclarativeReflexes\(\) to pick up any new data-reflex attributes.

## Reflex Classes

StimulusReflex makes the following properties available to the developer inside Reflex actions:

* `connection` - the ActionCable connection
* `channel` - the ActionCable channel
* `request` - an `ActionDispatch::Request` proxy for the socket connection
* `session` - the `ActionDispatch::Session` store for the current visitor
* `url` - the URL of the page that triggered the reflex
* `element` - a Hash like object that represents the HTML element that triggered the reflex

{% hint style="danger" %}
`reflex` and `process` are reserved words inside Reflex classes. You cannot create Reflex actions with these names.
{% endhint %}

### `element`

The `element` property contains all of the Stimulus controller's [DOM element attributes](https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes) as well as other properties like, `tagName`, `checked` and `value`.

{% hint style="info" %}
**Most values are strings.** The only exceptions are `checked` and `selected` which are booleans.
{% endhint %}

Here's an example that outlines how you can interact with the `element` property in your reflexes.

{% code title="app/views/examples/show.html.erb" %}
```markup
<checkbox id="example" label="Example" checked
  data-reflex="ExampleReflex#work" data-value="123" />
```
{% endcode %}

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  def work()
    element[:id]    # => the HTML element's id attribute value
    element.dataset # => a Hash that represents the HTML element's dataset

    element[:id]                 # => "example"
    element[:tag_name]           # => "CHECKBOX"
    element[:checked]            # => true
    element[:label]              # => "Example"
    element["data-reflex"]       # => "ExampleReflex#work"
    element.dataset[:reflex]     # => "ExampleReflex#work"
    element["data-value"]        # => "123"
    element.dataset[:value]      # => "123"
  end
end
```
{% endcode %}

{% hint style="success" %}
When StimulusReflex is rendering your template, an instance variable named **@stimulus\_reflex** is available to your Rails controller and set to true.

You can use this flag to create branching logic to control how the template might look different if it's a Reflex vs normal page refresh.
{% endhint %}

### Reflex exceptions are rescuable

If you'd like to wire up 3rd-party exception handling services like Sentry or HoneyBadger to your Reflex classes, you can use `rescue_from` to respond to an errors raised.

```ruby
class MyTestReflex < StimulusReflex::Reflex
  rescue_from StandardError do |exception|
    ExceptionTrackingService.error(exception)
  end
  # ...
end
```

## Flash messages

One Rails mechanism that you might use less in a StimulusReflex application is the flash message object. Flash made a lot more sense in the era of submitting a CRUD form and seeing the result confirmed on the next page load. With StimulusReflex, the current state of the UI might be updated dozens of times in rapid succession and the flash message could be easily lost before it's read.

You'll want to experiment with other, more contemporary feedback mechanisms to provide field validations and event notification functionality. An example would be the Facebook notification widget, or a dedicated notification drop-down that is part of your site navigation.

Clever use of CableReady broadcasts when ActiveJobs complete or models update is likely to produce a cleaner reactive surface for status information.

