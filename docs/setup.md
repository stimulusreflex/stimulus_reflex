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

At this point, you can run the following command to get set up with some example files:

```bash
bundle exec rails stimulus_reflex:install
```

This command will generate:

1. `app/javascript/controllers/application_controller.js`
2. `app/javascript/controllers/example_controller.js`
3. `app/reflexes/application_reflex.rb`
4. `app/javascript/controllers/example_reflex.rb`

## Generators

```bash
bundle exec rails generate stimulus_reflex my_demo
```

This command will generate:

1. `app/javascript/controllers/application_controller.js` \(If the file does not already exist\)
2. `app/javascript/controllers/my_demo_controller.js`
3. `app/reflexes/application_reflex.rb` \(If the file does not already exist\)
4. `app/reflexes/my_demo_reflex.rb`

```bash
bundle exec rails generate stimulus_reflex:controller my_demo
```

This command will generate:

1. `app/javascript/controllers/application_controller.js` \(If the file does not already exist\)
2. `app/javascript/controllers/my_demo_controller.js`

```bash
bundle exec rails generate stimulus_reflex:reflex my_demo
```

This command will generate:

1. `app/reflexes/application_reflex.rb` \(If the file does not already exist\)
2. `app/reflexes/my_demo_reflex.rb`

