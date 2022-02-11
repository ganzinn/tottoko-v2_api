json.success true
json.works do
  json.array! @my_works, partial: 'api/v1/my_works/work', as: :work
end
json.pagination @pagination
