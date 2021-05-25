---
description: How to prepare your app to use StimulusReflex
---

# Setup

## The small print

* StimulusReflex requires Redis to be [installed and running](https://redis.io/topics/quickstart) on your development machine.
* **Cookie-based** [**session storage**](setup.md#session-storage) **is not currently supported by StimulusReflex.**
* StimulusReflex works out of the box with new and existing projects running Rails 6 or later. For Rails 5.2, see [here](setup.md#rails-5-2-support).
* StimulusReflex supports Stimulus v1.1 or v2. Examples will use the v2 syntax.
* We recommend Webpacker v5.4 or later, but suggest passing on v6 for now.
* Setting up [test](../appendices/testing.md#test-environment-setup) and [production](../appendices/deployment.md) environments are covered in their own sections.

## Command-Line Install

The [install task](https://github.com/stimulusreflex/stimulus_reflex/blob/master/lib/tasks/stimulus_reflex/install.rake) below will install both Stimulus and StimulusReflex. It will modify some configuration settings and [enable caching](https://app.gitbook.com/@stimulusreflex/s/stimulusreflex/~/drafts/-MaWBaQc4XjCMkXohIGk/v/pre-release/appendices/deployment#session-storage) in your development environment.

```ruby
bundle add stimulus_reflex
bundle exec rails stimulus_reflex:install
```

That's it! An example Reflex class and Stimulus controller will be created for you. 🎉

{% page-ref page="quickstart.md" %}

## Manual Configuration

Some developers will need more control than a one-size-fits-all install task, so we're going to step through what's actually required to get up and running with StimulusReflex in the _development_ environment.

We'll install the StimulusReflex gem and client library before enabling caching in your development environment. Make sure we have [Stimulus ](https://stimulusjs.org)installed as part of our project's Webpack configuration.

```ruby
bundle add stimulus_reflex --version "~> 3.5.0"
yarn add stimulus_reflex@3.5.0
rails dev:cache # caching needs to be enabled
bundle exec rails webpacker:install:stimulus
```

Modify your Stimulus configuration to import and initialize StimulusReflex, which will attempt to locate the existing ActionCable consumer.

{% tabs %}
{% tab title="app/javascript/controllers/index.js" %}
```javascript
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'
import StimulusReflex from 'stimulus_reflex'
import consumer from '../channels/consumer'
import controller from '../controllers/application_controller'

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/)
application.load(definitionsFromContext(context))
application.consumer = consumer
StimulusReflex.initialize(application, { controller, isolate: true })
StimulusReflex.debug = process.env.RAILS_ENV === 'development'
```
{% endtab %}
{% endtabs %}

{% hint style="danger" %}
The installation information presented by the [StimulusJS handbook](https://stimulus.hotwire.dev/handbook/installing#using-webpack) conflicts slightly with the Rails default webpacker Stimulus installation. The handbook demonstrates requiring your controllers inside of your `application.js` pack file, while webpacker creates an `index.js` in your `app/javascript/controllers` folder. StimulusReflex recommends that you are follow the Rails webpacker flow. Your application pack should ideally `import 'controllers'`.

If you require your controllers in both 'application.js `and` index.js\` it's likely that your controllers will load twice, causing all sorts of strange behavior.  
{% endhint %}

**Cookie-based session storage is not currently supported by StimulusReflex.**

Instead, we enable caching in the development environment so that we can assign our user session data to be managed by the cache store. We also want to set default URL options for partials to render route helpers properly inside of Reflexes.

{% code title="config/environments/development.rb" %}
```ruby
Rails.application.configure do
  config.session_store :cache_store
  config.action_controller.default_url_options = {host: "localhost", port: 3000}
  config.action_mailer.default_url_options = {host: "localhost", port: 3000}
end
```
{% endcode %}

Configure ActionCable to use the Redis adapter in development mode:

{% code title="config/cable.yml" %}
```yaml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: your_application_development
```
{% endcode %}

Finally, StimulusReflex provides several generators that you should run to complete your setup process. They will create initializers for both StimulusReflex and CableReady, enable `stream_from` support for CableReady and create the `application_controller.js` Stimulus controller and an example Reflex class.

```text
bundle exec rails generate stimulus_reflex:initializer
bundle exec rails generate cable_ready:initializer
bundle exec rails generate cable_ready:stream_from
bundle exec rails generate stimulus_reflex example
```

## Upgrading, package versions and sanity

In the future, should you ever upgrade your version of StimulusReflex, it's very important that you always make sure your gem version and npm package versions match.

Since mismatched versions are the first step on the path to hell, by default StimulusReflex won't allow the server to start if your versions are mismatched.

If you have special needs, you can override this setting in your initializer. `:warn` will emit the same text-based warning but not prevent the server process from starting. `:ignore` will silence all mismatched version warnings, if you really just DGAF. ¯\\_\(ツ\)\_/¯

StimulusReflex can also let you know when new stable versions are released during the application start-up process. This opt-in behaviour is `:ignore` by default, but you can set it to `:warn` or `:exit`.

{% code title="config/initializers/stimulus\_reflex.rb" %}
```ruby
StimulusReflex.configure do |config|
  config.on_failed_sanity_checks = :warn
  config.on_new_version_available = :warn
end
```
{% endcode %}

### Upgrading to v3.5.0

* make sure that you update `stimulus_reflex` in **both** your Gemfile and package.json
* enable [isolation mode](../rtfm/reflexes.md#tab-isolation) by adding `isolate: true` to the initialize options
* generate an initializer with `rails g stimulus_reflex:initializer` if required

## Authentication

{% hint style="info" %}
If you're just experimenting with StimulusReflex or trying to bootstrap a proof-of-concept application on your local workstation, you can actually skip this section until you're planning to deploy.
{% endhint %}

Out of the box, ActionCable doesn't give StimulusReflex the ability to distinguish between multiple concurrent users looking at the same page.

**If you deploy to a host with more than one person accessing your app, you'll find that you're sharing a session and seeing other people's updates**. That isn't what most developers have in mind!

When the time comes, it's easy to configure your application to support authenticating users by their Rails session or current\_user scope. Just check out the Authentication page and choose your own adventure.

{% page-ref page="../rtfm/authentication.md" %}

## Tab isolation

One of the most universally surprising aspects of real-time UI updates is that by default, Morph operations intended for the current user execute in all of the current user's open tabs. Since the early days of StimulusReflex, this behavior has shifted from being an interesting edge case curiosity to something many developers need to prevent. Meanwhile, others built applications that rely on it.

The solution has arrived in the form of **isolation mode**.

When engaged, isolation mode restricts Morph operations to the active tab. While technically not enabled by default, we believe that most developers will want this behavior, so the StimulusReflex installation task will prepare new applications with isolation mode enabled. Any existing applications can turn it on by passing `isolate: true`:

{% code title="app/javascript/controllers/index.js" %}
```javascript
StimulusReflex.initialize(application, { consumer, controller, isolate: true })
```
{% endcode %}

If isolation mode is not enabled, Reflexes initiated in one tab will also be executed in all other tabs, as you will see if you have client-side logging enabled.

{% hint style="info" %}
Keep in mind that tab isolation mode only applies when multiple tabs are open to the same URL. If your tabs are open to different URLs, Reflexes will not carry over even if isolation mode is disabled.
{% endhint %}

## Session Storage

We are strong believers in the Rails Doctrine and work very hard to prioritize convention over configuration. Unfortunately, there are some inherent limitations to the way cookies are communicated via websockets that make it difficult to use cookies for session storage in production.

We default to using the `:cache_store` for `config.session_store` \(and enabling caching\) in the development environment if no other option has been declared.

Most developers switch to using `:redis_cache_store` for the cache store. The [redis-session-store gem](https://github.com/roidrage/redis-session-store) is a popular choice for the session store, especially in production.

Learn about configuring Redis for cache and session storage on the [Deployment](../appendices/deployment.md#use-redis-as-your-cache-store) page.

## Rack middleware support

While StimulusReflex is optimized for speed, some developers might be using Rack middleware that rewrites the URL, which could cause problems for Page Morphs.

You can add any middleware you need in your initializer:

{% code title="config/initializers/stimulus\_reflex.rb" %}
```ruby
StimulusReflex.configure do |config|
  config.middleware.use FirstRackMiddleware
  config.middleware.use SecondRackMiddleware
end
```
{% endcode %}

{% hint style="info" %}
Users of [Jumpstart Pro](https://jumpstartrails.com/) are advised to add the `Jumpstart::AccountMiddleware` middleware if they are doing path-based multitenancy.
{% endhint %}

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

If you're having trouble with converting your Rails 5.2 app to work correctly with webpacker, you should check out "[Rails 5.2, revisited](../appendices/troubleshooting.md#rails-5-2-revisited)" on the Troubleshooting page.
{% endhint %}

## Polyfills for IE11

If you need to provide support for older browsers, you can `yarn add @stimulus_reflex/polyfills` and include them **before** your Stimulus controllers:

{% code title="app/javascript/packs/application.js" %}
```javascript
// other stuff
import '@stimulus_reflex/polyfills'
import 'controllers'
```
{% endcode %}

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
gem "stimulus_reflex", github: "hopsoft/stimulus_reflex", branch: "master"
```
{% endcode %}

Restart your server\(s\) and refresh your page to see the latest.

{% hint style="success" %}
It is really important to **always make sure that your Ruby and JavaScript package versions are the same**!
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

