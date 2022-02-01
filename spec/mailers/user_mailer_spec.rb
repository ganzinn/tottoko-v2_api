require "rails_helper"

RSpec.describe UserMailer, type: :mailer do

  ########################################################################
  ### 【新規ユーザー登録】アカウントアクティベイトトークン送付
  ########################################################################
  describe "【新規ユーザー登録】アカウントアクティベイトトークン送付" do
    before do
      @user = FactoryBot.build(:user)
      @user.save
      @mail = UserMailer.account_activation(@user)
    end
    it '件名、送信先、送信元が正しいこと' do
      aggregate_failures do
        expect(@mail.subject).to eq '【tottoko】アカウント有効化のご案内'
        expect(@mail.to).to eq [@user.email]
        expect(@mail.from).to eq ['noreply@example.com']
      end
    end
  end

  ########################################################################
  ### 【パスワード リセット エントリー】パスワードリセットトークン送付
  ########################################################################
  describe "【パスワード リセット エントリー】パスワードリセットトークン送付" do
    before do
      @user = FactoryBot.build(:user)
      @user.activated = true
      @user.save
      @mail = UserMailer.password_reset(@user)
    end
    it '件名、送信先、送信元が正しいこと' do
      aggregate_failures do
        expect(@mail.subject).to eq '【tottoko】パスワード再設定のご案内'
        expect(@mail.to).to eq [@user.email]
        expect(@mail.from).to eq ['noreply@example.com']
      end
    end
  end

  ########################################################################
  ### 【メールアドレス変更 エントリー】メールアドレス変更トークン送付
  ########################################################################
  describe "【メールアドレス変更 エントリー】メールアドレス変更トークン送付" do
    before do
      @user = FactoryBot.build(:user)
      @user.activated = true
      @user.save
      @user.email = 'changed_email@example.com'
      @mail = UserMailer.email_change(@user)
    end
    it '件名、送信先、送信元が正しいこと' do
      aggregate_failures do
        expect(@mail.subject).to eq '【tottoko】メールアドレス変更のご案内'
        expect(@mail.to).to eq [@user.email]
        expect(@mail.from).to eq ['noreply@example.com']
      end
    end
  end


  # describe "account_activation" do
  #   let(:mail) { UserMailer.account_activation }

  #   it "renders the headers" do
  #     expect(mail.subject).to eq("Account activation")
  #     expect(mail.to).to eq(["to@example.org"])
  #     expect(mail.from).to eq(["from@example.com"])
  #   end

  #   it "renders the body" do
  #     expect(mail.body.encoded).to match("Hi")
  #   end
  # end

end
