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

The terminal commands above will ensure that both Stimulus and StimulusReflex are installed. It creates common files and an example to get you started. It also handles some of the configuration outlined below, including enabling caching in your development environment.

{% hint style="warning" %}
Starting with v3.0.0 of StimulusReflex, you must be running Rails 6 or above. You can find additional information for supporting Rails 5.2+ below.
{% endhint %}

{% hint style="danger" %}
Starting with v2.2.2 of StimulusReflex, support for the Rails default session storage mechanism `cookie_store` has been _temporarily_ dropped. The stimulus\_reflex:install script will now set your session storage to be :cache\_store in your development environment if no value has been set.
{% endhint %}

And that's it! **You can start using StimulusReflex in your application.**

{% page-ref page="quickstart.md" %}

## Manual Configuration

Some developers will need more control than a one-size-fits-all install task, so we're going to step through what's actually required to get up and running with StimulusReflex in your Rails 6+ project.

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

### Authentication

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

The recommended solution is to use Redis as your cache store, and `:cache_store` as your session store. Memcache is also an excellent cache store; we prefer Redis because it offers a far broader range of data structures and querying mechanisms. If you're not using Redis' advanced features, both tools are equally well-suited to key:value string caching.

{% hint style="warning" %}
Make sure that your Redis instance is configured to use the `lru-volatile` expiration strategy with expiring session keys.
{% endhint %}

Many Rails projects are already using Redis for ActiveJob queues and Russian doll caching, making the decision to use it for session storage easy and incremental. Add the `redis` and `hiredis` gems to your Gemfile:

```ruby
gem "redis", ">= 4.0", :require => ["redis", "redis/connection/hiredis"]
gem "hiredis"
```

Then configure your environments to suit your caching strategy and pool size:

```ruby
config.cache_store = :redis_cache_store, {url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }}
config.session_store :cache_store,
  key: "_session",
  compress: true,
  pool_size: 5,
  expire_after: 1.year
```

Another powerful option for session storage is to use the [activerecord-session\_store](https://github.com/rails/activerecord-session_store) gem and keep your sessions in the database. This technique requires some additional setup in the form of a migration that will create a `sessions` table in your database.

Database-backed session storage offers a single source of truth in a production environment that might be preferable to a sharded Redis cluster for high-volume deployments. However, it's also important to weigh this against the additional strain this will put on your database server, especially in high-traffic scenarios.

Regardless of which option you choose, keep an eye on your connection pools and memory usage.

## AnyCable Support

{% hint style="danger" %}
"But does it scale?"
{% endhint %}

{% hint style="success" %}
**Yes.**
{% endhint %}

We're excited to announce that StimulusReflex now works with [AnyCable](https://github.com/anycable/anycable), a library which allows you to use any WebSocket server \(written in any language\) as a replacement for your Ruby WebSocket server. You can read more about the dramatic scalability possible with AnyCable in [this post](https://evilmartians.com/chronicles/anycable-actioncable-on-steroids).

Getting to this point required significant effort and cooperation between members of both projects. You can try out a preview of the upcoming AnyCable v1.0.0 release today.

First, add `gem "anycable-rails", "1.0.0.preview1"` to your Gemfile.

Next, install `anycable-go` v1.0.0.preview \(binaries available [here](https://github.com/anycable/anycable-go/releases/tag/v1.0.0.preview1), Docker images are also [available](https://hub.docker.com/repository/docker/anycable/anycable-go/tags?page=1&name=preview)\).

Finally, if you use `session` in your Reflex classes, add `persistent_session_enabled: true` to `anycable.yml` .

There is also a brand-new installation wizard which you can access via`rails g anycable:setup` after the gem has been installed.

If you notice any issues with AnyCable support, please tell us about it [here](https://github.com/hopsoft/stimulus_reflex/issues/46).

## Rails 5.2+ Support

When the Rails core team renamed the ActionCable JS npm package from `actioncable` to `@rails/actioncable` it made it very difficult to reliably import ActionCable. After evaluating our options, we made the difficult decision of updating to the new package name and freezing _official_ Rails 5.2 support on the 2.2.x branch of StimulusReflex.

```ruby
bundle add stimulus_reflex --version "~> 2.2.3"
yarn add stimulus_reflex@2.2.3
```

While we don't have the resources to maintain two distinct package versions, we're proud of 2.2.x and consider it stable. In the unfortunate case of a critical security issue, we will make every attempt to backport hotfixes.

{% hint style="success" %}
There's nothing about StimulusReflex 3+ that shouldn't work fine in a Rails 5.2 app if you're willing to do a bit of manual package dependency management.
{% endhint %}

## Logging

In the _default_ debug log level, ActionCable emits particularly verbose log messages. You can **optionally** discard everything but exceptions by switching to the _warn_ log level, as is common in development environments:

{% code title="config/environments/development.rb" %}
```ruby
# :debug, :info, :warn, :error, :fatal, :unknown
config.log_level = :warn
```
{% endcode %}

Alternatively, disabling just ActionCable logs _may_ improve performance.

{% code title="config/initializers/action\_cable.rb" %}
```ruby
ActionCable.server.config.logger = Logger.new(nil)
```
{% endcode %}

## Troubleshooting

{% hint style="info" %}
If _something_ goes wrong, it's often because of the **spring** gem. You can test this by temporarily setting the `DISABLE_SPRING=1` environment variable and restarting your server.

To remove **spring** forever, here is the process we recommend:

1. `pkill -f spring`
2. Edit your Gemfile and comment out **spring** and **spring-watcher-listen**
3. `bin/spring binstub –-remove –-all`
{% endhint %}

