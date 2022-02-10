json.extract! work, :id, :date, :title, :description
json.scope do
  json.id work.scope.attributes[:id]
  json.value work.scope.attributes[:value]
end
json.creator do
  json.extract! work.creator, :id, :name, :date_of_birth
end
json.image_urls work.image_urls
