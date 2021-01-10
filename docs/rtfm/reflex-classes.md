# Reflex Classes

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

Every Reflex starts as a client-side data structure that is assigned a unique UUIDv4 used to track it through its round-trip life-cycle. Most developers using StimulusReflex never have to think about these details. However, if you're building an application that is based on transactional concepts, it might be very useful to be able to track interactions based on the `reflex_id`. 

```ruby
class ExampleReflex < ApplicationReflex
  def foo
    puts reflex_id
  end
end
```

