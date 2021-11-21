---
description: How to build a great StimulusReflex application
---

# Useful Patterns

In the course of creating StimulusReflex and using it to build production applications, we have discovered several useful tricks. While it may be tempting to add features to the core library, every idea that we include creates bloat and comes with the risk of stepping on someone's toes because we didn't anticipate all of the ways it could be used.

## Client Side

### Application controller pattern

You can make use of JavaScript's class inheritance to set up an Application controller that will serve as the foundation for all of your StimulusReflex controllers to build upon. This not only reduces boilerplate, but it's also a convenient way to set up life-cycle callback methods for your entire application.

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

You can then create a Reflex-enabled controller by extending ApplicationController:

{% tabs %}
{% tab title="custom\_controller.js" %}
```javascript
import ApplicationController from './application_controller'

export default class extends ApplicationController {
  sayHi () {
    super.sayHi()
    console.log('Hello from a Custom controller')
  }
}
```
{% endtab %}
{% endtabs %}

If you need to override any methods on your Application controller, you can redefine them. Optionally call `super.sayHi(...Array.from(arguments))` to invoke the method on the parent super class.

### Spinners for long-running actions

You can use `beforeReflex` and `afterReflex` to create UI spinners for anything that might take more than a heartbeat to complete. In addition to providing helpful visual feedback, research has demonstrated that acknowledging a slight delay will result in the user _perceiving_ the delay as being shorter than they would if you did not acknowledge the delay. This is likely because we've been trained by good UI design to understand that this convention means we're waiting on the system. A sluggish UI otherwise forces people to wonder if they have done something wrong, and you don't want that.

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

If you are working with input elements in your application, you will quickly realize an unfortunate quirk of web browsers is that the `autofocus` attribute is only processed on the initial page load. If you want to implement a "click to edit" UI, you need to use a life-cycle callback method to make sure that the focus lands in the right place.

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

### Offering visual feedback

