class Transaction
  class FieldEmail < Field
    validates :value_text, format: {
      with: RFC822::EMAIL
    }

    def value=(data)
      self.value_text = data
    end

    def to_s
      value_text
    end
  end
end
