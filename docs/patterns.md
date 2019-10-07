# Useful Patterns

In the course of creating StimulusReflex and using it to build production applications, we have discovered several useful tricks. While it may be tempting to add features to the core library, every idea that we include creates bloat and comes with the risk of stepping on someone's toes because we didn't anticipate all of the ways it could be used.

That said, if you're building applications with StimulusReflex, you're going to want to bookmark this page. If you discover useful patterns not documented here, please open an issue or submit a pull request.

## Client Side

### Application Controller

You can make use of JavaScript's class inheritance to set up an "Application Controller" that will serve as the foundation for all of your StimulusReflex controllers to build upon. This not only reduces boilerplate, but it's also a convenient way to set up lifecycle callback methods for your entire application.

{% code-tabs %}
{% code-tabs-item title="application\_controller.js" %}
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
{% endcode-tabs-item %}
{% endcode-tabs %}

Then, all that's required to create a StimulusReflex controller is inherit from ApplicationController:

{% code-tabs %}
{% code-tabs-item title="custom\_controller.js" %}
```javascript
import ApplicationController from './application_controller'

export default class extends ApplicationController {
  sayHi () {
    super()
    console.log('Hello from a Custom controller')
  }
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

If you need to override any methods on your ApplicationController, you can redefine them. Optionally call `super(...Array.from(arguments))` to invoke the method on the parent super class.

### Benchmarking your Reflex actions

You might want to see how long your Reflex actions are taking to complete a round-trip, and without Ajax calls to monitor getting reliable metrics requires new approaches.

We suggest making use of the `beforeReflex` and `afterReflex` lifecycle callback methods to sample your performance. As a rule of thumb, anything below 200-300ms will be perceived as "**native**" by your users.

You can add this code to your desired Reflex controller. If you're making use of the Application Controller pattern described above, all of your Reflexes will log their round-trip execution times.

{% code-tabs %}
{% code-tabs-item title="application\_controller.js" %}
```javascript
  beforeReflex () {
    this.benchmark = performance.now()
  }

  afterReflex (element, reflex) {
    console.log(reflex, `${(performance.now() - this.benchmark).toFixed(0)}ms`)
  }
```
{% endcode-tabs-item %}
{% endcode-tabs %}

### Spinners for long-running actions

You can use `beforeReflex` and `afterReflex` to create UI "spinners" for anything that might take more than a heartbeat to complete. In addition to providing helpful visual feedback, research has demonstrated that acknowledging a slight delay will result in the user **perceiving** the delay as being shorter than they would if you did not acknowledge the delay. This is likely because we've been trained by good UI design to understand that this convention means we're waiting on the system. A sluggish UI otherwise forces people to wonder if they have done something wrong, and you don't want that.

{% code-tabs %}
{% code-tabs-item title="application\_controller.js" %}
```javascript
  beforeReflex () {
    document.body.classList.add('wait')
  }

  afterReflex () {
    document.body.classList.remove('wait')
  }
```
{% endcode-tabs-item %}

{% code-tabs-item title="application.css" %}
```css
body.wait, body.wait * {
  cursor: wait !important;
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

### Autofocus text boxes

If you are working with input elements in your application, you will quickly realize an unfortunate quirk of web browsers is that the `autofocus` attribute is only processed on the initial page load. If you want to implement a "click to edit" UI, you need to use a lifecycle callback method to make sure that the focus lands in the right place.

Handling this problem for every action would be extremely tedious. Luckily we can make use of the `afterReflex` callback to inspect the element to see if it has the `autofocus` attribute and, if so, correctly set the focus on that element.

{% code-tabs %}
{% code-tabs-item title="application\_controller.js" %}
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
{% endcode-tabs-item %}
{% endcode-tabs %}

{% hint style="success" %}
Note that to obtain our `focusElement`, we looked for a single instance of `autofocus` on an element that is a child of our controller. We used `this.element` where `this` is a reference to the Stimulus controller.

If we wanted to only check the element that triggered the Reflex action, we would modify our `afterReflex ()` to `afterReflex (element)` and then call `element.querySelector` - or just check the attributes directly.

If we wanted to check the whole page for an `autofocus` element, we can just do `document.querySelector('[autofocus]')` as usual. The square-bracket notation just tells your browser to look for an attribute called `autofocus`, regardless of whether it has a value or not.
{% endhint %}

## Server Side

### Chained Reflexes for long-running actions

Ideally, you want your Reflex action methods to be as fast as possible. Otherwise, no amount of client-side magic will cover for the fact that your app feels slow. If your round-trip click-to-redraw time is taking more than 300ms, people will describe the experience as sluggish. We can optimize our queries, make use of Russian Doll caching, and employ many other performance tricks in the app... but what if we rely on external, 3rd party services? Some tasks just take time, and for those situations, we **wait for it**:

{% code-tabs %}
{% code-tabs-item title="example\_reflex.rb" %}
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
{% endcode-tabs-item %}
{% endcode-tabs %}

This is code that you can insert into the bottom of your Reflex classes. It might look a bit arcane, but **it allows our Reflex action methods to call other Reflex actions after their work is complete**.

Let's explore this with a contrived example. When the page first loads, we see a button. If you click the button, it hides the button and displays a "Waiting" message while the server calls a slow API. When the API call comes back, it updates the page with the result.

{% code-tabs %}
{% code-tabs-item title="index.html.erb" %}
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
{% endcode-tabs-item %}
{% endcode-tabs %}

As you can see, we're following all of the proper StimulusReflex naming conventions; we have defined a simple component that has an `example` Stimulus controller defined. The button declares that it will call the `api` Reflex action of our `ExampleReflex` class on the server.

Since there is no `@api_status` instance variable during the initial page load, the case statement defaults to the `else` case which is our initial view state. Unfortunately, this might look visually confusing at first.

{% hint style="success" %}
If you really want to ditch the `else` you can define an initial state in your Rails controller:

{% code-tabs %}
{% code-tabs-item title="example\_controller.rb" %}
```ruby
  def index
    @api_status ||= :default
  end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

Now, you can refactor your view template like this:

{% code-tabs %}
{% code-tabs-item title="index.html.erb" %}
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
{% endcode-tabs-item %}
{% endcode-tabs %}

We've got your back.
{% endhint %}

Now, let's revisit our `ExampleReflex` class. When the user clicks the button, it calls our `api` action. The `@api_status` is set to `:loading` and `wait_for_it` gets called specifying the `success` action as the callback. Since `wait_for_it` operates asyncronously in its own thread, the action immediately sends the template back to the client to notify them that a slow process has started.

{% code-tabs %}
{% code-tabs-item title="example\_reflex.rb" %}
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
    return unless self.respond_to? target
    if block_given?
      Thread.new do
        channel.receive({
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
{% endcode-tabs-item %}
{% endcode-tabs %}

As you can see, we're only pretending to call an API for this example. **Do not call `sleep` in a production Ruby web application**. `sleep` tells your web server to stop dreaming of new possibilities. **However**, assuming that you're the only person on your **development** machine, you'll see that after three seconds, a second Reflex action is triggered and delivered to the browser over the websocket connection.

{% hint style="success" %}
This is one of the coolest things about websockets; you can respond many times to a single request, or not at all. It's an entirely different mental model than Ajax and HTTP.
{% endhint %}

### Coming Soon: Notifications with ActiveJob / Sidekiq

