---
description: How to secure your StimulusReflex app
---

# Security

[![GitHub stars](https://img.shields.io/github/stars/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![GitHub forks](https://img.shields.io/github/forks/hopsoft/stimulus_reflex?style=social)](https://github.com/hopsoft/stimulus_reflex) [![Twitter follow](https://img.shields.io/twitter/follow/hopsoft?style=social)](https://twitter.com/hopsoft)

StimulusReflex leans on [ActionCable for security](https://guides.rubyonrails.org/action_cable_overview.html#server-side-components-connections), but here's a **TLDR** to get you going.

{% hint style="info" %}
This should work with authentication solutions like [Devise](https://github.com/plataformatec/devise).
{% endhint %}

{% code-tabs %}
{% code-tabs-item title="app/controllers/application\_controller.rb  " %}
```ruby
class ApplicationController < ActionController::Base
  before_action :set_action_cable_identifier

  private

  def set_action_cable_identifier
    cookies.encrypted[:user_id] = current_user&.id
  end
end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="app/channels/application\_cable/connection.rb " %}
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
{% endcode-tabs-item %}

{% code-tabs-item title=undefined %}
```text

```
{% endcode-tabs-item %}
{% endcode-tabs %}

{% code-tabs %}
{% code-tabs-item title="app/reflexes/example\_reflex.rb" %}
```ruby
class ExampleReflex < StimulusReflex::Reflex
  delegate :current_user, to: :channel

  def do_suff
    current_user.first_name
  end
end
```
{% endcode-tabs-item %}
{% endcode-tabs %}

