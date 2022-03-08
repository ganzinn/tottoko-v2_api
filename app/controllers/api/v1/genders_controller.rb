class Api::V1::GendersController < ApplicationController

  def index
    selections = Gender.all.as_json.map{|selection| selection["attributes"]}
    render status: 200, json: { success: true, options: selections}
  end

end
