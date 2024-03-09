# frozen_string_literal: true

module StimulusReflex
  class Instrumentation
    def self.track(reflex)
      return yield unless reflex.logger && StimulusReflex.config.instrument_reflexes

      events = []

      time = Benchmark.realtime do
        ActiveSupport::Notifications.subscribed(Proc.new{ |event| events << event }, /^sql.active_record|^render/) do
          yield
        end
      end

      sql, views = events.partition { |e| e.name.match?(/^sql/) }

      reflex.logger.info "Processed #{reflex.class.name}##{reflex.method_name} in #{(time * 1000).round(1)}ms " +
                           "(Views: #{views.sum(&:duration).round(1)}ms | " +
                           "ActiveRecord: #{sql.sum(&:duration).round(1)}ms | " +
                           "Allocations: #{events.sum(&:allocations)}) \n"
    end
  end
end
