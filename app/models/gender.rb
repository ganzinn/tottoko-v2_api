class Gender < ActiveHash::Base
  self.data = [
    { id: 1, value: '男の子' },
    { id: 2, value: '女の子' },
    { id: 3, value: '指定なし' }
  ]

  include ActiveHash::Associations
  has_many :creators
end
