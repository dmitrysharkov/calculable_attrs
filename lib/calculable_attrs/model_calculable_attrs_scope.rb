class CalculableAttrs::ModelCalculableAttrsScope
  attr_reader :model, :ids, :attrs

  def initialize(model)
    @model = model
    @attrs = []
    @ids = []
  end

  def add_attr(attrribute)
    attrribute = attrribute.to_sym
    @attrs.push(attrribute) unless @attrs.include?(attrribute)
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
    calculators_to_use.each do |calulator|
      calcualted_values = calulator.calculate_many(attrs | @attrs, ids)
      merge_calculated_values(calcualted_values)
    end
  end

  def calcualted_attrs_values(id)
    @calculable_attrs_values[id.to_i]
  end


  private

  def merge_calculated_values(calcualted_values)
    if @calculable_attrs_values
      calcualted_values.each {|id,values| @calculable_attrs_values[id].merge!(calcualted_values[id]) }
    else
      @calculable_attrs_values = calcualted_values
    end
  end

  def calculators_to_use
    calculators_to_use = []
    @attrs.each do |attribute|
      calulator = @model.calculable_attrs_calculators[attribute]
      calculators_to_use.push(calulator) unless calculators_to_use.include?(calulator)
    end
    calculators_to_use
  end
end