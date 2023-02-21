# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "mocha"
require "rails"
require "active_model"
require "active_record"
require "action_controller"
require "minitest/mock"
require "pry"

require_relative "../lib/stimulus_reflex"

class TestApp < Rails::Application
  routes.draw { root to: "test#index" }
end

class ApplicationController < ActionController::Base; end

class TestController < ApplicationController
  include Rails.application.routes.url_helpers

  def index
    head :ok
  end
end

class SessionMock
  def enabled?
  end

  def load!
    nil
  end
end

class ActionDispatch::Request
  def session
    @session ||= SessionMock.new
  end
end

class TestModel
  include ActiveModel::Model
  attr_accessor :id
  def is_a?(klass)
    klass == ActiveRecord::Base
  end

  def to_gid_param
    "xxxyyyzzz"
  end
end

module ActionCable
  module Channel
    class ConnectionStub
      def connection_identifier
        connection_gid identifiers.map { |id| send(id.to_sym) if id }.compact
      end

      def connection_gid(ids)
        ids.map { |o| o.respond_to?(:to_gid_param) ? o.to_gid_param : o.to_s }.sort.join(":")
      end
    end
  end
end

def assert_broadcast_on(stream, data, &block)
  serialized_msg = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(data))

  new_messages = broadcasts(stream)
  if block
    old_messages = new_messages
    clear_messages(stream)

    yield
    new_messages = broadcasts(stream)
    clear_messages(stream)

    (old_messages + new_messages).each { |m| pubsub_adapter.broadcast(stream, m) }
  end

  message = new_messages.find { |msg| ActiveSupport::JSON.decode(msg) == serialized_msg }

  unless message
    puts "\n\nActual: #{ActiveSupport::JSON.decode(new_messages.first)}\n\nExpected: #{data}\n\n"
  end

  assert message, "No messages sent with #{data} to #{stream}"
end

StimulusReflex.configuration.parent_channel = "ActionCable::Channel::Base"
ActionCable::Server::Base.config.cable = {adapter: "test"}
ActionCable::Server::Base.config.logger = Logger.new(nil)

require_relative "../app/channels/stimulus_reflex/channel"
