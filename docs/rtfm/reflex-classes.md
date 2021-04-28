# Reflex Classes

Regardless of whether you use declared Reflexes in your HTML markup or call `stimulate()` directly from inside of a Stimulus controller, StimulusReflex maps your requests to Reflex classes on the server. These classes are found in `app/reflexes` and they inherit from `ApplicationReflex`.

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
end
```
{% endcode %}

Setting a declarative data-reflex="click-&gt;Example\#test" will call the `test` method in the Example Reflex class. We refer to Reflex class methods which get called from the client as "Reflex Action methods".

You can do anything you like in a Reflex action, including [retrieving data from Redis](persistence.md#the-rails-cache-store), ActiveRecord database updates, launching ActiveJobs and even initiating [CableReady broadcasts](cableready.md#order-of-operations).

{% hint style="success" %}
If you change the code in a Reflex class, you have to refresh your web browser to allow ActionCable to reconnect. This will reload the appropriate modules and allow you to see your changes.
{% endhint %}

You can get and set values on the `session` object, and if you're using the \(default\) Page Morph Reflexes, any instance variables that you set in your Reflex Action method will be available to the controller action before your page is re-rendered.

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
  def test
    @id = element.dataset["id"] # @id will be available inside your controller action if you're doing a Page Morph
  end
end
```
{% endcode %}

You will learn all about the `element` accessor in the [next section](reflex-classes.md#element).

{% hint style="warning" %}
Note that there's no correlation between the Reflex class or Reflex action and the page \(or its controller\) that you're on. Your `users#show` page can call `Example#increment`.
{% endhint %}

## ActionCable Connection Identifiers

It's very common to want to be able to access the `current_user` or equivalent accessor inside your Reflex actions. First, you'll need to make sure that your Connection is "identified" by your `current_user`. Since ActionCable is separate from the ActionController namespace, accessors need to be setup as part of your [authentication](authentication.md#current-user) process.

Your Connection can have multiple accessors defined. For example, it's common to implement a [hybrid](authentication.md#hybrid-anonymous-authenticated-connections) technique to use the visitor's `session_id` before they authenticate, and then switch over to `current_user`.

Once your connection is `identified_by :current_user`, you can delegate `current_user` to your ActionCable Connection:

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

If you plan to access `current_user` from all of your Reflex classes, delegate it your ApplicationReflex:

{% code title="app/reflexes/application\_reflex.rb" %}
```ruby
class ApplicationReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection
end
```
{% endcode %}

### Queries and associations are cached

When using `identified_by` accessors such as `current_user`, it's important to remember that any ActiveRecord queries or associations you access will be cached by default, **even across multiple Reflexes**.

The cache is cleared when the ActionCable Connection is re-established \(usually with a page refresh\) or you manually force the accessor to reload its associations:

```ruby
current_user.reload
```

You can also bust the cached value by running a different query, but Rails developers are used to thinking in terms of request/response cycles. They know controller actions are idempotent, and so it's reasonable to expect Reflex actions to also be idempotent. And they are... except for accessors on the Connection.

{% hint style="danger" %}
**Don't use `current_user` or other Connection identifiers in templates or partials that will be rendered in a Reflex.**

Instead, pass a `user` variable into the template using the `locals` hash [parameter](https://guides.rubyonrails.org/action_view_overview.html#render-without-partial-and-locals-options).
{% endhint %}

If you are expecting your data to change and it doesn't, you can lose an afternoon to debugging.

Likewise, if you keep this potential _gotcha_ in the back of your mind, it's entirely fair to see this association caching behavior as a performance boost. After all, it's one less query to run! 😅

## Building your Reflex action

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

## `element`

The `element` property contains all of the Stimulus controller's [DOM element attributes](https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes) as well as other properties like `tagName`, `checked` and `value`. In addition, `values` and the `dataset` property reference special collections as described below.

{% hint style="info" %}
**Most values are strings.** The only exceptions are `checked` and `selected` which are booleans.

Elements that support **multiple values** such as `<select multiple>` or a collection of checkboxes with the same `name` will emit an additional **`values` property.** In addition, the `value` property will contain a comma-separated string of the checked options.
{% endhint %}

Here's an example that outlines how you can interact with the `element` property and the `dataset` collection in your Reflex action. You can use the dot notation as well as string and symbol accessors.

{% code title="app/views/examples/show.html.erb" %}
```markup
<input type="checkbox" id="example" label="Example" checked
  data-reflex="change->Example#accessors" data-value="123" />
```
{% endcode %}

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
  def accessors

    element.id                  # => "example"
    element[:id]                # => "example"
    element["id"]               # => "example"
    
    element.value               # => "on" (checkbox is always "on", use checked)
    element.values              # => nil, or Array for multiple values

    element[:tag_name]          # => "CHECKBOX"
    element[:checked]           # => true
    element["checked"]          # => true
    element.checked             # => true
    element.label               # => "Example"

    element.data_reflex         # => "change->Example#accessors"
    element["data-reflex"]      # => "change->Example#accessors"
    element.dataset[:reflex]    # => "change->Example#accessors"
    element.dataset["reflex"]   # => "change->Example#accessors"

    element.dataset.value       # => "123"
    element.data_value          # => "123"
    element["data-value"]       # => "123"
    element.dataset[:value]     # => "123"
    element.dataset["value"]    # => "123"

  end
end
```
{% endcode %}

{% hint style="warning" %}
Remember, `id` and `data-id` are different attributes. `id` can be used as a CSS selector, and  it must be unique in your DOM. It does not show up in your `dataset` accessor. `data-id` cannot be used as a CSS selector, does not have to be unique in your DOM and is part of your `dataset`. Similar names, entirely different concepts and functions.

The same goes for other pairs, such as `value` and `data-value`. `value` has meaning to the browser and it's what gets processed in a form submission by Rails. `data-value` is just an arbitrary name that you made up, and it could have just as easily been `data-principle`.
{% endhint %}

{% hint style="success" %}
When StimulusReflex is rendering your template, an instance variable named **@stimulus\_reflex** is available to your Rails controller and set to true.

You can use this flag to create branching logic to control how the template might look different if it's a Reflex vs normal page refresh.
{% endhint %}

## Signed and unsigned Global ID accessors

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

## Reflex exceptions are rescuable

If you'd like to wire up 3rd-party exception handling services like Sentry or HoneyBadger to your Reflex classes, you can use `rescue_from` to respond to an errors raised.

```ruby
class MyTestReflex < ApplicationReflex
  rescue_from StandardError do |exception|
    ExceptionTrackingService.error(exception)
  end
  # ...
end
```

## Accessing `reflex_id`

Every Reflex starts as a client-side data structure that is assigned a unique UUIDv4 used to track it through its round-trip life-cycle. Most developers using StimulusReflex never have to think about these details. However, if you're building an application that is based on transactional concepts, it might be very useful to be able to track interactions based on the `reflex_id`.

```ruby
class ExampleReflex < ApplicationReflex
  def foo
    puts reflex_id
  end
end
```

