json.success true
json.comments do
  json.array! @comments, partial: 'api/v1/work_comments/comment', as: :comment
end
json.pagination @pagination
