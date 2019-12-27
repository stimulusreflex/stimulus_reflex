---
description: How to build a great StimulusReflex application
---

# Useful Patterns

In the course of creating StimulusReflex and using it to build production applications, we have discovered several useful tricks. While it may be tempting to add features to the core library, every idea that we include creates bloat and comes with the risk of stepping on someone's toes because we didn't anticipate all of the ways it could be used.

That said, if you're building applications with StimulusReflex, you're going to want to bookmark this page. If you discover useful patterns not documented here, please open an issue or submit a pull request.

## Client Side

### Application Controller

You can make use of JavaScript's class inheritance to set up an "Application Controller" that will serve as the foundation for all of your StimulusReflex controllers to build upon. This not only reduces boilerplate, but it's also a convenient way to set up lifecycle callback methods for your entire application.

{% tabs %}
{% tab title="application\_controller.js" %}
```javascript
import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }

  sayHi () {
    console.log('Hello from the Application controller.')
  }
}
```
{% endtab %}
{% endtabs %}

Then, all that's required to create a StimulusReflex controller is inherit from ApplicationController:

{% tabs %}
{% tab title="custom\_controller.js" %}
```javascript
import ApplicationController from './application_controller'

export default class extends ApplicationController {
  sayHi () {
    super()
    console.log('Hello from a Custom controller')
  }
}
```
{% endtab %}
{% endtabs %}

If you need to override any methods on your ApplicationController, you can redefine them. Optionally call `super(...Array.from(arguments))` to invoke the method on the parent super class.

### Benchmarking your Reflex actions

You might want to see how long your Reflex actions are taking to complete a round-trip, and without Ajax calls to monitor getting reliable metrics requires new approaches.

We suggest making use of the `beforeReflex` and `afterReflex` lifecycle callback methods to sample your performance. As a rule of thumb, anything below 200-300ms will be perceived as "**native**" by your users.

You can add this code to your desired Reflex controller. If you're making use of the Application Controller pattern described above, all of your Reflexes will log their round-trip execution times.

{% tabs %}
{% tab title="application\_controller.js" %}
```javascript
  beforeReflex () {
    this.benchmark = performance.now()
  }

  afterReflex (element, reflex) {
    console.log(reflex, `${(performance.now() - this.benchmark).toFixed(0)}ms`)
  }
```
{% endtab %}
{% endtabs %}

### Spinners for long-running actions

You can use `beforeReflex` and `afterReflex` to create UI "spinners" for anything that might take more than a heartbeat to complete. In addition to providing helpful visual feedback, research has demonstrated that acknowledging a slight delay will result in the user **perceiving** the delay as being shorter than they would if you did not acknowledge the delay. This is likely because we've been trained by good UI design to understand that this convention means we're waiting on the system. A sluggish UI otherwise forces people to wonder if they have done something wrong, and you don't want that.

{% tabs %}
{% tab title="application\_controller.js" %}
```javascript
  beforeReflex () {
    document.body.classList.add('wait')
  }

  afterReflex () {
    document.body.classList.remove('wait')
  }
```
{% endtab %}

{% tab title="application.css" %}
```css
body.wait, body.wait * {
  cursor: wait !important;
}
```
{% endtab %}
{% endtabs %}

### Autofocus text boxes

If you are working with input elements in your application, you will quickly realize an unfortunate quirk of web browsers is that the `autofocus` attribute is only processed on the initial page load. If you want to implement a "click to edit" UI, you need to use a lifecycle callback method to make sure that the focus lands in the right place.

Handling this problem for every action would be extremely tedious. Luckily we can make use of the `afterReflex` callback to inspect the element to see if it has the `autofocus` attribute and, if so, correctly set the focus on that element.

{% tabs %}
{% tab title="application\_controller.js" %}
```javascript
  afterReflex () {
    const focusElement = this.element.querySelector('[autofocus]')
    if (focusElement) {
      focusElement.focus()

      // shenanigans to ensure that the cursor is placed at the end of the existing value
      const value = focusElement.value
      focusElement.value = ''
      focusElement.value = value
    }
  }
```
{% endtab %}
{% endtabs %}

