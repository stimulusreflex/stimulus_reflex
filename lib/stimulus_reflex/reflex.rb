# frozen_string_literal: true

class StimulusReflex::Reflex
  attr_reader :channel, :url, :element, :selectors

  delegate :connection, to: :channel
  delegate :session, to: :request

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
      path_params = Rails.application.routes.recognize_path(path)
      query_hash = Rack::Utils.parse_nested_query(uri.query)
      ActionDispatch::Request.new(
        connection.env.merge(
          Rack::MockRequest.env_for(uri.to_s).merge(
            "rack.request.query_hash" => query_hash,
            "rack.request.query_string" => uri.query,
            "ORIGINAL_SCRIPT_NAME" => "",
            "ORIGINAL_FULLPATH" => path,
            Rack::SCRIPT_NAME => "",
            Rack::PATH_INFO => path,
            Rack::REQUEST_PATH => path,
            Rack::QUERY_STRING => uri.query,
            ActionDispatch::Http::Parameters::PARAMETERS_KEY => path_params
          )
        )
      ).tap { |req| req.session.send :load! }
    end
  end

  def url_params
    @url_params ||= Rails.application.routes.recognize_path_with_request(request, request.path, request.env[:extras] || {})
  end
end
