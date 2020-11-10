---
description: How to hook into Reflex activity... aka callbacks
---

# Lifecycle

## Server-Side Reflex Callbacks

StimulusReflex gives you a set of callback events to control how your Reflex actions function. These usual suspects will be familiar to Rails developers:

* `before_reflex`, `around_reflex` , `after_reflex`
* All callbacks can receive multiple symbols representing Reflex actions, an optional block and the following options: `only`, `except`, `if`, `unless`
* You can halt a Reflex - prevent it from executing - by placing `throw :abort` in a `before_reflex` callback. This callback fires before the code in your Reflex action method is called, making it a logical place to implement authorization logic for destructive _state mutations_ aka database updates:

```ruby
class ExampleReflex < StimulusReflex::Reflex
  # will run only if the element has the step attribute, can use "unless" instead of "if" for opposite condition
  before_reflex :do_stuff, if: proc { |reflex| reflex.element.dataset[:step] }

  # will run only if the reflex instance has a url attribute, can use "unless" instead of "if" for opposite condition
  before_reflex :do_stuff, if: :url

  # will run before all reflexes
  before_reflex :do_stuff

  # will run before increment reflex, can use "except" instead of "only" for opposite condition
  before_reflex :do_stuff, only: [:increment]

  # will run around all reflexes, must have a yield in the callback
  around_reflex :do_stuff_around

 # will run after all reflexes
  after_reflex :do_stuff

  # Example with a block
  before_reflex do 
    # callback logic
  end

  # Example with multiple method names
  before_reflex :do_stuff, :do_stuff2

  # Example with halt
  before_reflex :run_checks

  def increment
    # reflex logic
  end

  def decrement
    # reflex logic
  end

  private

  def run_checks
    throw :abort # this will prevent the reflex from re-rendering the page
  end

  def do_stuff
    # callback logic
  end

  def do_stuff2
    # callback logic
  end

  def do_stuff_around
    # before
    yield
    # after
  end
end
```

## Client-Side Reflex Callbacks

StimulusReflex gives you the ability to inject custom JavaScript at five distinct moments **around** sending an event to the server and updating the DOM. These hooks allow you to improve the user experience and handle edge cases.

1. **`before`** prior to sending a request over the web socket
2. **`success`** after the server side Reflex succeeds and the DOM has been updated
3. **`error`** whenever the server side Reflex raises an error
4. **`halted`** Reflex canceled with `throw :abort` in the `before_reflex` callback
5. **`after`** after both `success` and `error`

{% hint style="info" %}
**Using lifecycle callback methods is not a requirement.**

Think of them as power tools that can help you build more sophisticated results. 👷
{% endhint %}

If you define a method with a name that matches what the library searches for, it will run at just the right moment. **If there's no method defined, nothing happens.** StimulusReflex will only look for these methods in Stimulus controllers that have called `StimulusReflex.register(this)` in their `connect()` function.

There are two kinds of callback methods: **generic** and **custom**. Generic callback methods are invoked for every Reflex action on a controller. Custom callback methods are only invoked for specific Reflex actions.

