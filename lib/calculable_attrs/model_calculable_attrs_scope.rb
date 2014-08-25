class CalculableAttrs::ModelCalculableAttrsScope
  attr_reader :model, :ids, :attrs

  def initialize(model)
    @model = model
    @attrs = []
    @ids = []
  end

  def add_attr(attribute)
    attribute = attribute.to_sym
    @attrs.push(attribute) unless @attrs.include?(attribute)
  end

  def add_all_attrs
    @attrs = model.calculable_attrs
  end

  def has_attrs
    @attrs.size > 0
  end

  def add_id(id)
    @ids.push(id.to_i)
  end

  def calculate
    @calculable_attrs_values = nil
    calculators_to_use.each do |calculator|
      calculated_values = calculator.calculate_many(calculator.attrs & @attrs, ids)
      merge_calculated_values(calculated_values)
    end
  end

  def calculated_attrs_values(id)
    @calculable_attrs_values[id.to_i]
  end


  private

  def merge_calculated_values(calculated_values)
    if @calculable_attrs_values
      calculated_values.each {|id, values| @calculable_attrs_values[id].merge!(calculated_values[id]) }
    else
      @calculable_attrs_values = calculated_values
    end
  end

  def calculators_to_use
    calculators_to_use = []
    @attrs.each do |attribute|
      calculator = @model.calculable_attrs_calculators[attribute]
      calculators_to_use.push(calculator) unless calculators_to_use.include?(calculator)
    end
    calculators_to_use
  end
end
