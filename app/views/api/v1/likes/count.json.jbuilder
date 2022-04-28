json.success true
json.like do
  json.count @likes.size
  json.already_like @already_like
end
