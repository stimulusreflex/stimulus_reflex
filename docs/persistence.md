---
description: __noun__ firm or obstinate continuance in a course of action in spite of difficulty or opposition.
---

# Persistence

Planning the design of StimulusReflex user interfaces is simpler than what we're used to, whether that's submitting a form and loading the results or using a JavaScript SPA framework to communicate with an API. Since your applications won't have a client state, we estimate that 80% of the effort previously required is now behind you. It does, however, require some unlearning and the willingness to rethink how you approach persisting the state of your application. We recognize that this can be jarring at first and that even positive changes can feel like work.

The best way to start thinking about how interfaces are designed in a StimulusReflex world is to remember that when you access a URL in your browser, you are seeing the current state of your UI; there is no mounting process. Your request goes through the Rails router to Action Pack where your controller renders your view templates and sends them down the wire. At this stage, StimulusReflex is not yet involved. You can call ActiveRecord, access data from Redis or the Rails cache, and set instance variables that get picked up in your view. This is Rails in all it's server rendered glory.

Once the page is displayed in your browser, the magic begins. StimulusReflex opens an ActionCable (websockets) connection back to the server and keeps it open, waiting for events. It then scans your document for `data-reflex` attributes so that it can wire up those events to Stimulus controllers that are responsible for mapping events in your browser to methods in your Reflex classes on the server.

When Reflex method is called, it is able to access ActiveRecord, Redis, the session object and Rails cache. After the Reflex method is complete the Rails controller's action method is called and any instance variables set are passed on to the Rails controller's action method. In this way, it's similar to a `before_action` filter. However, this is also where people new to StimulusReflex could get confused. The order of operations can seem fuzzy.

This document is here to get you back on track.

## Instance Variables

One of the most common patterns in StimulusReflex is to pass instance variables from the Reflex method through the controller and into the view template. Ruby's `||=` "__or equals__" operator helps us manage this hand-off:

```Ruby example_reflex.rb
def updateValue
  @value = element[:value]
end
```

```Ruby example_controller.rb
def index
  @value ||= 0
end
```

```Text index.html.erb
<div data-controller="example">
  <input type="text" data-reflex="input->ExampleReflex#updateValue" data-reflex-permanent>
  <p>The value is: <%= @value %>.</p>
</div>
```

When you access the index page, the value will initially be set to 0. If the user changes the value of the text input, the value is updated to reflect whatever has been typed. This is possible because the `||=` will only set the instance variable to be 0 if there hasn't already been a value set in the Reflex method.

{% hint style="success" %}
It's good to remember that in Ruby, `nil.to_i` will return 0. This means that even without `||=` you can safely use `@value.to_i` in your view template, because it will default to 0 in the rendered output.
{% endhint %}

{% hint style="info" %}
StimulusReflex doesn't need to go through the Rails routing module. This means updates are processed much faster than requests that come from the browser.
{% endhint %}

Of course, instance variables are aptly named; they only exist for the duration of a single request, regardless of whether that request is initiated by the browser or StimulusReflex.

## The Rails session object

The `session` object will persist across multiple requests; indeed, you can open multiple browser tabs and they will all share the same `session.id` value on the server. (See for yourself: you can create a new session using Incognito Mode.)

We can update our earlier example to use the session object, and it will now persist across multiple browser tabs and refreshes:

```Ruby example_reflex.rb
def updateValue
  session[:value] = element[:value]
end
```

```Ruby example_controller.rb
def index
  session[:value] ||= 0
end
```

```Text index.html.erb
<div data-controller="example">
  <input type="text" data-reflex="input->ExampleReflex#updateValue" data-reflex-permanent>
  <p>The value is: <%= session[:value] %>.</p>
</div>
```

### The @stimulus_reflex instance variable

When StimulusReflex calls your Rails controller's action method, it passes any active instance variables along with a special variable called `@stimulus_reflex` which is set to `true`. **You can use this variable to create an if/else block in your controller that behaves differently depending on whether it's being called within the context of a Reflex update or not.**

```Ruby pinball_controller.rb
def index
  unless @stimulus_reflex
    session[:balls_left] = 3
  end
end
```

