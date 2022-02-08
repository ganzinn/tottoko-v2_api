json.success true
json.creator do
  json.partial! 'api/v1/creators/creator', creator: @creator
  json.edit_permission @family.creator_edit_permission_check
end
json.users do
  json.array! @creator_families do |creator_family|
    json.user_id creator_family.user.id
    json.user_name creator_family.user.name
    json.relation creator_family.relation.value
    json.remove_family_permission @family.remove_family_permission_check(creator_family)
  end
end
