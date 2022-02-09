json.success true
json.works do
  json.array! @my_works, partial: 'api/v1/works/work', as: :work
end