In this example, the user is given 3 new balls every time they refresh the page in their browser, effectively restarting the game. If the page state is updated via StimulusReflex, no new balls are allocated.

This also means that `session[:balls_left]` will be set to 3 before StimulusReflex methods are ever called. **The first time the controller action executes is your opportunity to set up the state that StimulusReflex will later modify.**

## The Rails cache store

One of the most under-appreciated modules in Rails is `ActiveSupport::Cache` which provides the underlying infrastructure for [Russian doll](https://guides.rubyonrails.org/caching_with_rails.html#russian-doll-caching) caching. Many people forget that it can be called directly and that it has [a solid offering of utility methods](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html) such as `increment` and `decrement` for numeric values.

The Rails cache provides a consistent interface to a key/value storage container that behind the scenes can be anything from an in-memory database or temporary files to Redis or Memcached hosted on a different machine.

You can access the Rails cache easily from anywhere in your application:

`Rails.cache.fetch("clicks:#{session.id}") {0}`

Behold the sexy: we're using the user's `session.id` to help us build a unique key string to look up the current value. The structure of the key is free-form, but the convention is to use colon characters to build up a namespace, terminating in a unique identifier; for example, `Rails.cache.fetch("preferences:colors:foreground:#{session.id}") {"blue"}`.

If no key exists, it will evaluate the block, set the value for that key and return the value in one convenient, atomic action. Bam!

If you're planning to do more than set an initial simple value for the fetch default, it's good idiomatic Ruby to move to the `do..end` form of block declaration:

```Text fortune.html.erb
<pre><%=
  Rails.cache.fetch("fortune") do
    `fortune | cowsay`
  end
%></pre>
```

{% hint style="success" %}
In order to use the Rails cache store in development, you have to run `rails dev:cache` on the command line once. Otherwise, if you look in `config/environments/development.rb` you'll see that your cache store will be `:null_store`, which is exactly as reliable as it sounds.
{% endhint %}

## ActiveRecord

The most common and powerful persistence mechanism you'll call from a Reflex method is also the most familiar.

An excellent reference example of StimulusReflex best practices is [todos_reflex.rb](https://github.com/hopsoft/stimulus_reflex_todomvc/blob/master/app/reflexes/todos_reflex.rb) from the [StimulusReflex TodoMVC](http://todomvc.stimulusreflex.com/) sample application.

The Reflex class makes use of the `session.id`, the `data-id` attributes from individual Todo model instances, and the new Rails `&` [safe naviation operator](http://mitrev.net/ruby/2015/11/13/the-operator-in-ruby/) (available since Ruby 2.3) to make short work of mapping events in the client to your permanent datastore.

For comparison, [todos_controller.rb](https://github.com/hopsoft/stimulus_reflex_todomvc/blob/master/app/controllers/todos_controller.rb) only makes the single ActiveRecord query to render the current state of the view template. Well-designed StimulusReflex applications leave the heavy-lifting associated with state changes to the Reflex class.

## Redis

You might already be using Redis, if Redis is your Rails cache store.

However, depending on your application and the kind of data you're working with, calling the Redis engine directly (through the `redis` gem, in tandem with the `hiredis` gem for best performance) from your Reflex methods allows you to work with the full suite of data structure manipulation tools that are available in response to the state change operations your users initiate.

Using Redis is beyond the scope of this document, but an excellent starting point is Jesus Castello's excellent "[How to Use the Redis Database in Ruby](https://www.rubyguides.com/2019/04/ruby-redis/)".

{% hint style="warning" %}
Just remember that while data in Redis could potentially be accessed faster than data in a traditional database engine such as Postgres, it is still ephemeral and you should act as though your data could __theoretically__ disappear at any time.

It is a common pattern to store the results of API calls or long-running database queries in Redis, with the assumption that you could reconstitute your Redis store from scratch later in an emergency.
{% endhint %}

{% hint style="success" %}
To get the best mileage from Redis, make sure that your key expiration strategy is set to **LRU**. Least-Recently Used keys means that as your database storage fills up, Redis will automatically evict the keys most likely to be stale or expired. This means that you never have to worry about setting expiry dates or manually expiring old keys.
{% endhint %}