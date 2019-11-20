---
description: How to prepare your app to use StimulusReflex
---

# Setup

StimulusReflex relies on [Stimulus](https://stimulusjs.org/), an excellent library from the creators of Rails. You can easily install StimulusReflex to new and existing Rails projects.

```bash
rails new myproject --webpack=stimulus
cd myproject
bundle add stimulus_reflex
bundle exec rails stimulus_reflex:install
```

{% hint style="info" %}
The example above will ensure that both Stimulus and StimulusReflex are installed. It creates common files and an example to get you started. It also handles some of the configuration outlined below.
{% endhint %}

## Configuration

{% tabs %}
{% tab title="app/javascript/controllers/index.js" %}
```javascript
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'
import StimulusReflex from 'stimulus_reflex'

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/)
application.load(definitionsFromContext(context))
StimulusReflex.initialize(application)
```
{% endtab %}

{% tab title="Gemfile" %}
```ruby
gem "stimulus_reflex"
```
{% endtab %}
{% endtabs %}

{% code title="Gemfile" %}
```ruby
gem "stimulus_reflex"
```
{% endcode %}

You should add the `action_cable_meta_tag`helper to your application template so that ActionCable can access important configuration settings:

{% code title="app/views/layouts/application.html.erb" %}
```markup
  <head>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= action_cable_meta_tag %>
  </head>
```
{% endcode %}

### Disabling Logging

ActionCable emits verbose log messages. Disabling ActionCable logs _may_ improve performance.

{% code title="config/initializers/action\_cable.rb" %}
```ruby
ActionCable.server.config.logger = Logger.new(nil)
```
{% endcode %}

### Rooms

By default, everyone looking at a page will see the same Reflex updates. You can restrict updates  to one or several users by specifying a "room". This can be accomplished in one of two ways:

1. Passing the room name as an option to `register`, which defines a default room for every Reflex on your page.

{% code title="app/javascript/controllers/example\_controller.js" %}
```javascript
export default class extends Controller {
  connect() {
    StimulusReflex.register(this, { room: 'ExampleRoom12345' });
  }
}
```
{% endcode %}

2. Optionally, you can set the `data-room` attribute on individual StimulusController elements.

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

The StimulusReflex generator is like scaffolding for StimulusReflex.

```bash
bundle exec rails generate stimulus_reflex user
```

This will create, but not overwrite the following files:

1. `app/javascript/controllers/application_controller.js`
2. `app/javascript/controllers/user_controller.js`
3. `app/reflexes/application_reflex.rb`
4. `app/reflexes/user_reflex.rb`

{% hint style="info" %}
If _something_ goes wrong, it's often because of the **spring** gem. You can test this by temporarily setting the `DISABLE_SPRING=1` environment variable and restarting your server.

To remove **spring** forever, here is the process we recommend:

1. `pkill -f spring`
2. Edit your Gemfile and comment out **spring** and **spring-watcher-listen**
3. `bin/spring binstub –remove –all`
{% endhint %}

