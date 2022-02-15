json.success true
json.work do
  json.extract! @work, :id, :date, :title, :description
  json.scope do
    json.id @work.scope.attributes[:id]
    json.value @work.scope.attributes[:value]
  end
  json.creator do
    json.extract! @work.creator, :id, :name, :date_of_birth
  end
  json.detail_image_urls @work.detail_image_urls
  json.edit_permission (@family.present? && @family.work_edit_permission_check)
  json.tags @work.tags.pluck(:name)
end
