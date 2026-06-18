class Transaction
  class FieldText < Field
    def value=(data)
      self.value_text = data
    end

    def to_s
      value_text
    end
  end
end
