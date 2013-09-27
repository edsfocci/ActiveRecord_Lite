class MassObject
  def self.set_attrs(*attributes)
    attributes.each do |attribute|
      attr_accessor attribute
    end

    @attributes = attributes

    nil
  end

  def self.attributes
    @attributes
  end

  def self.parse_all(results)
    results.map do |result|
      new(result)
    end
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        send("#{attr_name}=".to_sym, value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end
end
