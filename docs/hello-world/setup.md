---
description: How to prepare your app to use StimulusReflex
---

# Setup

## First: set up Webpacker

**StimulusReflex was designed with Webpacker in mind.** It's possible to configure it to work with asset pipeline/Sprockets, import maps, Vite Rails, ESBuild and probably several other tools which will be directly supported by StimulusReflex 3.5 **when it is released**.

_For now_, we recommend that you use the **webpacker 5.4.3** gem:

```ruby
gem "webpacker", "~> 5.4.3"
```

And set up your `package.json`:

```json
"dependencies": {
  "@rails/webpacker": "5.4.3",
},
"devDependencies": {
  "webpack-dev-server": "^3.11.2"
}
```

## Command-Line Install

StimulusReflex relies on [Stimulus](https://stimulusjs.org), an excellent library from the creators of Rails. You can easily install StimulusReflex to new and existing Rails 6+ projects. For Rails 5.2, see [here](setup.md#rails-5-2-support).

::: warning
StimulusReflex requires Redis to be [installed and running](https://redis.io/topics/quickstart).
:::

The terminal commands below will ensure that both Stimulus and StimulusReflex are installed. It creates common files and an example to get you started. It also handles some of the configuration outlined below, **including enabling caching in your development environment**. (You can read more about why we enable caching [here](../appendices/deployment.md#session-storage).)

```ruby
bundle add stimulus_reflex --version 3.5.0.pre8
rake stimulus_reflex:install
```

::: warning
There have been recent reports of a change in the Safari web browser that cause Action Cable connections to drop. You can find a hotfix to mitigate this issue [here](../appendices/troubleshooting.md#safari-nsurlsession-websocket-bug).
:::

And that's it! You can start using StimulusReflex in your application with the _development_ environment. You'll need to keep reading to set up [test](../appendices/testing.md#test-environment-setup) and [production](../appendices/deployment.md).

TODO [quickstart.md](quickstart.md)

## Manual Configuration

Some developers will need more control than a one-size-fits-all install task, so we're going to step through what's actually required to get up and running with StimulusReflex in your Rails 6+ project in the _development_ environment. You'll need to keep reading to set up [test](../appendices/testing.md#test-environment-setup) and [production](../appendices/deployment.md). For Rails 5.2, see [here](setup.md#rails-5-2-support).

::: warning
StimulusReflex requires Redis to be [installed and running](https://redis.io/topics/quickstart).

You can learn more about optimizing your Redis configuration, why we enable caching in development and why we don't currently support cookie sessions on the [Deployment](../appendices/deployment.md#session-storage) page.
:::

We'll install the StimulusReflex gem and client library before enabling caching in your development environment. Then Webpacker and Stimulus are installed. An initializer called `stimulus_reflex.rb` will be created with default values.

```ruby
bundle add stimulus_reflex --version 3.5.0.pre9
yarn add stimulus_reflex@3.5.0.pre9
rails dev:cache # caching needs to be enabled
rake webpacker:install:stimulus
rails generate stimulus_reflex:initializer
```

::: warning
StimulusReflex happily supports Stimulus versions 1.1, 2 and 3.
:::

We need to modify our Stimulus configuration to import and initialize StimulusReflex, which will attempt to locate the existing ActionCable consumer. A new websocket connection is created if the consumer isn't found.

::: code-group
```javascript [app/javascript/controllers/index.js]
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'
import StimulusReflex from 'stimulus_reflex'
import consumer from '../channels/consumer'

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/)
application.load(definitionsFromContext(context))
application.consumer = consumer
StimulusReflex.initialize(application, { isolate: true })
```
:::

::: warning
The installation information presented by the [StimulusJS handbook](https://stimulusjs.org/handbook/installing#using-webpack) conflicts slightly with the Rails default webpacker Stimulus installation. The handbook demonstrates requiring your controllers inside of your `application.js` pack file, while webpacker creates an `index.js` in your `app/javascript/controllers` folder. StimulusReflex assumes that you are following the Rails webpacker flow. Your application pack should simply `import 'controllers'`.

If you require your controllers in both 'application.js `and` index.js\` it's likely that your controllers will load twice, causing all sorts of strange behavior.
:::

**Cookie-based session storage is not currently supported by StimulusReflex.**

Instead, we enable caching in the development environment so that we can assign our user session data to be managed by the cache store.

In Rails, the default cache store is the memory store. We want to change the cache store to make use of Redis:

::: code-group
```ruby [config/environments/development.rb]
Rails.application.configure do
  # CHANGE the following line; it's :memory_store by default
  config.cache_store = :redis_cache_store, {url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }}

  # ADD the following line; it probably doesn't exist
  config.session_store :cache_store, key: "_sessions_development", compress: true, pool_size: 5, expire_after: 1.year
end
```
:::

You can read more about configuring Redis on the [Deployment](../appendices/deployment.md#session-storage) page.

Configure ActionCable to use the Redis adapter in development mode:

::: code-group
```yaml [config/cable.yml]
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: your_application_development
```
:::

You should also add the `action_cable_meta_tag`helper to your application template so that ActionCable can access important configuration settings:

::: code-group
```html [app/views/layouts/application.html.erb]
  <head>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= action_cable_meta_tag %>
  </head>
```
:::

::: warning
There have been recent reports of a change in the Safari web browser that cause Action Cable connections to drop. You can find a hotfix to mitigate this issue [here](../appendices/troubleshooting.md#safari-nsurlsession-websocket-bug).
:::

## Upgrading, package versions and sanity

In the future, should you ever upgrade your version of StimulusReflex, it's very important that you always make sure your gem version and npm package versions match.

Since mismatched versions are the first step on the path to hell, by default StimulusReflex won't allow the server to start if your versions are mismatched.

If you have special needs, you can override this setting in your initializer. `:warn` will emit the same text-based warning but not prevent the server process from starting. `:ignore` will silence all mismatched version warnings, if you really just DGAF. ¯\\_(ツ)\\_/¯

::: code-group
```ruby [config/initializers/stimulus_reflex.rb]
StimulusReflex.configure do |config|
  config.on_failed_sanity_checks = :warn
end
```
:::

## Authentication

::: warning
If you're just experimenting with StimulusReflex or trying to bootstrap a proof-of-concept application on your local workstation, you can actually skip this section until you're planning to deploy.
:::

Out of the box, ActionCable doesn't give StimulusReflex the ability to distinguish between multiple concurrent users looking at the same page.

**If you deploy to a host with more than one person accessing your app, you'll find that you're sharing a session and seeing other people's updates**. That isn't what most developers have in mind!

When the time comes, it's easy to configure your application to support authenticating users by their Rails session or current\_user scope. Just check out the Authentication page and choose your own adventure.

TODO [authentication.md](../guide/authentication.md)

## Tab isolation

One of the most universally surprising aspects of real-time UI updates is that by default, Morph operations intended for the current user execute in all of the current user's open tabs. Since the early days of StimulusReflex, this behavior has shifted from being an interesting edge case curiosity to something many developers need to prevent. Meanwhile, others built applications that rely on it.

The solution has arrived in the form of **isolation mode**.

When engaged, isolation mode restricts Morph operations to the active tab. While technically not enabled by default, we believe that most developers will want this behavior, so the StimulusReflex installation task will prepare new applications with isolation mode enabled. Any existing applications can turn it on by passing `isolate: true`:

::: code-group
```javascript [app/javascript/controllers/index.js]
StimulusReflex.initialize(application, { consumer, controller, isolate: true })
```
:::

If isolation mode is not enabled, Reflexes initiated in one tab will also be executed in all other tabs, as you will see if you have client-side logging enabled.

::: warning
Keep in mind that tab isolation mode only applies when multiple tabs are open to the same URL. If your tabs are open to different URLs, Reflexes will not carry over even if isolation mode is disabled.
:::

## Session Storage

We are strong believers in the Rails Doctrine and work very hard to prioritize convention over configuration. Unfortunately, there are some inherent limitations to the way cookies are communicated via websockets that make it difficult to use cookies for session storage in production.

We default to using the `:cache_store` for `config.session_store` (and enabling caching) in the development environment if no other option has been declared. Many developers switch to using the [redis-session-store gem](https://github.com/roidrage/redis-session-store), especially in production.

You can learn more about session storage on the Deployment page.

TODO [deployment.md](../appendices/deployment.md)

## Rack middleware support

While StimulusReflex is optimized for speed, some developers might be using Rack middleware that rewrites the URL, which could cause problems for Page Morphs.

You can add any middleware you need in your initializer:

::: code-group
```ruby [config/initializers/stimulus_reflex.rb]
StimulusReflex.configure do |config|
  config.middleware.use FirstRackMiddleware
  config.middleware.use SecondRackMiddleware
end
```
:::

::: warning
Users of [Jumpstart Pro](https://jumpstartrails.com) are advised to add the `Jumpstart::AccountMiddleware` middleware if they are doing path-based multitenancy.
:::

## ViewComponent Integration

There is no special process required for using [view\_component](https://github.com/github/view\_component) with StimulusReflex. If ViewComponent is setup and running properly, you're already able to use them in your Reflex-enabled views.

Many StimulusReflex + ViewComponent developers are enjoying using the [view\_component\_reflex](https://github.com/joshleblanc/view\_component\_reflex) gem, which automatically persists component state to your session between Reflexes.

## Rails 5.2+ Support

To use Rails 5.2 with StimulusReflex, you'll need the latest Action Cable package from npm: `@rails/actioncable`

1. Replace `actioncable` with `@rails/actioncable` in `package.json`
   * `yarn remove actioncable`
   * `yarn add @rails/actioncable`
2. Replace any instance of `import Actioncable from "actioncable"` with `import { createConsumer } from "@rails/actioncable"`
   * This imports the `createConsumer` function directly
   * Previously, you might call `createConsumer()` on the `Actioncable` import: `Actioncable.createConsumer()`
   * Now, you can reference `createConsumer()` directly

::: warning
There's nothing about StimulusReflex 3+ that shouldn't work fine in a Rails 5.2 app if you're willing to do a bit of manual package dependency management.

If you're having trouble with converting your Rails 5.2 app to work correctly with webpacker, you should check out "[Rails 5.2, revisited](../appendices/troubleshooting.md#rails-5-2-revisited)" on the Troubleshooting page.
:::

## Polyfills for IE11

If you need to provide support for older browsers, you can `yarn add @stimulus_reflex/polyfills` and include them **before** your Stimulus controllers:

::: code-group
```javascript [app/javascript/packs/application.js]
// other stuff
import '@stimulus_reflex/polyfills'
import 'controllers'
```
:::

## Running "Edge"

If you are interested in running the latest version of StimulusReflex, you can point to the `master` branch on Github:

::: code-group
```javascript [package.json]
"dependencies": {
  "stimulus_reflex": "stimulusreflex/stimulus_reflex#master"
}
```
:::

::: code-group
```ruby [Gemfile]
gem "stimulus_reflex", github: "stimulusreflex/stimulus_reflex", branch: "master"
```
:::

Restart your server(s) and refresh your page to see the latest.

::: warning
It is really important to **always make sure that your Ruby and JavaScript package versions are the same**!
:::

### Running a branch to test a Github Pull Request

Sometimes you want to test a new feature or bugfix before it is officially merged with the `master` branch. You can adapt the "Edge" instructions and run code from anywhere.

Using [#335 - tab isolation mode v2](https://github.com/hopsoft/stimulus\_reflex/pull/335) as an example, we first need the Github username of the author and the name of their local branch associated with the PR. In this case, the answers are `leastbad` and `isolation_optional`. This is a branch on the forked copy of the main project; a pull request is just a proposal to merge the changes in this branch into the `master` branch of the main project repository.

::: code-group
```javascript [package.json]
"dependencies": {
  "stimulus_reflex": "leastbad/stimulus_reflex#isolation_optional"
}
```
:::

::: code-group
```ruby [Gemfile]
gem "stimulus_reflex", github: "leastbad/stimulus_reflex", branch: "isolation_optional"
```
:::

Restart your server(s) and refresh your page to see the latest.
