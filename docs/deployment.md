---
description: Dealing with the scaling concerns we are supposedly lucky to have
---

# Deployment

## Session Storage

StimulusReflex configures :cache\_store to be the Rails session storage mechanism. In a production environment, you'll want to move beyond the Rails default :memory\_store cache in favor of a more robust solution.

The recommended solution is to use Redis as your cache store, and `:cache_store` as your session store. Memcache is also an excellent cache store; we prefer Redis because it offers a far broader range of data structures and querying mechanisms. If you're not using Redis' advanced features, both tools are equally well-suited to key:value string caching.

{% hint style="warning" %}
Make sure that your Redis instance is configured to use the `lru-volatile` expiration strategy with expiring session keys.
{% endhint %}

Many Rails projects are already using Redis for ActiveJob queues and Russian doll caching, making the decision to use it for session storage easy and incremental. Add the `redis` and `hiredis` gems to your Gemfile:

{% code title="Gemfile" %}
```ruby
gem "redis", ">= 4.0", :require => ["redis", "redis/connection/hiredis"]
gem "hiredis"
```
{% endcode %}

Then configure your environments to suit your caching strategy and pool size:

{% code title="config/environments/production.rb" %}
```ruby
config.cache_store = :redis_cache_store, {url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }}
config.session_store :cache_store,
  key: "_session",
  compress: true,
  pool_size: 5,
  expire_after: 1.year
```
{% endcode %}

Another powerful option for session storage is to use the [activerecord-session\_store](https://github.com/rails/activerecord-session_store) gem and keep your sessions in the database. This technique requires some additional setup in the form of a migration that will create a `sessions` table in your database.

Database-backed session storage offers a single source of truth in a production environment that might be preferable to a sharded Redis cluster for high-volume deployments. However, it's also important to weigh this against the additional strain this will put on your database server, especially in high-traffic scenarios.

Regardless of which option you choose, keep an eye on your connection pools and memory usage.

## AnyCable

{% hint style="danger" %}
"But does it scale?"
{% endhint %}

{% hint style="success" %}
Yes.
{% endhint %}

We're excited to announce that StimulusReflex now works with [AnyCable](https://github.com/anycable/anycable), a library which allows you to use any WebSocket server \(written in any language\) as a replacement for your Ruby WebSocket server. You can read more about the dramatic scalability possible with AnyCable in [this post](https://evilmartians.com/chronicles/anycable-actioncable-on-steroids). 

Getting to this point required significant effort and cooperation between members of both projects. You can try out a preview of the upcoming AnyCable v1.0.0 release today. 

1. Add `gem "anycable-rails", "1.0.0.rc1"` to your `Gemfile`. 

2. Install `anycable-go` v1.0.0.rc1 \([binaries](https://github.com/anycable/anycable-go/releases) available here, Docker images are also [available](https://hub.docker.com/repository/docker/anycable/anycable-go/tags?page=1&name=preview)\). 

3. If you are using the session object, you must select a cache store that is not MemoryStore, which is not compatible with AnyCable.

There is also a brand-new installation wizard which you can access via `rails g anycable:setup` after the gem has been installed.

Official AnyCable documentation for StimulusReflex can be found [here](https://docs.anycable.io/v1/#/ruby/stimulus_reflex). If you notice any issues with AnyCable support, please tell us about it [here](https://github.com/hopsoft/stimulus_reflex/issues/46).

{% hint style="info" %}
If you're looking to authenticate AnyCable connections with Devise, the documentation for that process is [here](https://docs.anycable.io/v1/#/ruby/authentication), and there's a good discussion about this process [here](https://github.com/anycable/anycable-rails/issues/127).
{% endhint %}

