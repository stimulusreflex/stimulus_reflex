# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "minitest/mock"
require "rails"
require "active_model"
require "action_controller"
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
  def load!
    nil
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

class ActionDispatch::Request
  def session
    @session ||= SessionMock.new
  end
end

class TestModel
  include ActiveModel::Model
  attr_accessor :id
end

StimulusReflex.configuration.parent_channel = "ActionCable::Channel::Base"
ActionCable::Server::Base.config.cable = {adapter: "test"}
ActionCable::Server::Base.config.logger = Logger.new(nil)

require_relative "../app/channels/stimulus_reflex/channel"
