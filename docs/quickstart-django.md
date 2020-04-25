---
description: How to use Sockpuppet in your app
---

# Quick Start

## Before you begin...

**A great user experience can be created with Django**. Though often django is positioned to be the backend of for a frontend written in either reactjs or vuejs or similar frontend frameworks.

If you are happy with that way of building applications, then you can stop reading now.

We are only alive for a short while and learning any new technology is a sacrifice of time spent with those you love, creating art or walking in the woods.

Every framework you learn is a lost opportunity to build something that could really matter to the world. **Please choose responsibly.**

It might strike you as odd that we would start by questioning whether you need this library at all. Our motivations are an extension of the question we hope more people will ask.

Instead of "_Which Single Page App framework should I use?_" we believe that StimulusReflex can empower people to wonder "**Do we still need React, given what we now know is possible?**"

## Hello, Reflex

Bringing your first Reflex to life couldn't be simpler:

1. Declare the appropriate data attributes in HTML together with a python view.
2. Initialize a stimulus application in javascript.
2. Create a server side reflex object with python.

### Call Reflex methods on the server without defining a Stimulus controller

This example will automatically update the page with the latest count whenever the anchor is clicked.

{% code title="your_app/templates/index.html" %}
```html
<body>
    <a href="#"
    data-reflex="click->CounterReflex#increment"
    data-step="1"
    data-count="{{ count }}"
    >Increment {{ count }}</a>
</body>
```
{% endcode %}

We use data attributes to declaratively tell Sockpuppet to pay special attention to this anchor link. `data-reflex` is the command you'll use on almost every action. The format follows the Stimulus convention of `[browser-event]->[ServerSideClass]#[action]`. The other two attributes, `data-step` and `data-count` are used to pass data to the server. You can think of them as arguments.

We are also assuming that we have a view that renders this template. The view looks like this.

{% code title="your_app/view.py"}
```python
from django.views.generic.base import TemplateView

class CountView(TemplateView):
    template_name = 'index.html'

    def get_context_data(self, *args, **kwargs):
        context = super().get_context_data(*args, **kwargs)
        context['count'] = 0
        return context
```
{% endcode %}

We also need to start a Stimulus application in javascript

{% code title="frontend/src/js/index.js" %}
```javascript
import { Application } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'
import WebsocketConsumer from 'sockpuppet-js'

const application = Application.start()
const consumer = new WebsocketConsumer('ws://localhost:8000/sockpuppet-sync')

StimulusReflex.initialize(application, { consumer })
```
{% endcode %}

Next up is defining a reflex in python.

{% code title="your_app/reflexes/counter\_reflex.py" %}
```python
from sockpuppet.reflex import Reflex

class CounterReflex(Reflex):
    def increment(self):
        self.count = (
            int(self.element.dataset['count']) +
            int(self.element.dataset['step'])
        )

```
{% endcode %}

Sockpuppet maps your requests to Reflex classes that live in your `your_app/reflexes` folder or reflexes that exist in the file `your_app/reflex.py`. In this example, the increment method is executed and the count is incremented by 1. The `self.count` instance variable is passed to the template when it is re-rendered.

Yes, it really is that simple.

{% hint style="success" %}
**Concerns like managing state and rendering views are handled server side.** This technique works regardless of how complex the UI becomes. For example, we could render multiple instances of `self.count` in unrelated sections of the page and they will all update.
{% endhint %}

### Manually call a Reflex from a Stimulus controller

Real world applications will benefit from additional structure and more granular control. Building on the solid foundation that Stimulus provides, we can use Controllers to build complex functionality and respond to events.

Let's build on our increment counter example by adding a Stimulus Controller and manually calling a Reflex action.

1. Declare the appropriate data attributes in HTML.
2. Create a client side StimulusReflex controller with JavaScript.
3. Create a server side Reflex object with Python.
4. Create a server side Example view with Python.

{% code title="app/views/pages/index.html.erb" %}
```html
<body>
    <a  href="#"
        data-controller="counter"
        data-action="click->counter#increment"
    >Increment <%= @count %></a>
</body>
```
{% endcode %}

Here, we rely on the standard Stimulus `data-controller` and `data-action` attributes. There's no StimulusReflex-specific markup required.

{% code title="frontend/src/js/controllers/counter\_controller.js" %}
```javascript
import { Controller } from 'stimulus';
import StimulusReflex from 'stimulus_reflex';

export default class extends Controller {
  connect() {
    StimulusReflex.register(this)
  }

  increment(event) {
    event.preventDefault()
    this.stimulate('CounterReflex#increment', 1)
  }
}
```
{% endcode %}

This controller needs to be registered together with the StimulusReflex application.

{% code title="frontend/src/js/index.js %}
```javascript
import { Application } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'
import WebsocketConsumer from 'sockpuppet-js'
import CounterController from './controller/counter_controller.js'

const application = Application.start()
const consumer = new WebsocketConsumer('ws://localhost:8000/sockpuppet-sync')

application.register('counter', CounterContreller)
StimulusReflex.initialize(application, { consumer })
```
{% endcode %}

The Controller connects during the page load process and we tell StimulusReflex that this Controller is going to be calling server-side Reflex actions. The `register` method has an optional 2nd argument that accepts options, but we'll cover that later.

When the user clicks the anchor, Stimulus calls the `increment` method. All StimulusReflex Controllers have access to the `stimulate` method. The first parameter is the `[ServerSideClass]#[action]` syntax, which tells the server which Reflex class and method to call. The second parameter is an optional argument which is passed to the Reflex method. If you need to pass multiple arguments, consider using a JavaScript object `{}` to do so.

{% hint style="warning" %}
If you're responding to an event like click on an element that would have a default action \(such as an `a` or a `button` element\) it's very important that you call preventDefault\(\) on that event, or else you will experience undesirable side effects such as page navigation.
{% endhint %}

{% code title="your_app/reflexes/counter\_reflex.py" %}
```ruby
class CounterReflex < StimulusReflex::Reflex
  def increment(step = 1)
    session[:count] = session[:count].to_i + step
  end
end
```

```python
from sockpuppet.reflex import Reflex

class CounterReflex(Reflex):
    def increment(self, step = 1):
        self.session['count'] = self.session['count'] + step

```
{% endcode %}

Here, you can see how we accept an optional `step` argument to our `increment` Reflex action. We're also now switching to using the Rails session object to persist our values across multiple page load operations.

{% code title="your_app/views.py.py" %}
```python
from django.views.generic.base import TemplateView

class CountView(TemplateView):
    template_name = 'index.html'

    def get_context_data(self, *args, **kwargs):
        context = super().get_context_data(*args, **kwargs)
        context['count'] = self.request.session.get('count', 0)
        return context
```
{% endcode %}

Finally, we set the value of the `self.count` instance variable in the view. When the page is first loaded, there will be no session\[:count\] value and `self.count` will be 0.

{% hint style="info" %}
Instead of using sessions to persist data you could store the data in django models. To keep this example we use django sessions to store our counter value.
{% endhint %}
