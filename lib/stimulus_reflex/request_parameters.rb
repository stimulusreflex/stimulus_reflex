module StimulusReflex
  class RequestParameters
    def initialize(params:, req:, url:)
      @params = params
      @req = req
      @url = url
    end

    def apply!
      path_params = Rails.application.routes.recognize_path_with_request(@req, @url, @req.env[:extras] || {})
      path_params[:controller] = path_params[:controller].force_encoding("UTF-8")
      path_params[:action] = path_params[:action].force_encoding("UTF-8")

      @req.env.merge(ActionDispatch::Http::Parameters::PARAMETERS_KEY => path_params)
      @req.env["action_dispatch.request.parameters"] = @req.parameters.merge(@params)
      @req.tap { |r| r.session.send :load! }
    end
  end
end
