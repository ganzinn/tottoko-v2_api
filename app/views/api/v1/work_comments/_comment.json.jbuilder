json.extract! comment, :id, :message
json.user do
  json.id comment.user&.id
  json.name comment.user&.name
end
json.edit_permission comment.edit_permission_check(@current_user_id)
