class Transaction
  class FieldCheckbox < Field
    def value=(data)
      self.value_checkbox = data
    end

    def to_s
      value_checkbox ? 'Yes' : 'No'
    end
  end
end
