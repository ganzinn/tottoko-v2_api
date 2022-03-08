class Api::V1::RelationsController < ApplicationController

  def index
    selections = Relation.all.as_json.map{|selection| selection["attributes"]}
    if params[:purp] === 'creator_entry'
      # クリエーター登録時はパパ・ママ・子ども自身のみ選択可
      selections.filter!{|selection| [1,2,3].include?(selection["id"])}
    end
    render status: 200, json: { success: true, options: selections}
  end

end
