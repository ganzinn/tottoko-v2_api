class Api::HealthCheckController < ApplicationController
  def index
    render status: 200, json: {success: true }
  end
end