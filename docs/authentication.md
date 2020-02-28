---
description: How to secure your StimulusReflex application
---

# Authentication

If you're just trying to bootstrap a proof-of-concept application on your local workstation, you don't technically have to worry about giving ActionCable the ability to distinguish between multiple concurrent users. However, **the moment you deploy to a host with more than one person accessing your app, you'll find that you're sharing a session and seeing other people's updates**. That isn't what most developers have in mind.

## Encrypted Session Cookies

You can use your default Rails encrypted cookie-based sessions to isolate your users into their own sessions. This works great even if your application doesn't have a login system.

{% code title="app/controllers/application\_controller.rb" %}
```ruby
class ApplicationController < ActionController::Base
  before_action :set_action_cable_identifier

  private

  def set_action_cable_identifier
    cookies.encrypted[:session_id] = session.id
  end
end	end
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

Many Rails apps use the current\_user convention or more recently, the  [Current](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html) object to provide a global user context. This gives access to the user scope from _almost_ all parts of your application.

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

Note that without intervention, your Reflex classes will **not** be able to see current\_user. This is easily fixed by setting `self.current_user = user` above and then delegating current\_user to your ActionCable Connection:

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
      self.current_user = find_verified_user
    end
    
    protected

    def find_verified_user
      if current_user = env["warden"].user
        current_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```
{% endcode %}

Now you're free to delegate current\_user. Be home by lunch:

{% code title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  delegate :current_user, to: :connection
end
```
{% endcode %}



