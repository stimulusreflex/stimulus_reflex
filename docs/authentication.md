---
description: How to secure your StimulusReflex application
---

# Authentication

If you're just trying to bootstrap a proof-of-concept application on your local workstation, you don't technically have to worry about giving ActionCable the ability to distinguish between multiple concurrent users. However, **the moment you deploy to a host with more than one person accessing your app, you'll find that you're sharing a session and seeing other people's updates**. That isn't what most developers have in mind.

## Authentication != Authorization

Libraries like Pundit, CanCanCan and Authz don't directly work on Reflexes because Reflexes action methods run before the controller action is called.

If your application makes use of role-based authorization to different resources, and that authorization usually happens in the controller, you should design your application such that state mutations and database updates with destructive outcomes happen in the controller.

You could use `before_reflex` callbacks to validate that the current user is authorized to take this action and call `throw :abort` to prevent the Reflex if the user is making decisions above their pay grade.

If you come up with a clever generalized approach, please let us know about it.

## Encrypted Session Cookies

You can use your default Rails encrypted cookie-based sessions to isolate your users into their own sessions. This works great even if your application doesn't have a login system.

{% code title="app/controllers/application\_controller.rb" %}
```ruby
class ApplicationController < ActionController::Base
  before_action :set_action_cable_identifier

  private

  def set_action_cable_identifier
    cookies.encrypted[:session_id] = session.id.to_s
  end
end
```
{% endcode %}

{% code title="app/channels/application\_cable/connection.rb" %}
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :session_id

    def connect
      self.session_id = cookies.encrypted[:session_id]
    end
  end
end
```
{% endcode %}

## User-based Authentication

Many Rails apps use the current\_user convention or more recently, the [Current](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html) object to provide a global user context. This gives access to the user scope from _almost_ all parts of your application.

{% code title="app/controllers/application\_controller.rb  " %}
```ruby
class ApplicationController < ActionController::Base
  before_action :set_action_cable_identifier

  private

  def set_action_cable_identifier
    cookies.encrypted[:user_id] = current_user&.id
  end
end
```
{% endcode %}

{% code title="app/channels/application\_cable/connection.rb " %}
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      user_id = cookies.encrypted[:user_id]
      return reject_unauthorized_connection if user_id.nil?
      user = User.find_by(id: user_id)
      return reject_unauthorized_connection if user.nil?
      self.current_user = user
    end
  end
end
```
{% endcode %}

Note that without intervention, your Reflex classes will **not** be able to see current\_user. This is easily fixed by setting `self.current_user = user` above and then delegating `current_user` to your ActionCable connection:

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection

  def do_stuff
    current_user.first_name
  end
end
```
{% endcode %}

## Devise-based Authentication

If you're using the versatile [Devise](https://github.com/plataformatec/devise) authentication library, your configuration is even easier.

{% code title="app/channels/application\_cable/connection.rb" %}
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = env["warden"].user || reject_unauthorized_connection
    end
  end
end
```
{% endcode %}

Delegate `current_user` to the ActionCable `connection` and be home by lunch:

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection
end
```
{% endcode %}

## Sorcery-based Authentication

If you're using [Sorcery](https://github.com/Sorcery/sorcery) for authentication, you'd need to pull the user's `id` out of the session store.

{% code title="app/channels/application\_cable/connection.rb" %}
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = User.find_by(id: request.session.fetch("user_id", nil)) || reject_unauthorized_connection
    end
  end
end
```
{% endcode %}

Now you're free to delegate `current_user` to the ActionCable `connection`.

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection
end
```
{% endcode %}

## Token-based Authentication

{% hint style="danger" %}
This section is a Work In Progress that is not yet functional in the current version of StimulusReflex. It's not yet something that you can use in your application.
{% endhint %}

There are scenarios where developers might wish to use JWT or some other form of authenticated programmatic access to an application using websockets. For example, you can configure a GraphQL service to accept queries over ActionCable instead of providing an URL endpoint for traditional Ajax calls. You also might need to support multiple custom domains with one ActionCable endpoint. You might also need a solution that doesn't depend on cookies, such as when you want to deploy multiple AnyCable nodes on a service like Heroku.

Your first instinct might be to authenticate in `connection.rb` using ugly hacks where you pass a token as part of your ActionCable connection URL. While this seems to make sense - after all, this is close to how the other techniques above work - **putting your token into the URL is a real security vulnerability** and there's a better way: _move the responsibility for authentication from the ActionCable connection down to the channels themselves_. Let's consider a potential solution that uses the [Warden::JWTAuth](https://github.com/waiting-for-dev/warden-jwt_auth) module:

{% code title="app/channels/application\_cable/connection.rb" %}
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
  end
end
```
{% endcode %}

