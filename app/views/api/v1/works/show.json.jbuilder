json.success true
json.work do
  json.partial! 'api/v1/works/work', work: @work
  json.edit_permission (@family.present? && @family.work_edit_permission_check)
end