We recommend [Velocity](https://github.com/julianshapiro/velocity/wiki) for light, tweening animations that alert the user to UI state changes.

You can see Velocity in action on the StimulusReflex Expo [Todos demo](https://expo.stimulusreflex.com/demos/todo).

### Capture all DOM update events

Stimulus provides a really powerful event routing syntax that includes custom events, specifying multiple events and capturing events on **document** and **window**.

```markup
<div data-action="cable-ready:after-morph@document->chat#scroll">
```

By capturing the **cable-ready:after-morph** event, we can run code after every update from the server. In this example, the scroll method on our Chat controller is being called to scroll the content window to the bottom, displaying new messages.

### Capture jQuery events with DOM event listeners

Don't hate jQuery: it was a life-saver 12 years ago, and many of its best ideas are now part of the JavaScript language. However, one of the uglier realities of jQuery in a contemporary context is that it has its own entirely proprietary system for managing events, and it's not compatible with the now-standard DOM events API.

Sometimes you still need to be able to interface with legacy components, but you don't want to have to write two event handling systems.

[jquery-events-to-dom-events](https://www.npmjs.com/package/jquery-events-to-dom-events) is an npm package that lets you easily access and respond to jQuery events.

### Access Stimulus controller instances

Stimulus doesn't provide an easy way to access a controller instance; you have to have access to your Stimulus application object, the element, the name of the controller and be willing to call an undocumented API.

```javascript
this.application.getControllerForElementAndIdentifier(document.getElementById('users'), 'users')
```

This is ugly, verbose and potentially impossible outside of another Stimulus controller. Wouldn't it be nice to access your controller's methods and local variables from a legacy jQuery component? Just add this line to the **initialize\(\)** method of your Stimulus controllers:

```javascript
this.element[this.identifier] = this
```

This creates a document-scoped variable with the same name as your controller \(or controllers!\) on the element itself, so you can now call **element.controllerName.method\(\)** without any Pilates required. You can read more about this technique [here](https://leastbad.com/stimulus-power-move).

{% hint style="warning" %}
If your controller's identifier doesn't obey the rules of JavaScript variable naming conventions, you will need to specify a viable name for your instance.

For example, if your controller is named _list-item_ you might consider **this.element.listItem = this** for that controller**.**
{% endhint %}

## Server Side

### Russian Doll caching

Caching is the secret to getting your application responding in 30-50ms after a database query. Some developers are intimidated by application-level caching, but you can ease into it.

You might be surprised how easy it can be to stash frequently accessed resources that are expensive to generate. This is known as a **fragment cache**. In this contrived example, the cached block will be expired and replaced if the current user or the todo is changed:

```ruby
<% todo = Todo.first %>
<% cache([current_user, todo]) do %>
  ... a whole lot of work here ...
<% end %>
```

Russian Doll caching is just stacking cache fragments inside each other, and then configuring your ActiveRecord model callbacks to expire any keys that they are cached in when updated by setting the `touch: true` option on your `belongs_to` associations.

```ruby
<% cache([current_user, "todo_list", @todos.map(&:id), @todos.maximum(:updated_at)]) do %>
  <ul>
    <% @todos.each do |todo| %>
      <% cache(todo) do %>
        <li class="todo"><%= todo.description %></li>
      <% end %>
    <% end %>
  </ul>
<% end %>
```

Nate Berkopec's excellent post "[The Complete Guide to Rails Caching](https://www.speedshop.co/2015/07/15/the-complete-guide-to-rails-caching.html)" is one of the best resources on the topic - and the source of the above examples. It's a half-hour incredibly well-spent.

### Delegate render

{% hint style="warning" %}
Since StimulusReflex v3.4, this is now done automatically. This section will be removed when the next major release arrives.
{% endhint %}

If you are planning to render a lot of partials or ViewComponents in your Reflex action methods, you can delegate the `render` keyword to `ApplicationController`.

{% code title="app/reflexes/application\_reflex.rb" %}
```ruby
class ApplicationReflex < StimulusReflex::Reflex
  delegate :render, to: ApplicationController
end
```
{% endcode %}

This means that you can now call `morph` with a more terse syntax:

```ruby
morph "#foo", render(partial: "path/to/foo")
```

### Speed up page morphs

Depending on what parts of your DOM are being morphed, it's possible that you don't need to render your layout template every time you run a Reflex. If your menus and sidebar are mostly static, you might want to experiment with constraining your update to just the template for the current action.

First, check to see if the current controller action is executing inside of a Reflex:

```ruby
if @stimulus_reflex
  render layout: false
end
```

Then make sure that you're setting a `data-reflex-root` attribute containing a CSS selector that points to same DOM element where your template begins:

```markup
<div id="pow" data-reflex-root="#pow" data-reflex="click->Biff#pow">Pow.</div>
```

Otherwise StimulusReflex will look for the `body` tag and not know what to do.

You can read more about scoping Page Morphs [here](morph-modes.md#scoping-page-morphs).

### Internationalization

If you're building an application for an international audience, you might want to your morphed partials to be aware of the current user's location. Set your `I18n.locale` using a helper that you can define in your `ApplicationReflex`.

{% code title="app/reflexes/application\_reflex.rb" %}
```ruby
class ApplicationReflex < StimulusReflex::Reflex
  def with_locale(&block)
    I18n.with_locale(session[:locale]) { yield }
  end
end
```
{% endcode %}

Now you can wrap your render calls in your new `with_locale` helper:

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
  def foo
    morph "#foo", with_locale { render(partial: "path/to/foo") }
  end
end
```
{% endcode %}

If you're working on translations and would like to have your `.yml` files automatically reload when the browser refreshes, we've got you covered:

{% code title="app/controllers/application\_controller.rb" %}
```ruby
class ApplicationController < ActionController::Base
  before_action -> { I18n.backend.reload! } if Rails.env.development?
end
```
{% endcode %}

### The Current pattern

Several years ago, DHH [introduced](https://www.youtube.com/watch?v=D7zUOtlpUPw) the [Current](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html) pattern to Rails 5.1. It's easy to work with Current objects inside of your Reflex classes using a `before_reflex` callback in your `ApplicationReflex`.

{% code title="app/reflexes/application\_reflex.rb" %}
```ruby
class ApplicationReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection

  before_reflex do
    Current.user = current_user
  end
end
```
{% endcode %}

The `Current.user` accessor is now available in your Reflex action methods.

{% code title="app/reflexes/user\_reflex.rb" %}
```ruby
class UserReflex < ApplicationReflex
  def follow
    user = User.find(element.dataset[:user_id])
    Current.user.follow(user)
    morph "#following", render(partial: "users/following", locals: {user: Current.user})
  end
end
```
{% endcode %}

You can also set the Current object in the `connect` method of your `Connection` module. You can see this approach in the `tenant` branch of the [stimulus\_reflex\_harness](https://github.com/leastbad/stimulus_reflex_harness/tree/tenant) app.

### Adding log tags

{% hint style="warning" %}
Since StimulusReflex v3.4, there is now a vastly superior path in the form of [StimulusReflex Logging](../appendices/troubleshooting.md#stimulusreflex-logging). This section will be removed when the next release arrives.
{% endhint %}

You can prepend the `id` of the current `User` on messages logged from your `Connection` module.

{% code title="app/channels/application\_cable/connection.rb" %}
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = env["warden"].user
      logger.add_tags "ActionCable: User #{current_user.id}"
    end

  end
end
```
{% endcode %}

### Generating ids with dom\_id

CableReady - which is included and available for use in your Reflex classes - exposes a variation of the [dom\_id helper found in Rails](https://apidock.com/rails/ActionView/RecordIdentifier/dom_id). It has the exact same function signature and behavior, with one subtle but important difference: it prepends a `#` character to the beginning of the generated id. Where the original function was intended for use in ActionView ERB templates, that `#` makes it perfect for use on the server, where the `#` character is required to refer to a DOM element id attribute.

{% code title="app/reflexes/user\_reflex.rb" %}
```ruby
class UserReflex < ApplicationReflex
  def profile
    user = User.find(element.dataset[:user_id])
    morph dom_id(user), render(partial: "users/profile", locals: {user: user})
  end
end
```
{% endcode %}

### ViewComponentReflex

We're big fans of using [ViewComponents](https://github.com/github/view_component) in our template rendering process. The [view\_component\_reflex](https://github.com/joshleblanc/view_component_reflex) gem offers a simple mechanism for persistent state in your ViewComponents by automatically storing your component state in the Rails session.

Check out the [ViewComponentReflex Expo](http://view-component-reflex-expo.grep.sh/) for inspiration and examples.

### Rendering views inside of an ActiveRecord model or ActiveJob class

If you plan to initiate a [CableReady](https://cableready.stimulusreflex.com/) broadcast inside of a model callback or job, you might find yourself trying to render templates and wondering why it seems to return nil.

The secret to an efficient and successful template render operation is to call the `render` method of the `ApplicationController` class.

```ruby
class Notification < ApplicationRecord
  include CableReady::Broadcaster
  after_save do
    html = ApplicationController.render(
      partial: "layouts/navbar/notification",
      locals: { notification: self }
    )
    cable_ready["notification_feed:#{self.recipient.id}"].insert_adjacent_html(
      selector: "#notification_dropdown",
      position: "afterbegin",
      html: html
    ).broadcast
  end
end
```

### Flash messages

One Rails mechanism that you might use less in a StimulusReflex application is the flash message object. Flash made a lot more sense in the era of submitting a CRUD form and seeing the result confirmed on the next page load. With StimulusReflex, the current state of the UI might be updated dozens of times in rapid succession and the flash message could be easily lost before it's read.

You'll want to experiment with other, more contemporary feedback mechanisms to provide field validations and event notification functionality. An example would be the Facebook notification widget, or a dedicated notification drop-down that is part of your site navigation.

Clever use of CableReady broadcasts when ActiveJobs complete or models update is likely to produce a cleaner reactive surface for status information.

With all of those caveats established, Flash isn't dead, yet! Nate Hopkins has [shared his pattern](https://gist.github.com/leastbad/48466c8f16cbd3bc6a192666629a6bf5) for working with Rails Flash in a StimulusReflex project.

You can access the `ActionDispatch::Flash::FlashHash` for the current request via the `flash` accessor inside of a Reflex action.

### Use `webpack-dev-server` to reload after Reflex changes

It can be a pain to remember to reload your page after you make changes to a Reflex. Luckily, if you're already running `bin/webpack-dev-server` while you are building your application, you can add folders in your app to the list of places that are being monitored.

{% code title="config/webpack/development.js" %}
```javascript
var path = require('path')
process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
environment.config.devServer.watchContentBase = true
environment.config.devServer.contentBase = [
  path.join(__dirname, '../../app/views'),
  path.join(__dirname, '../../app/helpers'),
  path.join(__dirname, '../../app/reflexes')
]

module.exports = environment.toWebpackConfig()
```
{% endcode %}

