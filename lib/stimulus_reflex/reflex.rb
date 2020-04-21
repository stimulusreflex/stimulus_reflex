# frozen_string_literal: true

class StimulusReflex::Reflex
  include ActiveSupport::Callbacks

  attr_reader :channel, :url, :element, :selectors

  delegate :connection, to: :channel
  delegate :session, to: :request

  define_callbacks :process_action

  def initialize(channel, url: nil, element: nil, selectors: [])
    @channel = channel
    @url = url
    @element = element
    @selectors = selectors
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
      req.tap { |r| r.session.send :load! }
    end
  end

  def url_params
    @url_params ||= Rails.application.routes.recognize_path_with_request(request, request.path, request.env[:extras] || {})
  end

  def process_action(name, *args)
    run_callbacks(:process_action) do
      public_send(name, *args)
    end
  end

  class << self
    [:before, :after].each do |callback|
      define_method "#{callback}_action" do |*methods|
        methods.each do |method|
          set_callback :process_action, callback, method
        end
      end
    end
  end
end
