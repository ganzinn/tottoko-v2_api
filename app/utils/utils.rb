module Utils
  class << self
    def extract_when_one(array)
      return array.first if array.one?
      array
    end
  end
end