class Scope < ActiveHash::Base
  self.data = [
    { id: 1, value: '夫婦のみ',   targets: [1, 2] },
    { id: 2, value: '祖父母まで', targets: [1, 2, 3, 4, 5] },
    { id: 3, value: '招待者全員', targets: [1, 2, 3, 4, 5, 6, 7, 8] },
    { id: 4, value: '一般公開' }
  ]

  include ActiveHash::Associations
  has_many :works
end
