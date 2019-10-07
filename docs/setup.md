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

At this point your project isn't making use of StimulusReflex, but you are ready to roll.
