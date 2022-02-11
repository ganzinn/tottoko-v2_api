FactoryBot.define do
  factory :work do
    date { "2022-02-08" }
    title { "MyString" }
    description { "MyText" }
    scope_id { 1 }
    creator { nil }
  end
end
