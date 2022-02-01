10.times do |n|
  name = "user#{n}"
  email = "#{name}@example.com"
  user = User.find_or_initialize_by(email: email, activated: true)

  if user.new_record?
    user.name = name
    user.password = "password"
    user.save!
  end
end

# 非アクティベイトユーザー
not_activated_user = User.new(
  name: 'not_activated_user',
  email: 'not_activated_user@example.com',
  password: 'password'
)
not_activated_user.save!

puts "users = #{User.count}"