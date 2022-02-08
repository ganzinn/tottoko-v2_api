class DateFormatValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.class.ancestors.include?(ApplicationRecord)
      value = record.send("#{attribute}_before_type_cast")
    end
    begin
      if value.present?
        format = Regexp.new( '\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z' )
        unless format =~ value
          record.errors.add(attribute, :format_invalid)
        else
          Date.parse value
        end
      else
        record.errors.add(attribute, :blank)
      end
    rescue ArgumentError
      record.errors.add(attribute, :format_invalid)
    end
  end
end
