# frozen_string_literal: true

class StimulusReflex::Reflex
  include ActiveSupport::Rescuable
  include ActiveSupport::Callbacks

  define_callbacks :process, skip_after_callbacks_if_terminated: true

  class << self
    def before_reflex(*args, &block)
      add_callback(:before, *args, &block)
    end

    def after_reflex(*args, &block)
      add_callback(:after, *args, &block)
    end

    def around_reflex(*args, &block)
      add_callback(:around, *args, &block)
    end

    private

    def add_callback(kind, *args, &block)
      options = args.extract_options!
      options.assert_valid_keys :if, :unless, :only, :except
      set_callback(*[:process, kind, args, normalize_callback_options!(options)].flatten, &block)
    end

    def normalize_callback_options!(options)
      normalize_callback_option! options, :only, :if
      normalize_callback_option! options, :except, :unless
      options
    end

    def normalize_callback_option!(options, from, to)
      if (from = options.delete(from))
        from_set = Array(from).map(&:to_s).to_set
        from = proc { |reflex| from_set.include? reflex.method_name }
        options[to] = Array(options[to]).unshift(from)
      end
    end
  end

  attr_reader :channel, :url, :element, :selectors, :method_name, :render_mode

  delegate :connection, to: :channel
  delegate :session, to: :request

  def initialize(channel, url: nil, element: nil, selectors: [], method_name: nil, render_mode: nil, params: {})
    @channel = channel
    @url = url
    @element = element
    @selectors = selectors
    @method_name = method_name
    @render_mode = render_mode
    @params = params
  end

  def request
    @request ||= begin
      uri = URI.parse(url)
      path = ActionDispatch::Journey::Router::Utils.normalize_path(uri.path)
      query_hash = Rack::Utils.parse_nested_query(uri.query)
      req = ActionDispatch::Request.new(
        connection.env.merge(
          Rack::MockRequest.env_for(uri.to_s).merge(
            "rack.request.query_hash" => query_hash,
            "rack.request.query_string" => uri.query,
            "ORIGINAL_SCRIPT_NAME" => "",
            "ORIGINAL_FULLPATH" => path,
            Rack::SCRIPT_NAME => "",
            Rack::PATH_INFO => path,
            Rack::REQUEST_PATH => path,
            Rack::QUERY_STRING => uri.query
          )
        )
      )
      path_params = Rails.application.routes.recognize_path_with_request(req, url, req.env[:extras] || {})
      req.env.merge(ActionDispatch::Http::Parameters::PARAMETERS_KEY => path_params)
      req.env["action_dispatch.request.parameters"] = @params
      req.tap { |r| r.session.send :load! }
    end
  end

  def url_params
    @url_params ||= Rails.application.routes.recognize_path_with_request(request, request.path, request.env[:extras] || {})
  end

  def process(name, *args)
    reflex_invoked = false
    result = run_callbacks(:process) {
      public_send(name, *args).tap { reflex_invoked = true }
    }
    @halted ||= result == false && !reflex_invoked
    result
  end

  # Indicates if the callback chain was halted via a throw(:abort) in a before_reflex callback.
  # SEE: https://api.rubyonrails.org/classes/ActiveSupport/Callbacks.html
  # IMPORTANT: The reflex will not re-render the page if the callback chain is halted
  def halted?
    !!@halted
  end

  def default_reflex
    # noop default reflex to force page reloads
  end

  def params
    @_params ||= ActionController::Parameters.new(request.parameters)
  end
end