{% hint style="success" %}
Note that to obtain our **focusElement**, we looked for a single instance of `autofocus` on an element that is a child of our controller. We used **this.element** where **this** is a reference to the Stimulus controller.

If we wanted to only check the element that triggered the Reflex action, we would modify our **afterReflex \(\)** to **afterReflex\(element\)** and then call **element.querySelector** - or just check the attributes directly.

If we wanted to check the whole page for an **autofocus** attribute, we can just use **document.querySelector\('\[autofocus\]'\)** as usual. The square-bracket notation just tells your browser to look for an attribute called **autofocus**, regardless of whether it has a value or not.
{% endhint %}

### Capture all DOM update events

Stimulus provides a really powerful event routing syntax that includes custom events, specifying multiple events and capturing events on **document** and **window**.

```markup
<div data-action="cable-ready:after-morph@document->chat#scroll">
```

By capturing the **cable-ready:after-morph** event, we can run code after every update from the server. In this example, the scroll method on our Chat controller is being called to scroll the content window to the bottom, displaying new messages.

### Access Stimulus controller instances

Stimulus doesn't provide an easy way to access a controller instance; you have to have access to your Stimulus application object, the element, the name of the controller and be willing to call an undocumented API.

```javascript
this.application.getControllerForElementAndIdentifier(document.getElementById('users'), 'users')
```

This is ugly, verbose and potentially impossible outside of another Stimulus controller. Wouldn't it be nice to access your controller's methods and local variables from a legacy jQuery component? Just add this line to the **initialize\(\)** method of your Stimulus controllers:

```javascript
this.element[this.identifier] = this
```

This creates a document-scoped variable with the same name as your controller \(or controllers!\) on the element itself, so you can now call **element.controllerName.method\(\)** without any Pilates required.

{% hint style="warning" %}
If your controller's identifier doesn't obey the rules of JavaScript variable naming conventions, you will need to specify a viable name for your instance.

For example, if your controller is named _list-item_ you might consider **this.element.listItem = this** for that controller**.**
{% endhint %}

## Server Side

### Chained Reflexes for long-running actions

Ideally, you want your Reflex action methods to be as fast as possible. Otherwise, no amount of client-side magic will cover for the fact that your app feels slow. If your round-trip click-to-redraw time is taking more than 300ms, people will describe the experience as sluggish. We can optimize our queries, make use of Russian Doll caching, and employ many other performance tricks in the app... but what if we rely on external, 3rd party services? Some tasks just take time, and for those situations, we **wait for it**:

{% tabs %}
{% tab title="example\_reflex.rb" %}
```ruby
  def wait_for_it(target)
    if block_given?
      Thread.new do
        @channel.receive({
          "target" => "#{self.class}##{target}",
          "args" => [yield],
          "url" => url,
          "attrs" => element.attributes.to_s,
          "selectors" => selectors,
        })
      end
    end
  end
```
{% endtab %}
{% endtabs %}

This is code that you can insert into the bottom of your Reflex classes. It might look a bit arcane, but **it allows our Reflex action methods to call other Reflex actions after their work is complete**.

Let's explore this with a contrived example. When the page first loads, we see a button. If you click the button, it hides the button and displays a "Waiting" message while the server calls a slow API. When the API call comes back, it updates the page with the result.

{% tabs %}
{% tab title="index.html.erb" %}
```text
<div data-controller="example">
  <% case @api_status %>
  <% when :loading %>
    <em>Waiting...</em>
  <% when :ready %>
    <strong>@api_response</strong>
  <% else %>
    <button data-reflex="click->ExampleReflex#api">Call API</button>
  <% end %>
</div>
```
{% endtab %}
{% endtabs %}

As you can see, we're following all of the proper StimulusReflex naming conventions; we have defined a simple component that has an `example` Stimulus controller defined. The button declares that it will call the `api` Reflex action of our `ExampleReflex` class on the server.

