---
description: How to prepare your app to use StimulusReflex
---

# Setup

StimulusReflex relies on [Stimulus](https://stimulusjs.org/), an excellent library by the creators of Rails. You can install Stimulus when you create your Rails project:

```bash
rails new myproject --webpack=stimulus
```

You can add Stimulus and StimulusReflex to your existing Rails 5.1+ project:

```bash
yarn add stimulus stimulus_reflex
```

## ActionCable

StimulusReflex leverages [Rails ActionCable](https://guides.rubyonrails.org/action_cable_overview.html). Understanding what Rails provides out of the box will help you get the most value from this library.

{% hint style="info" %}
The ActionCable defaults of `window.App` and `App.cable` are used if they exist. **A new socket connection will be established if these do not exist.**
{% endhint %}

## Configuration

{% code-tabs %}
{% code-tabs-item title="app/javascript/controllers/index.js" %}
```javascript
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'
import StimulusReflex from 'stimulus_reflex'

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/)
application.load(definitionsFromContext(context))
StimulusReflex.initialize(application)
```
{% endcode-tabs-item %}

{% code-tabs-item title="Gemfile" %}
```ruby
gem "stimulus_reflex"
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="Gemfile" %}
```ruby
gem "stimulus_reflex"
```
{% endcode-tabs-item %}
{% endcode-tabs %}

You should add the `action_cable_meta_tag`helper to your application template so that ActionCable can access important configuration settings:

{% code-tabs %}
{% code-tabs-item title="app/views/layouts/application.html.erb" %}
```markup
  <head>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= action_cable_meta_tag %>
  </head>
```
{% endcode-tabs-item %}
{% endcode-tabs %}

### Performance

ActionCable emits verbose log messages. Disabling ActionCable logs _may_ improve performance.

{% code-tabs %}
{% code-tabs-item title="config/initializers/action\_cable.rb" %}
```ruby
ActionCable.server.config.logger = Logger.new(nil)
```
{% endcode-tabs-item %}
{% endcode-tabs %}

### Rooms

You might find the need to restrict communication to a specific room. This can be accomplished in 2 ways.

1. Passing the room name as an option to `register`.

{% code-tabs %}
{% code-tabs-item title="app/javascript/controllers/example\_controller.js" %}
```javascript
export default class extends Controller {
  connect() {
    StimulusReflex.register(this, { room: 'ExampleRoom12345' });
  }
}
```
{% endcode-tabs-item %}
{% endcode-tabs %}

1. Setting the `data-room` attribute on the StimulusController element.

```markup
<a href="#"
   data-controller="example"
   data-reflex="click->ExampleReflex#do_stuff"
   data-room="12345">
```

{% hint style="danger" %}
**Setting room in the body with a data attribute can pose a security risk.** Consider assigning room when registering the Stimulus controller instead.
{% endhint %}

## Generators

At this point, you can run the following command to bootstrap your project with some example files:

```bash
bundle exec rails stimulus_reflex:install
```

This command will generate:

1. `app/javascript/controllers/application_controller.js`
2. `app/javascript/controllers/example_controller.js`
3. `app/reflexes/application_reflex.rb`
4. `app/javascript/controllers/example_reflex.rb`

You can also use StimulusReflex generators, which is like scaffolding for StimulusReflex.

```bash
bundle exec rails generate stimulus_reflex my_demo
```

This command will generate:

1. `app/javascript/controllers/application_controller.js` \(If the file does not already exist\)
2. `app/javascript/controllers/my_demo_controller.js`
3. `app/reflexes/application_reflex.rb` \(If the file does not already exist\)
4. `app/reflexes/my_demo_reflex.rb`

If you want just the client-side files:

```bash
bundle exec rails generate stimulus_reflex:controller my_demo
```

This command will generate:

1. `app/javascript/controllers/application_controller.js` \(If the file does not already exist\)
2. `app/javascript/controllers/my_demo_controller.js`

If you want just the server-side files:

```bash
bundle exec rails generate stimulus_reflex:reflex my_demo
```

This command will generate:

1. `app/reflexes/application_reflex.rb` \(If the file does not already exist\)
2. `app/reflexes/my_demo_reflex.rb`

