require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'ユーザー新規作成' do
    before do
      @user = FactoryBot.build(:user)
    end

    it '全ての項目が存在すれば登録できること' do
      expect(@user).to be_valid
    end
  end
end