Since there is no `@api_status` instance variable during the initial page load, the case statement defaults to the `else` case which is our initial view state. Unfortunately, this might look visually confusing at first.

{% hint style="success" %}
If you really want to ditch the `else` you can define an initial state in your Rails controller:

```ruby
  def index
    @api_status ||= :default
  end
```

Now, you can refactor your view template like this:

```ruby
<div data-controller="example">
  <% case @api_status %>
  <% when :default %>
    <button data-reflex="click->ExampleReflex#api">Call API</button>
  <% when :loading %>
    <em>Waiting...</em>
  <% when :ready %>
    <strong>@api_response</strong>
  <% end %>
</div>
```

We've got your back.
{% endhint %}

Now, let's revisit our `ExampleReflex` class. When the user clicks the button, it calls our `api` action. The `@api_status` is set to `:loading` and `wait_for_it` gets called specifying the `success` action as the callback. Since `wait_for_it` operates asyncronously in its own thread, the action immediately sends the template back to the client to notify them that a slow process has started.

{% tabs %}
{% tab title="example\_reflex.rb" %}
```ruby
  def api
    @api_status = :loading
    wait_for_it(:success) do
      sleep 3 # DON'T EVER ACTUALLY DO THIS IRL
      "Worth the wait!"
    end
  end

  def success(response)
    @api_status = :ready
    @api_response = response
  end

  private

  def wait_for_it(target)
    return unless respond_to? target
    if block_given?
      Thread.new do
        channel.receive({
          "target" => "#{self.class}##{target}",
          "args" => [yield],
          "url" => url,
          "attrs" => element.attributes.to_h,
          "selectors" => selectors,
        })
      end
    end
  end
```
{% endtab %}
{% endtabs %}

As you can see, we're only pretending to call an API for this example. **Do not call `sleep` in a production Ruby web application**. `sleep` tells your web server to stop dreaming of new possibilities. **However**, assuming that you're the only person on your **development** machine, you'll see that after three seconds, a second Reflex action is triggered and delivered to the browser over the websocket connection.

{% hint style="success" %}
This is one of the coolest things about websockets; you can respond many times to a single request, or not at all. It's an entirely different mental model than Ajax and HTTP.
{% endhint %}

### Triggering custom events and forcing DOM updates

CableReady, one of StimulusReflex's dependencies, has [many handy methods](https://cableready.stimulusreflex.com/usage/dom-operations/event-dispatch) that you can call from controllers, ActionJob tasks and Reflex classes. One of those methods is dispatch\_event, which allows you to trigger any event in the client, including custom events and jQuery events.

In this example, we send out an event to everyone connected to ActionCable suggesting that update is required:

{% tabs %}
{% tab title="Ruby" %}
```ruby
class NotificationReflex < StimulusReflex::Reflex
  include CableReady::Broadcaster

  def force_update(id)
    cable_ready["StimulusReflex::Channel"].dispatch_event {
      name: "force:update",
      detail: {id: id},
    }
    cable_ready.broadcast
  end

  def reload
    # noop: this method exists so we can refresh the DOM
  end
end
```
{% endtab %}
{% endtabs %}

{% tabs %}
{% tab title="index.html.erb" %}
```markup
<div data-action="force:update@document->notification#reload">
  <button data-action="notification#forceUpdate">
</div>
```
{% endtab %}
{% endtabs %}

We use the Stimulus event mapper to call our controller's reload method whenever a force:update event is received:

{% tabs %}
{% tab title="notification\_controller.js" %}
```javascript
let lastId

export default class extends Controller {
  forceUpdate () {
    lastId = Math.random()
    this.stimulate("NotificationReflex#force_update", lastId)
  }
  
  reload (event) {
    const { id } = event.detail
    if (id === lastId) return
    this.stimulate("NotificationReflex#reload")
  }
}
```
{% endtab %}
{% endtabs %}

By passing a randomized number to the Reflex as an argument, we allow ourselves to return before triggering a reload if we were the ones that initiated the operation.

### Coming Soon: Notifications with ActiveJob / Sidekiq

