# frozen_string_literal: true

module StimulusReflex
  class Instrumentation
    def self.track(reflex)
      return yield unless reflex.logger && StimulusReflex.config.instrument_reflexes

      events = []
      start_allocations = current_allocations

      total_time = Benchmark.ms do
        ActiveSupport::Notifications.subscribed(proc { |event| events << event }, /^sql.active|reflex.render|reflex.sql_render/) do
          yield
        end
      end

      end_allocations = current_allocations
      sql, rendering = events.partition { |e| e.name.match?(/^sql/) }

      reflex.logger.info "Processed #{reflex.class.name}##{reflex.method_name} in #{total_time.round(1)}ms " \
                           "(Views: #{views_total(rendering).round(1)}ms | " \
                           "ActiveRecord: #{sql.sum(&:duration).round(1)}ms | " \
                           "Allocations: #{end_allocations - start_allocations}) \n"
    end

    def self.instrument_render(reflex, event_name)
      return yield unless reflex.logger && StimulusReflex.config.instrument_reflexes

      callback = proc { |event| ActiveSupport::Notifications.instrument("reflex.sql_render", {sql_duration: event.duration}) }

      ActiveSupport::Notifications.instrument(event_name) do
        ActiveSupport::Notifications.subscribed(callback, /^sql.active/) do
          yield
        end
      end
    end

    def self.views_total(events)
      rendering, querying = events.partition { |event| event.name.match?(/^reflex.render/) }
      rendering.sum(&:duration) - querying.sum { |event| event.payload[:sql_duration] }
    end

    def self.current_allocations
      GC.stat.key?(:total_allocated_objects) ? GC.stat(:total_allocated_objects) : 0
    end
  end
end
