FactoryBot.define do
  factory :user do
    name { "testuser" }
    email { "aaa@abc.com" }
    password { "password" }
    password_confirmation { "password" }
    activated { false }
    admin { false }
  end
end
