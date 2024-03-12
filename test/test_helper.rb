# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "rails"
require "active_model"
require "active_record"
require "action_controller"

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

class ApplicationReflex < StimulusReflex::Reflex
  def application_reflex
  end

  private

  def private_application_reflex
  end
end

class PostReflex < ApplicationReflex
  def post_reflex
  end

  private

  def private_post_reflex
  end
end

class NoReflex
  def no_reflex
  end
end

module CounterConcern
  def increment
  end
end

class CounterReflex < ApplicationReflex
  include CounterConcern
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

StimulusReflex.configuration.parent_channel = "ActionCable::Channel::Base"
ActionCable::Server::Base.config.cable = {adapter: "test"}
ActionCable::Server::Base.config.logger = Logger.new(nil)

require_relative "../app/channels/stimulus_reflex/channel"
