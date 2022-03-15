json.success true
json.creator do
  json.extract! @creator, :id, :name, :date_of_birth
  json.age @creator.age
  json.original_avatar_url @creator.original_avatar_url
  # json.partial! 'api/v1/creators/creator', creator: @creator
  json.edit_permission @family.creator_edit_permission_check
end
json.users do
  json.array! @creator_families do |creator_family|
    json.id creator_family.user.id
    json.name creator_family.user.name
    json.family do
      json.id creator_family.id
      json.relation do
        json.id creator_family.relation.id
        json.value creator_family.relation.value
      end
      json.family_remove_permission @family.family_remove_permission_check(creator_family)
    end
    
  end
end
