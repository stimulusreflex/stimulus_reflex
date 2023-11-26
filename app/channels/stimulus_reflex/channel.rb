# frozen_string_literal: true

class StimulusReflex::Channel < StimulusReflex.configuration.parent_channel.constantize
  def stream_name
    [params[:channel], connection.connection_identifier].reject(&:blank?).join(":")
  end

  def subscribed
    super
    stream_from stream_name
  end

  def receive(data)
    begin
      reflex = StimulusReflex::ReflexFactory.new(self, data).call
      delegate_call_to_reflex reflex
    rescue => exception
      error = exception_with_backtrace(exception)

      if reflex
        error_message = "\e[31mReflex #{reflex.data.target} failed: #{error[:message]} [#{reflex.url}]\e[0m\n#{error[:stack]}"
        reflex.rescue_with_handler(exception)
        reflex.logger&.error error_message
        reflex.broadcast_error data: data, error: "#{exception} #{exception.backtrace.first.split(":in ")[0] if Rails.env.development?}"
      else
        error_message = "\e[31mReflex failed: #{error[:message]} \e[0m\n#{error[:stack]}"
        unless exception.is_a?(StimulusReflex::VersionMismatchError)
          StimulusReflex.config.logger.error error_message
        end

        if error_message.to_s.include? "No route matches"
          initializer_path = Rails.root.join("config", "initializers", "stimulus_reflex.rb")

          StimulusReflex.config.logger.warn <<~NOTE
            \e[33mNOTE: StimulusReflex failed to locate a matching route and could not re-render the page.

            If your app uses Rack middleware to rewrite part of the request path, you must enable those middleware modules in StimulusReflex.
            The StimulusReflex initializer should be located at #{initializer_path}, or you can generate it with:

              $ bundle exec rails generate stimulus_reflex:config

            Configure any required middleware:

              StimulusReflex.configure do |config|
                config.middleware.use FirstRackMiddleware
                config.middleware.use SecondRackMiddleware
              end\e[0m

          NOTE
        end
      end
      return
    end

    if reflex.halted?
      reflex.broadcast_halt data: data
    elsif reflex.forbidden?
      reflex.broadcast_forbid data: data
    else
      begin
        reflex.broadcast(reflex.selectors, data)
      rescue => exception
        reflex.rescue_with_handler(exception)
        error = exception_with_backtrace(exception)
        reflex.broadcast_error data: data, error: "#{exception} #{exception.backtrace.first.split(":in ")[0] if Rails.env.development?}"
        reflex.logger&.error "\e[31mReflex failed to re-render: #{error[:message]} [#{reflex.url}]\e[0m\n#{error[:stack]}"
      end
    end
  ensure
    if reflex
      commit_session(reflex)
      report_failed_basic_auth(reflex) if reflex.controller?
      reflex.logger&.log_all_operations
    end
  end

  private

  def delegate_call_to_reflex(reflex)
    method_name = reflex.method_name
    arguments = reflex.data.arguments
    method = reflex.method(method_name)

    policy = StimulusReflex::ReflexMethodInvocationPolicy.new(method, arguments)

    if policy.no_arguments?
      reflex.process(method_name)
    elsif policy.arguments?
      reflex.process(method_name, *arguments)
    else
      raise ArgumentError.new("wrong number of arguments (given #{arguments.inspect}, expected #{policy.required_params.inspect}, optional #{policy.optional_params.inspect})")
    end
  end

  def commit_session(reflex)
    store = reflex.request.session.instance_variable_get(:@by)
    store.commit_session reflex.request, reflex.controller.response
  rescue => exception
    error = exception_with_backtrace(exception)
    reflex.logger&.error "\e[31mFailed to commit session! #{error[:message]}\e[0m\n#{error[:backtrace]}"
  end

  def report_failed_basic_auth(reflex)
    if reflex.controller.response.status == 401
      reflex.logger&.error "\e[31mReflex failed to process controller action \"#{reflex.controller.class}##{reflex.controller.action_name}\" due to HTTP basic auth. Consider adding \"unless: -> { @stimulus_reflex }\" to the before_action or method responible for authentication.\e[0m"
    end
  end

  def exception_with_backtrace(exception)
    {
      message: exception.to_s,
      backtrace: exception.backtrace.first.split(":in ")[0],
      stack: exception.backtrace.join("\n")
    }
  end
end
