---
description: How to prepare your app to use StimulusReflex
---

<script setup>
  import LinkComponent from '../components/LinkComponent.vue'
</script>

# Setup

## Command-Line Install

StimulusReflex relies on [Stimulus](https://stimulus.hotwired.dev), an excellent library from the creators of Rails. You can easily install StimulusReflex to new and existing Rails 6+ projects. For Rails 5.2, see [here](/hello-world/setup#rails-5-2-support).

::: warning
StimulusReflex requires Redis to be [installed and running](https://redis.io/topics/quickstart).
:::

The terminal commands below will ensure that both Stimulus and StimulusReflex are installed. It creates common files and an example to get you started. It also handles some of the configuration outlined below, **including enabling caching in your development environment**. (You can read more about why we enable caching [here](/appendices/deployment#session-storage).)

### Step 1: Ruby

Add the `stimulus_reflex` gem to `Gemfile` using `bundle add`:

```shell
bundle add stimulus_reflex --version 3.5.0.rc3
```

or manually add this line to your `Gemfile`:
```ruby
gem 'stimulus_reflex', '3.5.0.rc3'
```

### Step 2: JavaScript

StimulusReflex 3.5 is designed to work with all the asset bundling solutions Rails 7 supports.

StimulusReflex's installer will try to automatically detect your bundling setup and asks you to confirm the choice.

#### Automatic Setup

The let the installer automatically detect your setup run:

```shell
rails stimulus_reflex:install
```

The installer tries to detect your setup and asks you to confirm the choice:

```
Where do JavaScript files live in your app? Our best guess is: app/javascript 🤔
Press enter to accept this, or type a different path.
>
```

Similar with the bundler choice:

```
It looks like you're using esbuild as your bundler. Is that correct? (Y/n)
>
```

The bundler will continue and guide you through the install process.

#### Manual selection

If the installer can't automatically detect your setup or you want tell the installer which strategy to use you can run the `stimulus_reflex:install` command with an argument.

##### Using Importmaps

```bash
rails stimulus_reflex:install importmap
```

##### Using esbuild

```bash
rails stimulus_reflex:install esbuild
```

##### Using Vite

```bash
rails stimulus_reflex:install vite
```

##### Using Webpacker

```bash
rails stimulus_reflex:install webpacker
```

##### Using Shackapacker

```bash
rails stimulus_reflex:install shakapacker
```

And that's it! You can start using StimulusReflex in your application with the `development` environment. You'll need to keep reading to set up [`test`](/appendices/testing#test-environment-setup) and [`production`](/appendices/deployment).

<LinkComponent name="Quick Start" href="/hello-world/quickstart" />

## Manual Configuration

Some developers will need more control than a one-size-fits-all install task, so we're going to step through what's actually required to get up and running with StimulusReflex in your Rails 6+ project in the _development_ environment. You'll need to keep reading to set up [test](/appendices/testing#test-environment-setup) and [production](/appendices/deployment). For Rails 5.2, see [here](/hello-world/setup#rails-5-2-support).

::: warning
StimulusReflex requires Redis to be [installed and running](https://redis.io/topics/quickstart).

You can learn more about optimizing your Redis configuration, why we enable caching in development and why we don't currently support cookie sessions on the [Deployment](/appendices/deployment#session-storage) page.
:::

We'll install the StimulusReflex gem and client library before enabling caching in your development environment. An initializer called `stimulus_reflex.rb` will be created with default values.

::: info
We assume [Stimulus](https://stimulus.hotwired.dev) is present in your app, along with a Javascript bundling mechanism. If in doubt, please consult the READMEs of [jsbundling-rails](https://github.com/rails/jsbundling-rails) and [stimulus-rails](https://github.com/hotwired/stimulus-rails).

StimulusReflex happily supports Stimulus versions 1.1, 2 and 3.
:::

```ruby
bundle add stimulus_reflex --version 3.5.0.rc3
bundle add redis-session-store
yarn add stimulus_reflex@3.5.0.rc3
rails dev:cache # caching needs to be enabled
rails generate stimulus_reflex:initializer
```

We need to modify our Stimulus configuration to import and initialize StimulusReflex, which will attempt to locate the existing ActionCable consumer. A new websocket connection is created if the consumer isn't found.

::: code-group
```javascript [app/javascript/controllers/index.js]
import { application } from "./application"
import applicationController from "./application_controller"
import StimulusReflex from "stimulus_reflex"

import controllers from "./**/*_controller.js"

controllers.forEach((controller) => {
  application.register(controller.name, controller.module.default)
})

StimulusReflex.initialize(application, { applicationController, isolate: true })

// consider removing these options in production
StimulusReflex.debug = true
// end remove
```
```javascript [app/javascript/controllers/application.js]
import { Application } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
application.consumer = consumer
window.Stimulus   = application

export { application }
```
:::

**Cookie-based session storage is not currently supported by StimulusReflex.**

Instead, we enable caching in the development environment so that we can assign our user session data to be managed by the cache store.

In Rails, the default cache store is the memory store. We want to change the cache store to make use of Redis:

::: code-group
```ruby [config/environments/development.rb]
Rails.application.configure do
  # CHANGE the following line; it's :memory_store by default
  config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } }

  # ADD the following line; it probably doesn't exist
  config.session_store :redis_session_store, key: "_sessions_development", compress: true, pool_size: 5, expire_after: 1.year
end
```
:::

You can read more about configuring Redis on the [Deployment](/appendices/deployment#session-storage) page.

Configure ActionCable to use the Redis adapter in development mode:

::: code-group
```yaml [config/cable.yml]
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: your_application_development
```
:::

You should also add the `action_cable_meta_tag` helper to your application template so that ActionCable can access important configuration settings:

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
There have been recent reports of a change in the Safari web browser that cause Action Cable connections to drop. You can find a hotfix to mitigate this issue [here](/appendices/troubleshooting#safari-nsurlsession-websocket-bug).
:::

## Upgrading, package versions and sanity

In the future, should you ever upgrade your version of StimulusReflex, it's very important that you always make sure your gem version and npm package versions match.

Since mismatched versions are the first step on the path to hell, by default StimulusReflex won't allow the server to start if your versions are mismatched.

You can override this setting in your initializer.
* `:exit` (default) will prevent the server process from starting.
* `:warn` will emit the same text-based warning but not prevent the server process from starting.
* `:ignore` will silence all mismatched version warnings.

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

When the time comes, it's easy to configure your application to support authenticating users by their Rails session or `current_user` scope. Just check out the Authentication page and choose your own adventure.

<LinkComponent name="Authentication" href="/guide/authentication" />

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

We default to using the `:cache_store` for `config.session_store` (and enabling caching) in the development environment if no other option has been declared. Many developers switch to using the [`redis-session-store` gem](https://github.com/roidrage/redis-session-store), especially in production.

You can learn more about session storage on the Deployment page.

<LinkComponent name="Deployment" href="/appendices/deployment" />

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

There is no special process required for using [`view_component`](https://github.com/github/view_component) with StimulusReflex. If ViewComponent is setup and running properly, you're already able to use them in your Reflex-enabled views.

Many StimulusReflex + ViewComponent developers are enjoying using the [`view_component_reflex`](https://github.com/joshleblanc/view_component_reflex) gem, which automatically persists component state to your session between Reflexes.

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

If you're having trouble with converting your Rails 5.2 app to work correctly with webpacker, you should check out "[Rails 5.2, revisited](/appendices/troubleshooting#rails-5-2-revisited)" on the Troubleshooting page.
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

If you are interested in running the latest version of StimulusReflex, you can point to the `main` branch on GitHub:

::: code-group
```ruby [Gemfile]
gem "stimulus_reflex", github: "stimulusreflex/stimulus_reflex", branch: "main"
```
:::

And for the JavaScript package your want to get the latest commit sha on `main` and use the first 7 characters of that commit.

Replace the `[commit sha]` in the command below and it will install the latest version from main.

::: code-group
```bash [Terminal]
yarn add stimulus_reflex@https://github.com/stimulusreflex/dev-builds/archive/refs/tags/stimulus_reflex/[commit sha].tar.gz
```

Restart your server(s) and refresh your page to see the latest.

::: warning
It is really important to **always make sure that your Ruby and JavaScript package versions are the same**!
:::
