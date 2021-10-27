require 'rails_helper'

RSpec.describe User, type: :model do
  
  before do
    @user = FactoryBot.build(:user)
  end

  describe 'バリデーション' do
    describe 'ユーザー登録' do
      context 'ユーザ登録できる場合' do
        it '全ての項目が存在すれば登録できる' do
          expect{ @user.save }.to change{ User.count }.by(1)
        end
        it 'nameが30文字の場合、登録できる' do
          max = 30
          name = 'a' * max
          @user.name = name
          expect{ @user.save }.to change{ User.count }.by(1)
        end
        it 'emailが255文字の場合、登録できる' do
          max = 255
          domain = '@test.com'
          email = 'a' * (max - domain.length) + domain
          @user.email = email
          expect{ @user.save }.to change{ User.count }.by(1)
        end
        it 'emailが「aaa@a」のとき、登録できる' do
          @user.email = 'aaa@a'
          expect{ @user.save }.to change{ User.count }.by(1)
        end
        it "emailが「azAZ09.!#$%&'*+/=?^_`{|}~-@a」のとき、登録できる" do
          @user.email = "azAZ09.!#$%&'*+/=?^_`{|}~-@a"
          expect{ @user.save }.to change{ User.count }.by(1)
        end
        it '登録済みのユーザーとemailが同じであったとしても、そのユーザーのactivatedがfalseの場合、登録できる' do
          email = 'aaa@a.com'
          another_user = User.create(name: 'test1', email: email, password: 'password')
          user = User.new(name: 'test2', email: email, password: 'password')
          expect{ user.save }.to change{ User.count }.by(1)
        end
        it 'passwordが8文字のとき、登録できる' do
          user = User.new(name: 'test', email: 'a@a', password: '12345678')
          expect{ user.save }.to change{ User.count }.by(1)
        end
        it 'passwordが72文字のとき、登録できる' do
          max = 72
          password = 'a' * max
          user = User.new(name: 'test', email: 'a@a', password: password)
          expect{ user.save }.to change{ User.count }.by(1)
        end
        it 'passwordが「azAZ09_-」とき、登録できる' do
          user = User.new(name: 'test', email: 'a@a', password: 'azAZ09_-')
          expect{ user.save }.to change{ User.count }.by(1)
        end
        
      end
      context 'ユーザ登録できない場合' do
        # name
        it 'nameが空（nil）のとき、「名前を入力してください」のメッセージが出力される' do
          @user.name = nil
          @user.save
          expect(@user.errors.full_messages).to match(['名前を入力してください'])
        end
        it 'nameが空文字のとき、「名前を入力してください」のメッセージが出力される' do
          @user.name = ''
          @user.save
          expect(@user.errors.full_messages).to match(['名前を入力してください'])
        end
        it 'nameが空白のとき、「名前を入力してください」のメッセージが出力される' do
          @user.name = ' 　'
          @user.save
          expect(@user.errors.full_messages).to match(['名前を入力してください'])
        end
        it 'nameが30文字を超える場合、「名前は30文字以内で入力してください」のメッセージが出力される' do
          max = 30
          name = 'a' * (max + 1)
          @user.name = name
          @user.save
          expect(@user.errors.full_messages).to match(['名前は30文字以内で入力してください'])
        end
        it 'nameが空白文字で30文字を超える場合、文字数制限のバリデーションはスキップされ、「名前を入力してください」のメッセージのみ出力される' do
          max = 30
          name = ' ' * (max + 1)
          @user.name = name
          @user.save
          expect(@user.errors.full_messages).to match(['名前を入力してください'])
        end

        # email
        it 'emailが空（nil）のとき、「メールアドレスを入力してください」のメッセージが出力される' do
          @user.email = nil
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスを入力してください'])
        end
        it 'emailが空文字のとき、「メールアドレスを入力してください」のメッセージが出力される' do
          @user.email = ''
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスを入力してください'])
        end
        it 'emailが空白のとき、「メールアドレスを入力してください」のメッセージが出力される' do
          @user.email = ' 　'
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスを入力してください'])
        end
        it 'emailが255文字を超える場合、「メールアドレスは255文字以内で入力してください」のメッセージが出力される' do
          max = 255
          domain = '@test.com'
          email = 'a' * (max + 1 - domain.length) + domain
          @user.email = email
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスは255文字以内で入力してください'])
        end
        it 'emailの書式が不正（aaa）な場合、「メールアドレスの書式が不正です」のメッセージが出力される' do
          @user.email = 'aaa'
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスの書式が不正です'])
        end
        it 'emailの書式が不正（aaa@）な場合、「メールアドレスの書式が不正です」のメッセージが出力される' do
          @user.email = 'aaa@'
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスの書式が不正です'])
        end
        it 'emailの書式が不正（aaa@.a）な場合、「メールアドレスの書式が不正です」のメッセージが出力される' do
          @user.email = 'aaa@.a'
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスの書式が不正です'])
        end
        it 'emailの書式が不正（a"a@a）な場合、「メールアドレスの書式が不正です」のメッセージが出力される' do
          @user.email = 'a"a@a'
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスの書式が不正です'])
        end
        it 'emailの書式が不正（あああ@a）な場合、「メールアドレスの書式が不正です」のメッセージが出力される' do
          @user.email = 'あああ@a'
          @user.save
          expect(@user.errors.full_messages).to match(['メールアドレスの書式が不正です'])
        end
        it '登録済みのユーザーとemailが同じかつ、そのユーザーのactivatedがtrueの場合、「メールアドレスはすでに存在します」のメッセージが出力される' do
          email = 'aaa@a.com'
          another_user = User.create(name: 'test1', email: email, password: 'password', activated: true)
          user = User.create(name: 'test2', email: email, password: 'password')
          expect(user.errors.full_messages).to match(['メールアドレスはすでに存在します'])
        end

        # password
        # ※ 一度newでpasswordを設定（DB登録はなし）したあと、空文字に設定しなおしても上書きされないため、
        #    本番同様newの時点でpasswordに空文字を設定する。
        it 'passwordが空（指定なし）のとき、「パスワードを入力してください」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a')
          user.save
          expect(user.errors.full_messages).to match(['パスワードを入力してください'])
        end
        it 'passwordが空（nil）のとき、「パスワードを入力してください」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a', password: nil)
          user.save
          expect(user.errors.full_messages).to match(['パスワードを入力してください'])
        end
        it 'passwordが空文字のとき、「パスワードを入力してください」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a', password: '')
          user.save
          expect(user.errors.full_messages).to match(['パスワードを入力してください'])
        end
        it 'passwordが空白のとき、「パスワードを入力してください」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a', password: ' 　')
          user.save
          expect(user.errors.full_messages).to match(['パスワードを入力してください'])
        end
        it 'passwordが8文字未満のとき、「パスワードは8文字以上で入力してください」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a', password: '1234567')
          user.save
          expect(user.errors.full_messages).to match(['パスワードは8文字以上で入力してください'])
        end
        it 'passwordが72文字を超える場合、「パスワードは72文字以内で入力してください」のメッセージが出力される' do
          max = 72
          password = 'a' * ( max + 1 )
          user = User.new(name: 'test', email: 'a@a', password: password)
          user.save
          expect(user.errors.full_messages).to match(['パスワードは72文字以内で入力してください'])
        end
        it 'passwordが「1234567@」のとき、「パスワードの書式が不正です」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a', password: '1234567@')
          user.save
          expect(user.errors.full_messages).to match(['パスワードの書式が不正です'])
        end
        it 'passwordが「1234567あ」のとき、「パスワードの書式が不正です」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a', password: '1234567あ')
          user.save
          expect(user.errors.full_messages).to match(['パスワードの書式が不正です'])
        end
        it 'passwordとpassword_confirmationの値が異なるとき、「パスワード確認とパスワードの入力が一致しません」のメッセージが出力される' do
          user = User.new(name: 'test', email: 'a@a', password: 'a12345678', password_confirmation: 'b12345678')
          user.save
          expect(user.errors.full_messages).to match(['パスワード確認とパスワードの入力が一致しません'])
        end
      end
    end
    describe 'ユーザー更新' do
      context 'パスワードの入力状態により、他項目を更新できる場合' do
        it 'パスワードの入力が空（指定なし）の場合、名前を更新できる' do
          @user.activated = true
          @user.save
          user = User.find(@user.id)
          expect{ user.update(name: 'update_testuser') }.to change{ User.find(user.id).name }.from('testuser').to('update_testuser')
        end
        it 'パスワードの入力が空文字の場合、名前を更新できる' do
          @user.activated = true
          @user.save
          user = User.find(@user.id)
          expect{ user.update(name: 'update_testuser') }.to change{ User.find(user.id).name }.from('testuser').to('update_testuser')
        end
      end
      context 'パスワードの入力状態により、他項目を更新できない場合' do
        it 'パスワードの入力が空（nil）の場合、名前を更新できない' do
          @user.activated = true
          @user.save
          user = User.find(@user.id)
          user.update(name: 'update_testuser', password: nil)
          expect(user.errors.full_messages).to match(['パスワードを入力してください'])
        end
        it 'パスワードの入力が空白文字の場合、名前を更新できない' do
          @user.activated = true
          @user.save
          user = User.find(@user.id)
          user.update(name: 'update_testuser', password: ' 　')
          expect(user.errors.full_messages).to match(['パスワードを入力してください'])
        end
      end
    end
  end
  describe 'バリデーション前変換機能' do
    it 'emailが英文字の大文字（AAA@BBB.COM）で送信された場合、小文字（aaa@bbb.com）で登録されること' do
      email = 'AAA@BBB.COM'
      @user.email = email
      @user.save
      expect(User.find(@user.id).email).to match('aaa@bbb.com')
    end
  end
end
