class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # text length
    max = 255
    record.errors.add(attribute, :too_long, count: max) if value.length > max

    # format
    format = Regexp.new( '\A[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~\-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\z' )
    record.errors.add(attribute, :format_invalid) unless format =~ value

    # uniqueness
    record.errors.add(attribute, :taken) if record.email_activated?
  end
end