---
description: The life of a stimulus reflex
---

# Lifecycle

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex)
[![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex)
[![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

StimulusReflex supports 4 lifecycle events.

1. **`before`** - prior to sending a stimulate request over the web socket
2. **`success`** - after the server side reflex succeeds and the DOM has been updated
3. **`error`** - whenever the server side reflex raises an error
4. **`after`** - after both `success` and `error`

{% hint style="info" %}
**Using the lifecycle is not a requirement.** Think of it as a power tool that will help you build more sophisticated applications.
{% endhint %}

## Quick Start

Simply declare lifecycle methods in your StimulusReflex controller.

{% code-tabs %}
{% code-tabs-item title="app/views/examples/show.html.erb" %}
```text
<a href="#"
   data-controller="example"
   data-reflex="click->ExampleReflex#update">
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

  beforeUpdate() {
    // show spinner
  }

  afterUpdate() {
    // hide spinner
  }
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% hint style="danger" %}
The methods `beforeUpdate` and `afterUpdate` use a naming convention that matches their suffix to the reflex method name `ExampleReflex#update`
{% endhint %}

## Generic Lifecycle Methods

StimulusReflex controllers can define 4 generic lifecycle methods which provide a simple way to hook into descendant reflexes.

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

## Custom Lifecycle Methods

StimulusReflex controllers can define 4 custom lifecycle methods for each descendant reflex. These methods use a naming convention based on the reflex. For example, the reflex `ExampleReflex#update` will produce the following lifecycle methods.

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

{% hint style="info" %}
**It's not required to implement all lifecycle methods.** Pick and choose which lifecycle methods makes sense for your application.
{% endhint %}

## Conventions

### Method Names

Lifecycle methods apply a naming convention based on the reflex. For example, the reflex `ExampleReflex#do_stuff` will produce the following lifecycle methods.

1. `beforeDoStuff`
2. `doStuffSuccess`
3. `doStuffError`
4. `afterDoStuff`

### Method Signatures

Both generic and custom lifecycle methods share the same function arguments.

* `beforeReflex(element)`  **element** - the element that triggered the reflex
* `reflexSuccess(element)` **element** - the element that triggered the reflex
* `reflexError(element, error)` **element** - the element that triggered the reflex **error** - the error message
* `afterReflex(element, error)` **element** - the element that triggered the reflex **error** - the error message if an error occurred, otherwise `null`

