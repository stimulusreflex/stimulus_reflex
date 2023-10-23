# frozen_string_literal: true

require "stimulus_reflex/cable_readiness"
require "stimulus_reflex/version_checker"

class StimulusReflex::Reflex
  prepend StimulusReflex::CableReadiness
  include StimulusReflex::VersionChecker
  include StimulusReflex::Callbacks
  include ActiveSupport::Rescuable
  include ActionView::Helpers::TagHelper
  include CableReady::Identifiable

  attr_accessor :payload, :headers
  attr_reader :channel, :reflex_data, :broadcaster

  delegate :connection, :stream_name, to: :channel
  delegate :controller_class, :flash, :session, to: :request
  delegate :broadcast, :broadcast_halt, :broadcast_forbid, :broadcast_error, to: :broadcaster

  # TODO remove xpath_controller and xpath_element for v4
  delegate :url, :element, :selectors, :method_name, :id, :tab_id, :reflex_controller, :xpath_controller, :xpath_element, :permanent_attribute_name, :version, :npm_version, :suppress_logging, to: :reflex_data
  # END TODO: remove

  alias_method :action_name, :method_name # for compatibility with controller libraries like Pundit that expect an action name
  alias_method :data, :reflex_data

  def initialize(channel, reflex_data:)
    @channel = channel
    @reflex_data = reflex_data
    @broadcaster = StimulusReflex::PageBroadcaster.new(self)
    @payload = {}
    @headers = {}

    check_version!
  end

  # TODO: remove this for v4
  def reflex_id
    warn "Deprecation warning: reflex_id will be removed in v4. Use id instead!" if Rails.env.development?
    id
  end
  # END TODO: remove

  def logger
    @logger ||= StimulusReflex::Logger.new(self) unless suppress_logging
  end

  def request
    @request ||= begin
      uri = URI.parse(url)
      path = ActionDispatch::Journey::Router::Utils.normalize_path(uri.path)
      query_hash = Rack::Utils.parse_nested_query(uri.query)
      mock_env = Rack::MockRequest.env_for(uri.to_s)

      mock_env.merge!(
        "rack.request.query_hash" => query_hash,
        "rack.request.query_string" => uri.query,
        "ORIGINAL_SCRIPT_NAME" => "",
        "ORIGINAL_FULLPATH" => path,
        Rack::SCRIPT_NAME => "",
        Rack::PATH_INFO => path,
        Rack::REQUEST_PATH => path,
        Rack::QUERY_STRING => uri.query
      )

      env = connection.env.merge(mock_env)

      middleware = StimulusReflex.config.middleware

      if middleware.any?
        stack = middleware.build(Rails.application.routes)
        stack.call(env)
      end

      req = ActionDispatch::Request.new(env)

      # fetch path params (controller, action, ...) and apply them
      request_params = StimulusReflex::RequestParameters.new(params: reflex_data.params, req: req, url: url)
      req = request_params.apply!

      req
    end
  end

  def morph(selectors, html = nil)
    case selectors
    when :page
      raise StandardError.new("Cannot call :page morph after :#{broadcaster.to_sym} morph") unless broadcaster.page?
    when :nothing
      raise StandardError.new("#{broadcaster.to_sym} morph type has already been set") if broadcaster.selector?
      @broadcaster = StimulusReflex::NothingBroadcaster.new(self) unless broadcaster.nothing?
    else
      raise StandardError.new("#{broadcaster.to_sym} morph type has already been set") if broadcaster.nothing?
      @broadcaster = StimulusReflex::SelectorBroadcaster.new(self) unless broadcaster.selector?
      broadcaster.append_morph(selectors, html)
    end
  end

  def controller
    @controller ||= controller_class.new.tap do |c|
      request.headers.merge!(headers)
      c.instance_variable_set :@stimulus_reflex, true
      c.set_request! request
      c.set_response! controller_class.make_response!(request)
    end

    instance_variables.each { |name| @controller.instance_variable_set name, instance_variable_get(name) }
    @controller
  end

  def controller?
    !!defined? @controller
  end

  def render(*args)
    options = args.extract_options!
    (options[:locals] ||= {}).reverse_merge!(params: params)
    args << options.reverse_merge(layout: false)
    controller_class.renderer.new(connection.env.merge("SCRIPT_NAME" => "")).render(*args)
  end

  # Invoke the reflex action specified by `name` and run all callbacks
  def process(name, *args)
    run_callbacks(:process) { public_send(name, *args) }
  end

  # Indicates if the callback chain was halted via a throw(:abort) in a before_reflex callback.
  # SEE: https://api.rubyonrails.org/classes/ActiveSupport/Callbacks.html
  # IMPORTANT: The reflex will not re-render the page if the callback chain is halted
  def halted?
    !!@halted
  end

  # Indicates if the callback chain was halted via a throw(:forbidden) in a before_reflex callback.
  def forbidden?
    !!@forbidden
  end

  def default_reflex
    # noop default reflex to force page reloads
  end

  def params
    @_params ||= ActionController::Parameters.new(request.parameters)
  end

  # morphdom needs content to be wrapped in an element with the same id when children_only: true
  # Oddly, it doesn't matter if the target element is a div! See: https://docs.stimulusreflex.com/appendices/troubleshooting#different-element-type-altogether-who-cares-so-long-as-the-css-selector-matches
  # Used internally to allow automatic partial collection rendering, but also useful to library users
  # eg. `morph dom_id(@posts), render_collection(@posts)`
  def render_collection(resource, content = nil)
    content ||= render(resource)
    tag.div(content.html_safe, id: dom_id(resource).from(1))
  end
end