StimulusReflex also emits lifecycle events which can be captured in other Stimulus controllers, [jQuery plugins](https://github.com/leastbad/jquery-events-to-dom-events) or even the console.

### Generic Lifecycle Methods

StimulusReflex controllers automatically support five generic lifecycle callback methods. These methods fire for every Reflex action handled by the controller.

1. `beforeReflex`
2. `reflexSuccess`
3. `reflexError`
4. `reflexHalted`
5. `afterReflex`

{% hint style="warning" %}
While this is perfect for simpler Reflexes with a small number of actions, most developers quickly switch to using [Custom Lifecycle Methods](https://docs.stimulusreflex.com/lifecycle#custom-lifecycle-methods), which allow you to define different callbacks for every action.
{% endhint %}

In this example, we update each anchor's text before invoking the server side Reflex:

{% code title="app/views/examples/show.html.erb" %}
```markup
<div data-controller="example">
  <a href="#" data-reflex="Example#masticate">Eat</a>
  <a href="#" data-reflex="Example#deficate">Poop</a>
</div>
```
{% endcode %}

{% code title="app/javascript/controllers/example\_controller.js" %}
```javascript
import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  beforeReflex(anchorElement) {
    const { reflex } = anchorElement.dataset
    if (reflex.match(/masticate$/)) anchorElement.innerText = 'Eating...'
    if (reflex.match(/deficate$/)) anchorElement.innerText = 'Pooping...'
  }
}
```
{% endcode %}

### Custom Lifecycle Methods

StimulusReflex controllers can define up to five custom lifecycle callback methods for **each** Reflex action. These methods use a naming convention **based on the name of the Reflex**. The naming follows the pattern `<actionName>Success` and matches the camelCased name of the action.

The Reflex `Example#poke` will cause StimulusReflex to check for the existence of the following lifecycle callback methods:

1. `beforePoke`
2. `pokeSuccess`
3. `pokeError`
4. `pokeHalted`
5. `afterPoke`

{% code title="app/views/examples/show.html.erb" %}
```markup
<div data-controller="example">
  <a href="#" data-reflex="Example#poke">Poke</a>
  <a href="#" data-reflex="Example#purge">Purge</a>
</div>
```
{% endcode %}

{% code title="app/javascript/controllers/example\_controller.js" %}
```javascript
import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  beforePoke(anchorElement) {
    anchorElement.innerText = 'Poking...'
  }

  beforePurge(anchorElement) {
    anchorElement.innerText = 'Purging...'
  }
}
```
{% endcode %}

Adapting the Generic example, we've refactored our controller to capture the `before` callback events for each anchor individually.

{% hint style="info" %}
**It's not required to implement all lifecycle methods.** Pick and choose which lifecycle callback methods make sense for your application. The answer is frequently **none**.
{% endhint %}

{% hint style="warning" %}
Adding a declarative Reflex such as `Foo#action` to your element does **not** automatically attach an instance of the _foo_ Stimulus controller to the element.

This coupling would only add an unnecessary constraint, as you can call any Reflex from any Stimulus controller.

If you want to run Reflex lifecycle callbacks on your element, you need to use `data-controller="foo"` to attach it.

You can use **both** `data-reflex` and `data-controller` at the same time.
{% endhint %}

### Conventions

#### Method Names

Lifecycle callback methods apply a naming convention based on your Reflex actions. For example, the Reflex `ExampleReflex#do_stuff` will produce the following camel-cased lifecycle callback methods.

1. `beforeDoStuff`
2. `doStuffSuccess`
3. `doStuffError`
4. `doStuffHalted`
5. `afterDoStuff`

#### Method Signatures

Both generic and custom lifecycle callback methods share the same arguments:

* `beforeReflex(element, reflex, noop, reflexId)`
* `reflexSuccess(element, reflex, noop, reflexId)`
* `reflexError(element, reflex, error, reflexId)`
* `reflexHalted(element, reflex, noop, reflexId)`
* `afterReflex(element, reflex, noop, reflexId)`

**element** - the DOM element that triggered the Reflex _this may not be the same as the controller's `this.element`_

**reflex** - the name of the server side Reflex

**error/noop** - the error message \(for reflexError\), otherwise `null`

**reflexId** - a UUID4 or developer-provided unique identifier for each Reflex

### Lifecycle Events

If you need to know when a Reflex method is called, but you're working outside of the Stimulus controller that initiated it, you can subscribe to receive DOM events.

DOM events are limited to the generic lifecycle; developers can obtain information about which Reflex methods were called by inspecting the detail object when the event is captured.

Events are dispatched on the same element that triggered the Reflex. Events bubble but cannot be cancelled.

#### Event Names

* `stimulus-reflex:before`
* `stimulus-reflex:success`
* `stimulus-reflex:error`
* `stimulus-reflex:halted`
* `stimulus-reflex:after`

#### Event Metadata

When an event is captured, you can obtain all of the data required to respond to a Reflex action:

```javascript
document.addEventListener('stimulus-reflex:before', event => {
  event.target // the element that triggered the Reflex (may not be the same as controller.element)
  event.detail.reflex // the name of the invoked Reflex
  event.detail.reflexId // the UUID4 or developer-provided unique identifier for each Reflex
  event.detail.controller // the controller that invoked the stimuluate method
})
```

`event.target` is a reference to the element that triggered the Reflex, and `event.detail.controller` is a reference to the instance of the controller that called the `stimulate` method. This is especially handy if you have multiple instances of a controller on your page.

{% hint style="info" %}
Knowing which element dispatched the event might appear daunting, but the key is in knowing how the Reflex was created. If a Reflex is declared using a `data-reflex` attribute in your HTML, the event will be emitted by the element with the attribute.

If you're calling the `stimulate` method inside of a Stimulus controller, the event will be emitted by the element the `data-controller` attribute is declared on.
{% endhint %}

### Promises

Are you a hardcore JavaScript developer? A props power-lifter? Then you'll be pleased to know that in addition to lifecycle methods and events, StimulusReflex allows you to write promise resolver functions:

```javascript
this.stimulate('Comments#create')
  .then(() => this.doSomething())
  .catch(() => this.handleError())
```

You can get a sense of the possibilities:

```javascript
this.stimulate('Post#publish')
  .then(payload => {
    const { data, element, event } = payload
    const { attrs, reflexId } = data
    // * attrs - an object that represents the attributes of the element that triggered the reflex
    // * data - the data sent from the client to the server over the web socket to invoke the reflex
    // * element - the element that triggered the reflex
    // * event - the source event
    // * reflexId - a unique identifier for this specific reflex invocation
  })
  .catch(payload => {
    const { data, element, event } = payload
    const { attrs, reflexId } = data
    const { error } = event.detail.stimulusReflex
    // * attrs - an object that represents the attributes of the element that triggered the reflex
    // * data - the data sent from the client to the server over the web socket to invoke the reflex
    // * element - the element that triggered the reflex
    // * error - the error message from the server
    // * event - the source event
    // * reflexId - a unique identifier for this specific reflex invocation
  })
```

You can get the `reflexId` of an unresolved promise:

```javascript
const snail = this.stimulate('Snail#secrete')
console.log(snail.reflexId)
snail.then(trail => {})
```

## StimulusReflex Library Events

In addition to the Reflex lifecycle mechanisms, the StimulusReflex client library emits its own set of handy DOM events which you can hook into and use in your applications.

* `stimulus-reflex:connected`
* `stimulus-reflex:disconnected`
* `stimulus-reflex:rejected`
* `stimulus-reflex:ready`

All four events fire on `document`.

`connected` fires when the ActionCable connection is established, which is a precondition of a successful call to `stimulate` - meaning that you can delay calls until the event arrives. It will also fire after a `disconnected` subscription is reconnected.

`disconnected` fires if the connection to the server is lost; the `detail` object of the event has a `willAttemptReconnect` boolean which should be `true` in most cases.

`rejected` is fired if you're doing authentication in your Channel and the subscription request was denied.

`ready` is slightly different than the first three, in that it has nothing to do with the ActionCable subscription. Instead, it is called after StimulusReflex has scanned your page, looking for declared Reflexes to connect. This event fires every time the document body is modified, and was created primarily to support automated JS test runners like Cypress. Without this event, Cypress tests would have to wait for a few seconds before "clicking" on Reflex-enabled UI elements.

