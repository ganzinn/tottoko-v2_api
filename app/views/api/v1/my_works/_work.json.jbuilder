json.extract! work, :id, :date, :title
json.creator do
  json.extract! work.creator, :id, :name, :date_of_birth
end
json.index_image_url work.index_image_url
json.tags work.tags.pluck(:name)
