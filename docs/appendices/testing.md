---
description: This page is woefully incomplete because we need your help to finish it.
---

# Testing (WIP)

In the future, this page will be home to the definitive guide to testing StimulusReflex. Until then, we're doing our best!

After many conversations and a few threats of potential future action, sometimes the only way to get started is to start. The stucture, order and content best suited to the topic of testing is still very much an open conversation.

Please do drop by [`#stimulus_reflex`](https://discord.gg/stimulus-reflex) on the StimulusReflex Discord and offer your best ideas.

## Test environment setup

Setting up your test environment to run StimulusReflex is very similar to what you probably already have running in development. Please verify that Reflexes are working in development before troubleshooting your test environment.

Here is a checklist of what needs to be enabled, much of which is borrowed from the development environment setup:

Install [Redis](https://redis.io/download). Make sure that it's running and accessible to the Rails project and then include connectivity gems:

::: code-group
```ruby [Gemfile]
gem "redis", ">= 4.0", :require => ["redis", "redis/connection/hiredis"]
gem "hiredis"
```
:::

To setup your Rails credentials for the test environment and link to Redis, run `rails credentials:edit --environment test` and add the following:

```yaml
redis_url: redis://localhost:6379/0
```

Configure ActionCable to use your Redis instance:

::: code-group
```yaml [config/cable.yml]
test:
  adapter: redis
  url: <%= Rails.application.credentials.redis_url %>
  channel_prefix: your_app_test
```
:::

Configure your cache store and turn on ActionController caching:

::: code-group
```ruby [config/environments/test.rb]
config.action_controller.perform_caching = true
config.cache_store = :redis_cache_store, {driver: :hiredis, url: Rails.application.credentials.redis_url}
```
:::

## Resources

### ActionCable testing guide

There's lots of helpful information contained in the [Testing Rails Applications](https://guides.rubyonrails.org/testing.html#testing-action-cable) guide page.

### `stimulus_reflex_testing` gem

Our friends at Podia released [`stimulus_reflex_testing`](https://github.com/podia/stimulus_reflex_testing), which provides some helpers for unit testing your Reflex classes.

## Open questions!

How do you run the StimulusReflex tests on the server? How do you run them on the client?

Where do we need more coverage?
