json.extract! comment, :id, :message
json.user do
  json.id comment.user&.id
  json.name comment.user&.name
  json.avatar_url comment.user&.avatar_url
end
json.edit_permission comment.edit_permission_check(@current_user_id)
