---
description: AKA callbacks AKA keeping the magic after the honeymoon is over
---

# Lifecycle

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

StimulusReflex gives you the ability to run custom code at four distinct moments __around__ sending an event to the server and updating your DOM. Most of the time, these moments are best spent thinking about what really happened to Oceanic Air Flight 815. Still, there are occasions where we absolutely need to handle an edge case. For those situations, we offer **lifecycle callback methods**:

1. **`before`** - prior to sending a request over the web socket
2. **`success`** - after the server side Reflex succeeds and the DOM has been updated
3. **`error`** - whenever the server side Reflex raises an error
4. **`after`** - after both `success` and `error`

{% hint style="info" %}
**Using the lifecycle callback methods is not a requirement.** Think of it as a power tool that will help you build more sophisticated applications.
{% endhint %}

The idea is that if and when you define a method with a specific name that matches what the library searches for, it will run at just the right moment. __If there's no function, nothing happens.__ StimulusReflex only knows to look for these methods inside of Stimulus controllers that have called `StimulusReflex.register(this)` in their `connect()` function.

There are two kinds of callback methods that you can use: **generic** and **custom**. Generic callback methods fire for every Reflex action on a controller, while custom callback methods are __created dynamically on a 1:1 basis__ for each of your Reflex actions.

When designing your application logic, think of it like taking medicine: it's preferable to take a pill that solves a specific problem, but sometimes you just need to make all of your problems go away at once.

## Generic Lifecycle Methods

StimulusReflex controllers can define up to four generic lifecycle callback methods. These methods fire for every Reflex action handled by the controller.

1. `beforeReflex`
2. `reflexSuccess`
3. `reflexError`
4. `afterReflex`

{% code-tabs %}
{% code-tabs-item title="app/views/examples/show.html.erb" %}
```text
<div data-controller="example">
  <a href="#" data-reflex="ExampleReflex#update">Update</a>
  <a href="#" data-reflex="ExampleReflex#delete">Delete</a>
</div>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="app/javascript/controllers/example\_controller.js" %}
```javascript
import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  beforeReflex(anchorElement) {
    const { reflex } = anchorElement.dataset
    if (reflex.match(/update$/)) anchorElement.innerText = 'Updating...'
    if (reflex.match(/delete$/)) anchorElement.innerText = 'Deleting...'
  }
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

In this example, we update the correct anchor link to change its text before sending the action to the server.

## Custom Lifecycle Methods

StimulusReflex controllers can define up to four custom lifecycle callback methods for **each** Reflex action. These methods use a naming convention __based on the name of the reflex action__. For example, the Reflex `ExampleReflex#update` will cause StimulusReflex to check for the existence of the following lifecycle callback methods:

1. `beforeUpdate`
2. `updateSuccess`
3. `updateError`
4. `afterUpdate`

{% code-tabs %}
{% code-tabs-item title="app/views/examples/show.html.erb" %}
```text
<div data-controller="example">
  <a href="#" data-reflex="ExampleReflex#update">Update</a>
  <a href="#" data-reflex="ExampleReflex#delete">Delete</a>
</div>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="app/javascript/controllers/example\_controller.js" %}
```javascript
import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  beforeUpdate(anchorElement) {
    anchorElement.innerText = 'Updating...'
  }

  beforeDelete(anchorElement) {
    anchorElement.innerText = 'Deleting...'
  }
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

Adapting from the Generic example, we have refactored our controller to capture the `before` callback events for each anchor individually.

{% hint style="info" %}
**It's not required to implement all lifecycle methods.** Pick and choose which lifecycle callback methods make sense for your application. The answer is frequently __none__.
{% endhint %}

## Conventions

### Method Names

Lifecycle callback methods apply a naming convention based on your Reflex actions. For example, the Reflex `ExampleReflex#do_stuff` will produce the following camel-cased lifecycle callback methods.

1. `beforeDoStuff`
2. `doStuffSuccess`
3. `doStuffError`
4. `afterDoStuff`

### Method Signatures

Both generic and custom lifecycle callback methods share the same function arguments.

* `beforeReflex(element)`  **element** - the element that triggered the reflex
* `reflexSuccess(element)` **element** - the element that triggered the reflex
* `reflexError(element, error)` **element** - the element that triggered the reflex **error** - the error message
* `afterReflex(element, error)` **element** - the element that triggered the reflex **error** - the error message if an error occurred, otherwise `null`

