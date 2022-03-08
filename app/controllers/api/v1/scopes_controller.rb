class Api::V1::ScopesController < ApplicationController

  def index
    selections = Scope.all.as_json.map{|selection|
      {id: selection["attributes"]["id"], value: selection["attributes"]["value"]}
    }
    render status: 200, json: { success: true, options: selections}
  end

end
