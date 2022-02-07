class Relation < ActiveHash::Base
  self.data = [
    { id: 1, value: 'パパ' },
    { id: 2, value: 'ママ' },
    { id: 3, value: '子ども自身' },
    { id: 4, value: 'おじいちゃん' },
    { id: 5, value: 'おばあちゃん' },
    { id: 6, value: '親族' },
    { id: 7, value: '友人' },
    { id: 8, value: 'その他' }
  ]

  include ActiveHash::Associations
  has_many :families
end
