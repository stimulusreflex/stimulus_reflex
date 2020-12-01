---
description: "Reflex classes are full of Reflex actions. Reflex actions are full of love. \U0001F3E9"
---

# Reflexes

What is a Reflex, really? Is it a transactional UI update that takes place over a persistent open connection to the server? Is it a new tool on your belt that operates adjacent to and in tandem with concepts like REST and Ajax? Is it the smug feelings associated with successfully achieving a massive productivity arbitrage? Is it the boundless potential for unironic good in every child?

A thousand times, _yes_.

## There are three kinds of Reflex...

StimulusReflex features three distinct modes of operation, and you can use all three of them together in your application:

* Page Morph, which is the default, performs a full-page update
* Selector Morph is for replacing the content of an element
* Nothing Morph, for executing functions that don't update your page

Every Reflex starts off life as a Page Morph. You can change it to a different kind of Morph inside of your Reflex action; there's no way to set a Morph type on the client.

You can learn more about the control flow of each Morph by consulting [this flowchart](https://app.lucidchart.com/documents/view/e83d2cac-d2b1-4a05-8a2f-d55ea5e40bc9/0_0).

The rest of this page generally assumes that you're working with a Page Morph. Selector and Nothing Morphs are described in detail on their own page:

{% page-ref page="morph-modes.md" %}

## Declaring a Reflex in HTML with data attributes

The fastest way to enable Reflex actions by using the `data-reflex` attribute. The syntax follows Stimulus format: `[DOM-event]->[ReflexClass]#[action]`

```markup
<button data-reflex="click->Comment#create">Create</button>
```

You can use additional data attributes to pass variables as part of your Reflex payload.

```markup
<button 
  data-reflex="click->Comment#create" 
  data-post-id="<%= @post.id %>"
>Create</button>
```

It's a recommended **best practice** to put an `id` attribute on any element that has a `data-reflex` attribute on it. `id` is unique in a valid DOM, and  this is how StimulusReflex locates the controller which called the Reflex after a morph operation.

If you have multiple identical elements calling Reflex actions, no lifecycle mechanisms \(afterReflex callbacks, success events etc\) will be run.

{% hint style="info" %}
Thanks to the magic of [MutationObserver](https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver), a browser feature that allows StimulusReflex to know when the DOM has changed, StimulusReflex can pick up `data-reflex` attributes on all HTML elements - even if they are dynamically created and inserted into your DOM.

This means that if you parse a client-side markup format that has declarative Reflexes contained within, they will be connected to StimulusReflex in less than a millisecond.
{% endhint %}

### Declaring multiple Reflex events on an element

Do you want to trigger different Reflex actions for different events? We have you covered!

You can specify multiple Reflex operations by separating them with a space:

```markup
<img src="cat.jpg" data-reflex="mouseenter->Cat#approach mouseleave->Cat#escape">
```

{% hint style="warning" %}
There are two intentional limitations to this technique:

All Reflex actions must target the same controller. In the above example, it won't work properly if the `mouseleave` points to `Dog#escape` because, obviously, cats and dogs don't mix.

Also, you can only specify one action per event; this means `data-reflex="click->Cat#eat click->Cat#sleep"` will not work. In this example, the second action would be discarded.
{% endhint %}

### Inheriting data-attributes from parent elements

You might design your interface such that you have a deeply nested structure of data attributes on parent elements. Instead of writing code to travel your DOM and access those values, you can use the `data-reflex-dataset="combined"` directive to scoop all data attributes up the hierarchy and pass them as part of the Reflex payload.

```markup
<div data-post-id="<%= @post.id %>">
  <div data-category-id="<%= @category.id %>">
    <button data-reflex="click->Comment#create" data-reflex-dataset="combined">Create</button>
  </div>
</div>
```

This Reflex action will have `post-id` and `category-id` accessible:

```ruby
class CommentReflex < ApplicationReflex
  def create
    puts element.dataset["post-id"]
    puts element.dataset["category-id"]
  end
end
```

If a data attribute appears several times, the deepest one in the DOM tree is taken. In the following example, `data-id` would be **2**.

```markup
<div data-id="1">
  <button data-id="2" data-reflex="Example#whatever" data-reflex-dataset="combined">Click me</button>
</div>
```

### Don't get confused

Placing a `data-reflex="click->Foo#action"` attribute on your element does **not** automatically add an instance of the Stimulus `foo` controller. In fact, you might not even `have` a `foo` controller in your application!

There doesn't need to be a `foo_controller.js` in order for you to call your `Foo` Reflex actions.

It _is_ common use both `data-reflex` and `data-controller` at the same time, allowing you to create a `foo` Stimulus controller which extends `ApplicationController` and allowes you to define Reflex callback event handlers. We'll cover how this works in the [Lifecycle](https://docs.stimulusreflex.com/lifecycle) section.

## Calling a Reflex in a Stimulus controller

Behind the scenes, when you use declarative Reflex calls via `data-reflex` attributes in your HTML, the `stimulate` method on your Stimulus controller is being called. We touched on this briefly in the **Quick Start** chapter; here are the details.

All Stimulus controllers that have had `StimulusReflex.register(this)` called in their `connect` method gain a `stimulate` method.

```javascript
this.stimulate(string target, [DOMElement element], [Object options], ...[JSONObject argument])
```

**target** \[required\] \(exception: see "Requesting a Refresh" below\): a string containing the server Reflex class and method, in the form "Example\#increment".

**element** \[optional\]: a reference to a DOM element which will provide both attributes and scoping selectors. Frequently pointed to `event.target` in JavaScript. **Defaults to the DOM element of the controller in scope**.

**options** \[optional\]: an optional object containing _at least one of_ **reflexId**_**,**_ **selectors, resolveLate, serializeForm** or **attrs**. Can be used to override the ID of a given Reflex or override the selector\(s\) to be used for Page or Selector morphs. Advanced users might wish to modify the attributes sent to the server for the current Reflex.

**argument** \[optional\]: a **splat** of JSON-compliant JavaScript datatypes - array, object, string, numeric or boolean - will be received by the Reflex action as ordered arguments.

### Receiving arguments

When calling `stimulate()` you have the option to send arguments to the Reflex action method. Options have to be JSON-serializable data types and are received in a predictable order. Objects that are passed as parameters are accessible using both symbol and string keys.

```ruby
class CatReflex < ApplicationReflex
  def adopt(opinions, legs = 4)
    puts opinions["gender"]
    puts opinions[:gender]
  end
end
```

{% hint style="warning" %}
**Note: the method signature has to match.** If the Reflex action is expecting two arguments and doesn't receive two arguments, it will raise an exception.
{% endhint %}

Note that you can only provide parameters to Reflex actions by calling the `stimulate` method with arguments; there is no equivalent for Reflexes declared with data attributes.

### Combined data attributes with `stimulate()`

`data-reflex-dataset="combined"` also works with the `stimulate()` function:

```markup
<div data-folder-id="<%= folder.id %>" data-controller="folders">
  <button data-action="click->folders#edit" data-reflex-dataset="combined">Edit</button>
</div>
```

By default, `stimulate` treats the DOM element that the controller is placed on as the **element** parameter. Instead, we use `event.target` to make the clicked button element be the source of the Reflex action. All combined data attributes will be picked up, and all callbacks and events will emit from the button.

```javascript
import ApplicationController from './application_controller.js'

export default class extends ApplicationController {
  edit(event) {
    this.stimulate("Folder#edit", event.target)
  }
}
```

### Aborting a Reflex

It is possible that you might want to abort a Reflex and prevent it from executing. For example, the user might not have appropriate permissions to complete an action, or perhaps some other side effect like missing data would cause an exception if the Reflex was allowed to continue.

We'll go into much deeper detail on lifecycle callbacks on the [Lifecycle](https://docs.stimulusreflex.com/lifecycle) page, but for now it is important to know that if there is a `before_reflex` method in your Reflex class, it will be executed before the Reflex action. **If you call `raise :abort` in the `before_reflex` method, the Reflex action will not execute.** Instead, the client will receive a `halted` event and execute the `reflexHalted` callback if it's defined.

{% hint style="warning" %}
Halted Reflexes do not execute afterReflex callbacks on the server or client.
{% endhint %}

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

## Reflex classes

Regardless of whether you use declared Reflexes in your HTML markup or call `stimulate()` directly from inside of a Stimulus controller, StimulusReflex maps your requests to Reflex classes on the server. These classes are found in `app/reflexes` and they inherit from `ApplicationReflex`.

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
end
```
{% endcode %}

Setting a declarative data-reflex="click-&gt;Example\#increment" will call the increment Reflex action in the Example Reflex class, before passing any instance variables along to your controller action and re-rendering your page. You can do anything you like in a Reflex action, including database updates, launching ActiveJobs and even initiating CableReady broadcasts.

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
  def increment
    @counter += 1 # @counter will be available inside your controller action if you're doing a Page Morph
  end
end
```
{% endcode %}

{% hint style="warning" %}
Note that there's no correlation between the Reflex class or Reflex action and the page \(or its controller\) that you're on. Your `users#show` page can call `Example#increment`.
{% endhint %}

It's very common to want to be able to access the `current_user` or equivalent accessor inside your Reflex actions. The best way to achieve this is to delegate it to the ActionCable connection.

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
  delegate :current_user, to: :connection

  def increment
    current_user.counter.increment!
  end
end
```
{% endcode %}

If you plan to access `current_user` from all of your Reflex classes, it is common to delegate once in your ApplicationReflex.

{% code title="app/reflexes/application\_reflex.rb" %}
```ruby
class ApplicationReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection
end
```
{% endcode %}

{% hint style="success" %}
If you change the code in a Reflex class, you have to refresh your web browser to allow ActionCable to reconnect. This will reload the appropriate modules and allow you to see your changes.
{% endhint %}

### Building your Reflex action

The following properties available to the developer inside Reflex actions:

* `connection` - the ActionCable connection
* `channel` - the ActionCable channel
* `request` - an `ActionDispatch::Request` proxy for the socket connection
* `session` - the `ActionDispatch::Session` store for the current visitor
* `flash` - the `ActionDispatch::Flash::FlashHash` for the current request
* `url` - the URL of the page that triggered the reflex
* `params` - an `ActionController::Parameters` of the closest form
* `element` - a Hash like object that represents the HTML element that triggered the reflex
* `reflex_id` - a UUIDv4 that uniquely identies each Reflex

{% hint style="danger" %}
`reflex` and `process` are reserved words inside Reflex classes. You cannot create Reflex actions with these names.
{% endhint %}

### `element`

The `element` property contains all of the Stimulus controller's [DOM element attributes](https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes) as well as other properties like `tagName`, `checked` and `value`. In addition, `values` and the `dataset` property reference special collections as described below.

{% hint style="info" %}
**Most values are strings.** The only exceptions are `checked` and `selected` which are booleans.

Elements that support **multiple values** such as `<select multiple>` or a collection of checkboxes with the same `name` will emit an additional **`values` property.** In addition, the `value` property will contain a comma-separated string of the checked options.
{% endhint %}

Here's an example that outlines how you can interact with the `element` property and the `dataset` collection in your Reflex action. You can use the dot notation as well as string and symbol accessors.

{% code title="app/views/examples/show.html.erb" %}
```markup
<checkbox id="example" label="Example" checked
  data-reflex="Example#work" data-value="123" />
```
{% endcode %}

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
  def work()

    element.id      # => the HTML element's id in dot notation
    element[:id]    # => the HTML element's id w/ symbol accessor
    element["id"]   # => the HTML element's id w/ string accessor

    element.dataset # => a Hash that represents the HTML element's dataset
    element.values  # => [] only for multiple values

    element["id"]                # => "example"
    element[:tag_name]           # => "CHECKBOX"
    element[:checked]            # => true
    element.label                # => "Example"

    element["data-reflex"]       # => "ExampleReflex#work"
    element.dataset[:reflex]     # => "ExampleReflex#work"

    element.value                # => "123"
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

### Signed and unsigned Global ID accessors

Rails has [a pair of cool features](https://github.com/rails/globalid) that allow developers to generate tokens from ActiveRecord models. These tokens can later be used to access those models, and in the case of signed Global IDs, obscure the model from prying eyes. They can even be set to expire after a period of time.

The `element` accessor on every Reflex has two dynamic accessors, `signed` and `unsigned` which automatically unpack Global IDs stored in data attributes and converts them to model instances.

```markup
<div data-reflex="click->Example#foo"
     data-public="<%= @foo.to_global_id.to_s %>"
     data-secure="<%= @foo.to_sgid.to_s %>"
>
```

While in reality, you'd never use both on the same object, you can now have StimulusReflex automatically convert these attributes into instances of the models they reference. This happens lazily, at the time you access the accessor:

```ruby
class ExampleReflex < ApplicationReflex
  def foo
    puts element.unsigned[:public] # returns Foo model instance
    puts element.signed[:secure] # returns Foo model instance
  end
end
```

While most developers default to using signed Global IDs, understand that the tradeoff is that signed tokens can be quite long, whereas unsigned tokens remain short.

### Reflex exceptions are rescuable

If you'd like to wire up 3rd-party exception handling services like Sentry or HoneyBadger to your Reflex classes, you can use `rescue_from` to respond to an errors raised.

```ruby
class MyTestReflex < ApplicationReflex
  rescue_from StandardError do |exception|
    ExceptionTrackingService.error(exception)
  end
  # ...
end
```

### Accessing `reflex_id`

Every Reflex starts as a client-side data structure that is assigned a unique UUIDv4 used to track it through its round-trip lifecycle. Most developers using StimulusReflex never have to think about these details. However, if you're building an application that is based on transactional concepts, it might be very useful to be able to track interactions based on the `reflex_id`. 

```ruby
class ExampleReflex < ApplicationReflex
  def foo
    puts reflex_id
  end
end
```

## Tab isolation

One of the most universally surprising aspects of real-time UI updates is that by default, Morph operations intended for the current user execute in all of the current user's open tabs. Since the early days of StimulusReflex, this behavior has shifted from being an interesting edge case curiosity to something many developers need to prevent. Meanwhile, others built applications that rely on it.

The solution has arrived in the form of **isolation mode**.

When engaged, isolation mode restricts Morph operations to the active tab. While technically not enabled by default, we believe that most developers will want this behavior, so the StimulusReflex installation task will prepare new applications with isolation mode enabled. Any existing applications can turn it on by passing `isolate: true` :

{% code title="app/javascript/controllers/index.js" %}
```javascript
StimulusReflex.initialize(application, { consumer, controller, isolate: true })
```
{% endcode %}

If isolation mode is not enabled, Reflexes initiated in one tab will also be executed in all other tabs, as you will see if you have client-side logging enabled.

{% hint style="info" %}
Keep in mind that tab isolation mode only applies when multiple tabs are open to the same URL. If your tabs are open to different URLs, Reflexes will not carry over even if isolation mode is disabled.
{% endhint %}

## StimulusReflex and CableReady

[CableReady](https://cableready.stimulusreflex.com/) is the primary dependency of StimulusReflex, and it actually pre-dates this library by a year. What is it, and why should you care enough to watch [this video](https://gorails.com/episodes/how-to-use-cable-ready?autoplay=1&ck_subscriber_id=646293602)?

| Library | Responsibility |
| :--- | :--- |
| StimulusReflex | Translates user actions into server-side events that change your data, then regenerating your page based on this new data **into an HTML string**. |
| CableReady | Takes the HTML string from StimulusReflex and sends it to the browser before using [morphdom](https://github.com/patrick-steele-idem/morphdom/) to update only the parts of your DOM that changed. |

⬆️ StimulusReflex is for **sending** commands. 📡  
⬇️ CableReady is for **receiving** updates. 👽

CableReady has 22 operations for changing every aspect of your page, and you can define your own. It can emit events, set cookies, make you breakfast and call your parents \(Twilio fees are not included.\)

{% embed url="https://www.youtube.com/watch?v=dPzv2qsj5L8" caption="" %}

StimulusReflex uses CableReady's `morph` for Page Morphs and some Selector Morphs, `inner_html` for Selector Morphs that don't use `morph` , and `dispatch_event` for Nothing Morphs, as well as aborted/halted Reflexes and sending errors that occur in a Reflex action.

The reason some Selector morphs are sent via `inner_html` is that the content you send to replace your existing DOM elements has to match up. If you replace an element with something completely different, `morph` just won't work. You can read all about this in the [Morphing Sanity Checklist](https://docs.stimulusreflex.com/troubleshooting#morphing-sanity-checklist).

### Using CableReady inside a Reflex action

It's common for developers to use CableReady inside a Reflex action for all sorts of things, especially initiating client-side events which can be picked up by Stimulus controllers. Another pattern is to use Nothing Morphs that call CableReady operations.

Inside of a Reflex class, `CableReady::Broadcaster` is already included, giving you access to the `dom_id` helper and a special version of the `cable_ready` method. If you call `cable_ready` in a Reflex action without specifying a stream or resource - in other words, **no brackets** - CableReady will piggyback on the StimulusReflex ActionCable channel.

This means **you can automatically target the current user**, and if you're _only_ ever targeting the current user, you don't need to set up a channel for CableReady at all.

```ruby
class ExampleReflex < ApplicationReflex
  def foo
    cable_ready.console_log(message: "Cable Ready rocks!").broadcast
    morph :nothing
  end
end
```

Of course, you're still free to call `cable_ready` with a different stream or resource, if you need your update to go to a wider audience.

### When to use a StimulusReflex `morph` vs. a CableReady operation

Since StimulusReflex uses CableReady's `morph` and `inner_html` operations, you might be wondering when or if to just use CableReady operations directly instead of calling StimulusReflex's `morph`.

The simple answer is that you should use StimulusReflex when you need life-cycle management; callbacks, events and promises. Reflexes have a transactional life-cycle, where each one is assigned a UUID and the client will have the opportunity to respond if something goes wrong.

CableReady operations raise their own events, but StimulusReflex won't know if they are successful or not. Any CableReady operations you broadcast in a Reflex will be executed immediately.

### Order of operations

You can control the order in which CableReady and StimulusReflex operations execute in the client through strategic use \(and non-use\) of `broadcast`.

1. CableReady operations that are `broadcast`ed
2. StimulusReflex `morph` operations
3. CableReady operations that haven't been `broadcast`ed

CableReady operations that have `broadcast` called on them well be immediately delivered to the client, while any CableReady operations queued in a Page or Selector Morph Reflex action that aren't broadcast by the end of the action will be broadcast along with the StimulusReflex-specific `morph` operations. The StimulusReflex operations execute first, followed by any remaining CableReady operations.

{% hint style="warning" %}
If you have CableReady operations that haven't been broadcasted followed by another set of operations that do get broadcasted... the former group of operations will go out with the latter. If you want some operations to be sent with the StimulusReflex operations, make sure that they occur after any calls to `broadcast`.
{% endhint %}

One clever example use of advanced CableReady+StimulusReflex operation ordering is `CableReady#push_state`. There are scenarios where you might want to update your page and then change the URL. If you attempt to change the URL of the page during the Reflex action, the StimulusReflex `morph` updates will be unsuccessful due to the URL changing. StimulusReflex won't execute if the page has changed since the beginning of the Reflex.

By calling `push_state` without actually calling `broadcast`, this ensures that the Reflex page updates can occur before `push_state` changes the URL.

### With great power...

It's important to plan your use of CableReady operations that manipulate the DOM, in terms of timing and eliminating side-effects.

CableReady operations that are broadcasted from a Reflex action will be processed by the client before the Reflex action finishes executing. This means that if you change the DOM in a Page Morph Reflex, it will appear as though your change didn't work when in reality, it was overwritten by the Reflex a few milliseconds later. For this reason, it's rare to see CableReady used in Page Morph Reflex actions. Instead, you should **send the HTML that you want to see**, the first time, so that there's no need to update anything. After all, you can always use client-side callbacks to embellish your UI after a Reflex completes.

The concern is different with a Selector Morph. As discussed above, it's fine to use CableReady operations alongside StimulusReflex `morph` method calls, especially to take advantage of functions not supported directly by StimulusReflex, such as CableReady's `insert_adjacent_html` .

However, you must take responsibility for ensuring that your CableReady operations do not erase, move, or otherwise disturb the DOM above the element which invoked the Reflex action. While StimulusReflex will do everything it can to locate the Stimulus controller attached to the Reflex, if the controller can't be located - or no longer exists - then the life-cycle callbacks will not execute.

This is because StimulusReflex needs to be able to locate the Stimulus controller which initiated the Reflex, and it expects it to be in the same place in your DOM hierarchy that it was when the Reflex started.

{% hint style="info" %}
Keeping your DOM hierarchy consistent through the lifetime of a Reflex is critically important when using StimulusReflex with isolation mode disabled.
{% endhint %}

### radiolabel

If you're making extensive use of StimulusReflex `morph` and CableReady operations, you might consider installing [radiolabel](https://github.com/leastbad/radiolabel). It's a powerful visual aid that allows you to see your CableReady operations happen.

## Glossary

* StimulusReflex: the name of this project, which has a JS client and a Ruby based server component that rides along on top of Rails' ActionCable websockets framework
* Stimulus: an incredibly simple yet powerful JS framework by the creators of Rails
* "a Reflex": used to describe the full, round-trip life-cycle of a StimulusReflex operation, from client to server and back again
* Reflex class: a Ruby class that inherits from `StimulusReflex::Reflex` and lives in your `app/reflexes` folder. This is where your Reflex actions are implemented
* Reflex action: a method in a Reflex class, called in response to activity in the browser. It has access to several special accessors containing all of the Reflex controller element's attributes
* Reflex controller: a Stimulus controller that imports the StimulusReflex client library. It has a `stimulate` method for triggering Reflexes and like all Stimulus controllers, it's aware of the element it is attached to - as well as any Stimulus [targets](https://stimulusjs.org/reference/targets) in its DOM hierarchy
* Reflex controller element: the DOM element upon which the `data-reflex` attribute is placed, which often has data attributes intended to be delivered to the server during a Reflex action
* Morphs: the three ways to use StimulusReflex are Page, Selector and Nothing morphs. Page morphs are the default, and covered extensively on this page. See the [Morphs](https://docs.stimulusreflex.com/morph-modes) page for more
* Operation: a CableReady concept, operations are "things CableReady can do" such as changing the DOM or updating an element. Multiple operations of different types can be queued together for later delivery by calling `broadcast`
* Broadcast: operations are batched up by CableReady until a `broadcast` method is invoked, which immediately delivers all queued operations to one or multiple connected clients

