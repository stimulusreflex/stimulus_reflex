---
description: Dealing with the scaling concerns we are supposedly lucky to have
---

# Deployment

## Session Storage

**Cookie-based session storage is not currently supported by StimulusReflex.** ActionCable does not have the ability to write cookies, so inside of a Reflex it was possible to read session values while any attempts to store them would silently fail! We called it the _bubble universe_. We have a strategy for restoring cookie session storage in mind, but it's not ready, yet.

Instead, we make the best of things by enabling caching in the development environment. This allows us to:

* assign our user session data to be managed by the cache store
* use the [Rails Cache API](../rtfm/persistence.md#the-rails-cache-store) to store data that we access from Reflexes
* catch bugs that otherwise might only occur in production

### Use Redis as your cache store

We want to change the cache store to make use of Redis. First we should enable the `redis` gem, as well as `hiredis`, a native wrapper which is much faster than the Ruby gem alone.

{% code title="Gemfile" %}
```ruby
gem "redis", ">= 4.0", :require => ["redis", "redis/connection/hiredis"]
gem "hiredis"
```
{% endcode %}

Now that Redis is available to your application, you need to configure your development enviroment:

{% code title="config/environments/development.rb" %}
```ruby
config.cache_store = :redis_cache_store, {driver: :hiredis, url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }}
config.session_store :cache_store, key: "_session_development", compress: true, pool_size: 5, expire_after: 1.year
```
{% endcode %}

{% hint style="danger" %}
Please note that `cache_store` is an accessor, while `session_store` is a method. Take care **not** to use an `=` when defining your `session_store`.
{% endhint %}

Continue reading the [Deployment on Heroku](deployment.md#deployment-on-heroku) section below for tips on setting up Redis-backed sessions using the `redis-session-store` gem.

{% hint style="warning" %}
For **caching and session storage**, make sure that your Redis instance is configured to use the `volatile-lru` key expiration strategy. It means that if your Redis instance gets full, it will start ejecting the session data for the users who have likely churned anyhow, while ensuring regular users stay logged in.
{% endhint %}

## Deployment on Heroku

We have seen deployments where combining cache and session storage functions into one Redis database has led to strange behavior, such as forgetting Rails sessions after 10-15 minutes. Luckily, we have an excellent workaround based on splitting up caching and session functions into separate Redis instances.

Heroku allows you to provision multiple Redis instances to your application, both via their [Heroku Redis](https://elements.heroku.com/addons/heroku-redis) and using the Heroku CLI. This is possible at the free tier, so there's nothing to lose and lots to gain by splitting these up.

{% hint style="success" %}
You could end up with separate Redis instances for: fragment caching, sessions, ActionCable and Sidekiq job queues.

Remember, never store Sidekiq jobs with a `volatile-lru` key expiration strategy. If your job queue runs out of space, you want it sounding every alarm possible.
{% endhint %}

Install the `redis-session-store` gem into your project, and then in your `production.rb` you can change your session store:

{% code title="config/environments/production.rb" %}
```ruby
config.cache_store = :redis_cache_store, {driver: :hiredis, url: ENV.fetch("REDIS_URL")}

config.session_store :redis_session_store,
  key: "_session_production",
  serializer: :json,
  redis: {
    driver: :hiredis,
    expire_after: 1.year,
    ttl: 1.year,
    key_prefix: "app:session:",
    url: ENV.fetch("HEROKU_REDIS_MAROON_URL")
  }
```
{% endcode %}

{% hint style="success" %}
You don't have to use Heroku's Redis addon. If you choose another provider, your configuration will be slightly different - **only Heroku Redis assigns color-based instance names**, for example.
{% endhint %}

Heroku will give all Redis instances after the first a distinct URL. All you have to do is provide the app\_session\_key and a prefix. In this example, Rails sessions will last a maximum of one year.

### Heroku Redis Secure URLs

At the time of this writing, the `hiredis` gem does not support SSL. When you provision multiple Heroku Redis addons at the "Hobby" tier, it will give you a "color URL" and a REDIS\_TLS\_URL . You need to use the **non-TLS** one which works just fine without SSL.

If you plan to use the paid "Premium" tier Heroku Redis addons, they use Redis 6 by default and TLS becomes mandatory. Until such time as `hiredis` supports SSL, you will need to create your addon instance by specifying that Redis 5 is to be used:

```bash
heroku addons:create heroku-redis:premium-0 --version 5
```

### Build packs

Generally, only the `heroku/ruby` buildpack is required to successfully deploy a StimulusReflex app on Heroku. However, if you see the error:

`(WARNING: Can't locate the stimulus_reflex npm package [...])`

... we recommend that you try updating your Cedar stack to the latest version. This should be fixed as of Cedar-20.

## Cloudflare DNS

Cloudflare's infrastructure is nothing short of impressive, and they are a great choice for free DNS hosting. However, the default behaviour of their DNS product is to proxy all traffic to your domain. **This includes websocket traffic.**

Your mileage may vary \(literally, depending on how far you are from a Cloudflare edge node!\) but changing your DNS records from "Proxying" to "DNS Only", you could shave 60-90ms off the real-world execution time of your Reflex actions.

In a more sophisticated setup, you could experiment with hosting your websockets endpoint on a different domain, allowing you to experience the best of both worlds. In fact, this is the specific reason we add `<%= action_cable_meta_tag %>` to our HEADs.

## Nginx + Passenger

[Passenger](https://www.phusionpassenger.com/) users might have [a few extra steps](https://www.phusionpassenger.com/library/config/nginx/action_cable_integration/) to make sure that your deployment is smooth.

Specifically, if you experience your server process appear to freeze up when ActionCable is in play, you need to make sure that your `nginx.conf` has the **port 443 section** set up to receive secure websockets:

{% code title="/etc/nginx/nginx.conf" %}
```ruby
server {
    listen 443;
    passenger_enabled on;
    location /cable {
        passenger_app_group_name YOUR_APP_HERE_action_cable;
        passenger_force_max_concurrent_requests_per_process 0;
    }
}
```
{% endcode %}

Please note that **the above is not a complete document**; it's just the fragments often missing from the default configurations found on hosts like Cloud 66.

## Set your `default_url_options` for each environment

When you are using Selector Morphs, it is very common to use `ApplicationController.render()` to re-render a partial to replace existing content. It is advisable to give ActionDispatch enough information about your environment that it can pass the right values to any helpers that need to build URL paths based on the current application environment.

If your helper is generating **example.com** URLs, this is for you.

{% tabs %}
{% tab title="Development" %}
{% code title="config/environments/development.rb" %}
```ruby
config.action_controller.default_url_options = {host: "localhost", port: 3000}
```
{% endcode %}
{% endtab %}

{% tab title="Production" %}
{% code title="config/environments/production.rb" %}
```ruby
config.action_controller.default_url_options = {host: "stimulusreflex.com"}
```
{% endcode %}
{% endtab %}
{% endtabs %}

Similarly, if you need URL helpers in your mailers:

{% code title="config/environments/development.rb" %}
```ruby
config.action_mailer.default_url_options = {host: "localhost", port: 3000}
```
{% endcode %}

## AnyCable

{% hint style="danger" %}
"But does it scale?"
{% endhint %}

{% hint style="success" %}
Yes.
{% endhint %}

We're excited to announce that StimulusReflex now works with [AnyCable](https://github.com/anycable/anycable), a library which allows you to use any WebSocket server \(written in any language\) as a replacement for your Ruby WebSocket server. You can read more about the dramatic scalability possible with AnyCable in [this post](https://evilmartians.com/chronicles/anycable-actioncable-on-steroids).

We'd love to hear your battle stories regarding the number of simultaneous connections you can achieve both with and without AnyCable. Anecdotal evidence suggests that you can realistically squeeze ~4000 connections with native ActionCable, whereas AnyCable should allow roughly 10,000 connections **per node**. We've even [seen reports](https://nebulab.it/blog/actioncable-vs-anycable-fight/) that ActionCable can benchmark at 20,000 connections, while AnyCable maxes out around 60,000 because it runs out of TCP ports to allocate.

Of course, the message delivery speed - and even delivery _success_ rate - will dip as you start to approach the upper limit, so if you are working on a project successful enough to have this problem, you are advised to switch.

Getting to this point required significant effort and cooperation between members of both projects. You can try out the AnyCable v1.0 release today.

1. Add `gem "anycable-rails", "~> 1.0"` to your `Gemfile`.
2. Install `anycable-go` v1.0 \([binaries](https://github.com/anycable/anycable-go/releases) available here, Docker images are also [available](https://hub.docker.com/repository/docker/anycable/anycable-go/tags?page=1&name=preview)\).
3. If you are using the session object, you must select a cache store that is not MemoryStore, which is not compatible with AnyCable.

There is also a brand-new installation wizard which you can access via `rails g anycable:setup` after the gem has been installed.

Official AnyCable documentation for StimulusReflex can be found [here](https://docs.anycable.io/v1/#/ruby/stimulus_reflex). If you notice any issues with AnyCable support, please tell us about it [here](https://github.com/stimulusreflex/stimulus_reflex/issues/46).

{% hint style="info" %}
If you're looking to authenticate AnyCable connections with Devise, the documentation for that process is [here](https://docs.anycable.io/v1/#/ruby/authentication), and there's a good discussion about this process [here](https://github.com/anycable/anycable-rails/issues/127).
{% endhint %}

## Turbolinks / Turbo Drive

We strongly recommend the use of [Turbolinks 5](https://github.com/turbolinks/turbolinks) / [Turbo Drive](https://turbo.hotwire.dev/handbook/drive) for your applications.

In addition to the dramatic speed benefits associated with swapping the page content without having to load a new page, Turbo Drive will help you minimize the resource consumption of your ActionCable connections as well.

When all of your ActionCable channels \(including StimulusReflex\) share one memoized `consumer.js` your browser doesn't have to re-establish a new websocket connection with the server on every page. Turbolinks allows your connection to be persisted between page loads.

## Native Mobile Wrappers

Turbolinks 5 offered an excellent native mobile [wrapper for building iOS apps](https://github.com/turbolinks/turbolinks-ios) based on web applications. Originally, there was an Android wrapper as well, but that codebase was later deprecated.

StimulusReflex core team member [Julian Rubisch](https://twitter.com/julian_rubisch) prepared a [video presentation with source code](https://dev.to/julianrubisch/twitter-clone-with-stimulusreflex-gone-hybrid-native-app-17fm) for people interested in offering Reflex+TL5-powered iOS apps.

Now that Turbo Drive is here, there are new mobile wrappers for both [iOS](https://github.com/hotwired/turbo-ios) and [Android](https://github.com/hotwired/turbo-android), which is incredible news. They are both technically beta, but the Hey email service apps are in production and well-received.

Once we've had an opportunity to build something with these new tools, we will update this space.

## Connecting ActionCable to a different host

If you want to set up your ActionCable backend to accept connections from a different host, you'll need to reconfigure your setup.

First, make sure that you're serving the ActionCable endpoint:

{% code title="config/routes.rb" %}
```ruby
Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
end
```
{% endcode %}

Then, you will have to modify your `consumer.js` to connect to your application URL. Note that you can connect to secure websockets via SSL by using`wss://` instead of `ws://`

{% code title="app/javascript/channels/consumer.js" %}
```javascript
import { createConsumer } from '@rails/actioncable'
export default createConsumer('wss://myapp.com/cable')
```
{% endcode %}

Finally, tweak your production configuration. **Don't disable forgery protection unless it's not working.**

{% code title="config/environments/production.rb" %}
```ruby
Rails.application.configure do
  config.action_cable.allowed_request_origins
  config.action_cable.url = "wss://myapp.com/cable"
  config.action_cable.disable_request_forgery_protection = true # only if necessary
end
```
{% endcode %}

## Is StimulusReflex suitable for use in developing countries?

On the face, serving raw HTML to the client means a smaller download, there's no SPA dynamically rendering a page from JSON \(slow\) and draining the battery. However, the question deserves a more nuanced treatment - and not just because **some devices might not even support Websockets**.

It's simply true that the team developing StimulusReflex is working on relatively recent, non-mobile computers with subjectively fast, reliable connections to the internet. None of us are actively testing on legacy hardware.

Raw Websockets has more in common with UDP than TCP, in that there's no retry logic or acknowledgement of delivery. Messages can arrive out of order, or not at all.

ActionCable does add some reconnection and retry logic to Websockets that is mostly transparent. If you are disconnected, it will attempt to reconnect. If you try to send data while offline, it will raise an exception unless you handle it.

We offer two suggestions to developers looking to support users with slow, unreliable connections:

1. Don't put destructive database updates in your Reflex actions. Design your app to keep state mutation in your controller actions, and wrap everything important in transactions.
2. You might need to program defensively using two-stage commits. This means devising ways to acknowledge that transactions were completed. You should also construct your UI to hide action elements like buttons when your connection is dropped.

If you're working through these issues, please get in touch with us on Discord. We will work hard to help.

