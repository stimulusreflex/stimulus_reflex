## Instrumentation

Rails instrumentation is supported on StimulusReflex operations.

SEE: https://guides.rubyonrails.org/active_support_instrumentation.html

```ruby
# wraps the stimulus reflex method invocation
ActiveSupport::Notifications.subscribe "delegate_call.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end

# instruments the page rerender
ActiveSupport::Notifications.subscribe "render_page.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end

# wraps the web socket broadcast
ActiveSupport::Notifications.subscribe "broadcast.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end

# wraps the entire receive operation which includes everything above
ActiveSupport::Notifications.subscribe "receive.stimulus_reflex" do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.debug "#{event.name} #{event.duration} #{event.payload.inspect}"
end
```
