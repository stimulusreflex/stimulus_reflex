---
description: How to prepare your app to use StimulusReflex
---

# Setup

## Command-Line Install

StimulusReflex relies on [Stimulus](https://stimulusjs.org/), an excellent library from the creators of Rails. You can easily install StimulusReflex to new and existing Rails 6 projects. For Rails 5.2, see [here](https://docs.stimulusreflex.com/setup#rails-5-2-support).

```bash
# For new projects
rails new myproject --webpack=stimulus
cd myproject

# For existing projects
bundle exec rails webpacker:install:stimulus

# For both project types
bundle add stimulus_reflex
bundle exec rails stimulus_reflex:install
```

The terminal commands above will ensure that both Stimulus and StimulusReflex are installed. It creates common files and an example to get you started. It also handles some of the configuration outlined below, including enabling caching in your development environment.

And that's it! **You can start using StimulusReflex in your application.**

{% page-ref page="quickstart.md" %}

{% hint style="danger" %}
Starting with v2.2.2 of StimulusReflex, support for the Rails default session storage mechanism `cookie_store` has been _temporarily_ dropped. The `stimulus_reflex:install` script will now set your session storage to be `:cache_store` in your development environment if no value has been set.
{% endhint %}

## Manual Configuration

Some developers will need more control than a one-size-fits-all install task, so we're going to step through what's actually required to get up and running with StimulusReflex in your Rails 6+ project. For Rails 5.2, see [here](https://docs.stimulusreflex.com/setup#rails-5-2-support).

First, the easy stuff: let's make sure we have [Stimulus ](https://stimulusjs.org)installed as part of our project's Webpack configuration. We'll also install the StimulusReflex gem and client library before enabling caching in your development environment.

```ruby
bundle exec rails webpacker:install:stimulus
bundle add stimulus_reflex
yarn add stimulus_reflex
rails dev:cache
```

We need to modify our Stimulus configuration to import and initialize StimulusReflex, which will attempt to locate the existing ActionCable consumer. A new websocket connection is created if the consumer isn't found.

{% tabs %}
{% tab title="app/javascript/controllers/index.js" %}
```javascript
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'
import StimulusReflex from 'stimulus_reflex'
import consumer from '../channels/consumer'

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/)
application.load(definitionsFromContext(context))
StimulusReflex.initialize(application, { consumer })
```
{% endtab %}
{% endtabs %}

Cookie-based session management is not currently supported by StimulusReflex. We will set our session management to be managed by the cache store, which in Rails defaults to the memory store.

{% code title="config/environments/development.rb" %}
```ruby
Rails.application.configure do
  config.session_store :cache_store
  # ....
end
```
{% endcode %}

Configure ActionCable to use the Redis adapter in development mode. If you don't have Redis, you can [learn more on the Redis site](https://redis.io/topics/quickstart).

{% code title="config/cable.yml" %}
```yaml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: your_application_development
```
{% endcode %}

You should also add the `action_cable_meta_tag`helper to your application template so that ActionCable can access important configuration settings:

{% code title="app/views/layouts/application.html.erb" %}
```markup
  <head>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= action_cable_meta_tag %>
  </head>
```
{% endcode %}

## Authentication

{% hint style="info" %}
If you're just experimenting with StimulusReflex or trying to bootstrap a proof-of-concept application on your local workstation, you can actually skip this section until you're planning to deploy.
{% endhint %}

Out of the box, ActionCable doesn't give StimulusReflex the ability to distinguish between multiple concurrent users looking at the same page.

**If you deploy to a host with more than one person accessing your app, you'll find that you're sharing a session and seeing other people's updates**. That isn't what most developers have in mind!

When the time comes, it's easy to configure your application to support authenticating users by their Rails session or current\_user scope. Just check out the Authentication page and choose your own adventure.

{% page-ref page="authentication.md" %}

## Session Storage

We are strong believers in the Rails Doctrine and work very hard to prioritize convention over configuration. Unfortunately, there are some inherent limitations to the way cookies are communicated via websockets that make it difficult to use cookies for session storage in production. We've had to make the decision to _temporarily_ drop support for the Rails default cookie-based session store.

This puts us in the awkward position of forcing an infrastructure change for some users that has nuanced implications.

We decided to default to using the `:cache_store` for `config.session_store` \(and enabling caching\) in the development environment if no other option has been declared. If you set a different session store in an initializer, please make sure that we're not clobbering your preferred store with our good intentions. The Rails default cache store is `:memory_store` which will get the job done in development but is not suitable or appropriate for production.

You can learn more about session storage on the Deployment page.

{% page-ref page="deployment.md" %}

## Logging

StimulusReflex supports both client and server logging of Reflexes.

{% page-ref page="troubleshooting.md" %}

## ViewComponent Integration

There is no special process required for using [view\_component](https://github.com/github/view_component) with StimulusReflex. If ViewComponent is setup and running properly, you're already able to use them in your Reflex-enabled views.

Many StimulusReflex + ViewComponent developers are enjoying using the [view\_component\_reflex](https://github.com/joshleblanc/view_component_reflex) gem, which automatically persists component state to your session between Reflexes.

## Rails 5.2+ Support

To use Rails 5.2 with StimulusReflex, you'll need the latest Action Cable package from npm: `@rails/actioncable`

1. Replace `actioncable` with `@rails/actioncable` in `package.json`
   * `yarn remove actioncable`
   * `yarn add @rails/actioncable`
2. Replace any instance of `import Actioncable from "actioncable"` with `import { createConsumer } from "@rails/actioncable"`
   * This imports the `createConsumer` function directly
   * Previously, you might call `createConsumer()` on the `Actioncable` import: `Actioncable.createConsumer()`
   * Now, you can reference `createConsumer()` directly

{% hint style="info" %}
There's nothing about StimulusReflex 3+ that shouldn't work fine in a Rails 5.2 app if you're willing to do a bit of manual package dependency management.
{% endhint %}

## Running "Edge"

If you are interested in running the latest version of StimulusReflex, you can point to the `master` branch on Github:

{% code title="package.json" %}
```javascript
"dependencies": {
  "stimulus_reflex": "hopsoft/stimulus_reflex#master"
}
```
{% endcode %}

{% code title="Gemfile" %}
```ruby
gem "stimulus_reflex", github: "hopsoft/stimulus_reflex"
```
{% endcode %}

Restart your server\(s\) and refresh your page to see the latest.

{% hint style="success" %}
It is really important to **always make sure that your Ruby and Javascript package versions are the same**!
{% endhint %}

### Running a branch to test a Github Pull Request

Sometimes you want to test a new feature or bugfix before it is officially merged with the `master` branch. You can adapt the "Edge" instructions and run code from anywhere.

Using [\#335 - tab isolation mode v2](https://github.com/hopsoft/stimulus_reflex/pull/335) as an example, we first need the Github username of the author and the name of their local branch associated with the PR. In this case, the answers are `leastbad` and `isolation_optional`. This is a branch on the forked copy of the main project; a pull request is just a proposal to merge the changes in this branch into the `master` branch of the main project repository.

{% code title="package.json" %}
```javascript
"dependencies": {
  "stimulus_reflex": "leastbad/stimulus_reflex#isolation_optional"
}
```
{% endcode %}

{% code title="Gemfile" %}
```ruby
gem "stimulus_reflex", github: "leastbad/stimulus_reflex", branch: "isolation_optional"
```
{% endcode %}

Restart your server\(s\) and refresh your page to see the latest.

