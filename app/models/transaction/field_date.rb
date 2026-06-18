class Transaction
  class FieldDate < Field
    def value=(data)
      self.value_date = if data.is_a?(String)
        DateTime.strptime(data, '%m/%d/%Y')
      else
        self.value_date = data
      end
    end

    def to_s
      I18n.l(value_date, format: '%m/%d/%Y')
    end
  end
end
