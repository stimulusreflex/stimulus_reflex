module StimulusReflex
  module Service
    class ReflexInvoker
      attr_reader :data
      attr_reader :transport_adapter

      def initialize(data, transport_adapter)
        @data = data
        @transport_adapter = transport_adapter
      end

      def call
        url = data["url"].to_s
        selectors = (data["selectors"] || []).select(&:present?)
        selectors = data["selectors"] = ["body"] if selectors.blank?
        target = data["target"].to_s
        reflex_name, method_name = target.split("#")
        reflex_name = reflex_name.classify
        arguments = data["args"] || []
        element = StimulusReflex::Element.new(data["attrs"])

        begin
          reflex_class = reflex_name.constantize
          raise ArgumentError.new("#{reflex_name} is not a StimulusReflex::Reflex") unless is_reflex?(reflex_class)
          reflex = reflex_class.new(transport_adapter, url: url, element: element, selectors: selectors, method_name: method_name)
          delegate_call_to_reflex reflex, method_name, arguments
        rescue => invoke_error
          reflex.rescue_with_handler(invoke_error)
          message = exception_message_with_backtrace(invoke_error)
          return transport_adapter.transmit_errors("StimulusReflex::Channel Failed to invoke #{target}! #{url} #{message}", data)
        end

        begin
          render_page_and_transmit_morph reflex, selectors, data unless reflex.halted?
        rescue => render_error
          reflex.rescue_with_handler(render_error)
          message = exception_message_with_backtrace(render_error)
          transport_adapter.transmit_errors "StimulusReflex::Channel Failed to re-render #{url} #{message}", data
        end
      end

      private

      def is_reflex?(reflex_class)
        reflex_class.ancestors.include? StimulusReflex::Reflex
      end

      def delegate_call_to_reflex(reflex, method_name, arguments = [])
        method = reflex.method(method_name)
        required_params = method.parameters.select { |(kind, _)| kind == :req }
        optional_params = method.parameters.select { |(kind, _)| kind == :opt }

        if arguments.size == 0 && required_params.size == 0
          reflex.process(method_name)
        elsif arguments.size >= required_params.size && arguments.size <= required_params.size + optional_params.size
          reflex.process(method_name, *arguments)
        else
          raise ArgumentError.new("wrong number of arguments (given #{arguments.inspect}, expected #{required_params.inspect}, optional #{optional_params.inspect})")
        end
      end

      def render_page_and_transmit_morph(reflex, selectors, data = {})
        html = render_page(reflex)
        transport_adapter.transmit_morphs selectors, data, html if html.present?
      end

      def render_page(reflex)
        controller = reflex.request.controller_class.new
        controller.instance_variable_set :"@stimulus_reflex", true
        reflex.instance_variables.each do |name|
          controller.instance_variable_set name, reflex.instance_variable_get(name)
        end

        controller.request = reflex.request
        controller.response = ActionDispatch::Response.new
        controller.process reflex.url_params[:action]
        commit_session reflex.request, controller.response
        controller.response.body
      end

      def commit_session(request, response)
        store = request.session.instance_variable_get("@by")
        store.commit_session request, response
      rescue => e
        message = "Failed to commit session! #{exception_message_with_backtrace(e)}"
        Rails.logger.error "\e[31m#{message}\e[0m"
      end

      def exception_message_with_backtrace(exception)
        "#{exception} #{exception.backtrace.first}"
      end
    end
  end
end
