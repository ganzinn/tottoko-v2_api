json.success true
json.creators do
  json.array! @my_creators, partial: 'api/v1/creators/creator', as: :creator
end