We create the `current_user` accessor as usual, but we won't be able to set it until someone successfully create a subscription to a channel. If they fail to pass a valid token, we can deny them a subscription. That means that all channels will need to be able to authenticate tokens during the subscription creation process. We will create a `subscribed` method in `ApplicationCable`, which all of your channels inherit from.

{% code title="app/channels/application\_cable/channel.rb" %}
```ruby
module ApplicationCable
  class Channel < ActionCable::Channel::Base
    attr_accessor :current_user

    def subscribed
      authenticate_user!
    end

    private

    def authenticate_user!
      @current_user ||= decode_user params[:token]
      reject unless @current_user
      connection.current_user = @current_user
    end

    def decode_user(token)
      Warden::JWTAuth::UserDecoder.new.call token, :user, nil if token
    rescue JWT::DecodeError
      nil
    end
  end
end
```
{% endcode %}

In this configuration, a failure to match a token with a Warden user results in a call to `reject`. This means that while they have successfully established an ActionCable connection, they do not have the credentials to subscribe to the individual channel. Notice how we manually set the `current_user` on the connection if the authentication is successful.

In order for this scheme to work, all of your ActionCable channels - including StimulusReflex - must conform to the same validation mechanism. StimulusReflex itself will access the `ApplicationCable::Channel` definition in your application. You can set additional channels to authenticate in this manner by making sure that they inherit from `ApplicationCable::Channel` and that the `subscribed` method calls `super` before your `stream_from` or `stream_for` statement:

{% code title="app/channels/test\_channel.rb" %}
```ruby
class TestChannel < ApplicationCable::Channel
  def subscribed
    super
    stream_from "test"
  end
end
```
{% endcode %}

{% code title="app/javascript/channels/test\_channel.js" %}
```javascript
import consumer from './consumer'

consumer.subscriptions.create(
  {
    channel: 'TestChannel',
    token: document.querySelector('meta[name=action-cable-auth-token]').content
  },
  {
    connected () { console.log('Token accepted') },
    rejected () { console.log('Token rejected') }
  }
)
```
{% endcode %}

Set a JWT token for the current user in your layout template. Note that in this example we do assume that the `warden-jwt_auth` gem is in your project \(possibly through `devise-jwt`\) and that there is a valid `current_user` accessor in scope.

{% code title="app/controllers/application\_controller.rb" %}
```ruby
class ApplicationController < ActionController::Base
  before_action do
    @token = Warden::JWTAuth::UserEncoder.new.call(current_user, :user, nil).first
  end
end
```
{% endcode %}

{% code title="app/views/layout/application.html.erb" %}
```markup
<head>
  <meta name="action-cable-auth-token" content="<%= @token %>"/>
</head>
```
{% endcode %}

Now, make sure that StimulusReflex is able to access the JWT token from your DOM:

{% code title="app/javascript/controllers/index.js" %}
```javascript
import { Application } from 'stimulus'
import { definitionsFromContext } from 'stimulus/webpack-helpers'
import StimulusReflex from 'stimulus_reflex'

const application = Application.start()
const context = require.context('controllers', true, /_controller\.js$/)
const params = { token: document.head.querySelector('meta[name=action-cable-auth-token]').content }
application.load(definitionsFromContext(context))

StimulusReflex.initialize(application, { params })
```
{% endcode %}

Finally, delegate `current_user` to the ActionCable `connection` as you would in any other Reflex class:

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection
end
```
{% endcode %}

## Unauthenticated Connections

Perhaps your application doesn't have users. And maybe it doesn't even have sessions! You just want to offer all visitors access for the duration of the time that they are looking at your page. This will give every browser looking at your page a unique ActionCable connection.

{% code title="app/channels/application\_cable/connection.rb" %}
```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :uuid

    def connect
      self.uuid = SecureRandom.urlsafe_base64
    end
  end
end
```
{% endcode %}

While there is no user concept in this scenario, you can still access the visitor's uuid:

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  delegate :uuid, to: :connection
end
```
{% endcode %}

