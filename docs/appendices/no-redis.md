# StimulusReflex without Redis

The default setup uses Redis for the Rails cache store, the Rails session store, and the ActionCable adapter. This setup variant is battle-tested, and we can promise it will work. However, if you cannot use Redis (or do not want to use Redis), there is a way to run StimulusReflex without Redis, which is purely backed by the PostgreSQL database.

Start with the manual setup, which is described [here](/hello-world/setup#manual-configuration). Complete the manual setup until we explain how to set up the initializer. This is the part where we want to change things.

First, let's add two new gems to our Gemfile.

```ruby [Gemfile]
gem "active-record-session_store"
gem "solid_cache"
```

Generate the required database configurations.

```shell
bin/rails solid_cache:install:migrations
bin/rails generate active_record:session_migration
```

Then, run migrations.

```shell
bin/rails db:migrate
```

Afterward, configure your Rails environments to use these gems.

```ruby
Rails.application.configure do
    # CHANGE the following line; it's :memory_store by default
    config.cache_store = :solid_cache_store
    
    # ADD the following line; it probably doesn't exist
    config.session_store :active_record_store, key: "_sessions_development"
end
```

You can add this configuration per environment or add it to an initializer.

Adjust the ActionCable configuration to use the PostgreSQL adapter.

```yaml
development:
  adapter: postgresql

test:
  adapter: postgresql

production:
  adapter: postgresql
```

Now Rails will happily boot your application, and StimulusReflex will work as well.

```shell
rails s
```
