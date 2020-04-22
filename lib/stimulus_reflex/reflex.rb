# frozen_string_literal: true

class StimulusReflex::Reflex
  include ActiveSupport::Callbacks

  attr_reader :channel, :url, :element, :selectors, :reflex_name

  delegate :connection, to: :channel
  delegate :session, to: :request

  define_callbacks :process_reflex

  def initialize(channel, url: nil, element: nil, selectors: [], reflex_name: nil)
    @channel = channel
    @url = url
    @element = element
    @selectors = selectors
    @reflex_name = reflex_name
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

  def process_reflex(name, *args)
    run_callbacks(:process_reflex) do
      public_send(name, *args)
    end
  end

  class << self
    [:before, :after, :around].each do |callback|
      define_method "#{callback}_reflex" do |*method_names, &block|
        insert_callbacks(method_names, block) do |method_name, options|
          set_callback(:process_reflex, callback, method_name, options)
        end
      end
    end

    private

    def insert_callbacks(method_names, block = nil)
      options = method_names.extract_options!
      normalize_callback_options(options)

      method_names.push(block) if block
      method_names.each do |method_name|
        yield method_name, options
      end
    end

    def normalize_callback_options(options)
      normalize_callback_option(options, :only, :if)
      normalize_callback_option(options, :except, :unless)
    end

    def normalize_callback_option(options, from, to)
      if (from = options.delete(from))
        from_set = Array(from).map(&:to_s).to_set
        from = proc { |reflex| from_set.include? reflex.reflex_name }
        options[to] = Array(options[to]).unshift(from)
      end
    end
  end
end
