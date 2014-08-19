module Calculable::ActiveRecord::Base
  module ClassMethods
    def calculable_attr(attrs, &block)
      relation = block ? lambda(&block) : attrs.delete(:from)
      raise "CALCULABLE: Relation was missed." unless relation

      foreign_key = attrs.delete(:foreign_key) || "#{ name.tableize }.id"
      raise "CALCULABLE: At least one calculable attribute required." if attrs.empty?

      calculator = Calculable::Calculator.new(foreign_key: foreign_key, relation: relation, attributes: attrs)

      attrs.keys.each do |k|
        calculable_attrs_calculators[k.to_sym] = calculator
        class_eval <<-ruby
          def #{ k }
            calculable_attr_value(:#{ k })
          end
        ruby
      end
    end

    def calculable_attrs_calculators
      @calculable_attrs_calculators ||= {}
    end

    def calculable_attrs
      calculable_attrs_calculators.keys
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def calculable_attr_value(name)
    name = name.to_sym
    check_calculable_attr_name!(name)
    unless calculable_attrs_calculated_flags[name]
      recalc_calculable_attr_with_siblings(name)
    end
    calculable_attrs_values[name]
  end

  def set_calculable_attr_value(name, value)
    name = name.to_sym
    check_calculable_attr_name!(name)
    calculable_attrs_calculated_flags[name] = true
    calculable_attrs_values[name] = value
  end

  def calculable_attrs_values
    @calculable_attrs_values ||= {}
  end

  def calculable_attrs_values=(values)
    values.each { |key, value| set_calculable_attr_value(key, value) }
  end

  def recalc_calculable_attr_with_siblings(name)
    name = name.to_sym
    check_calculable_attr_name!(name)
    calculator = self.class.calculable_attrs_calculators[name]
    self.calculable_attrs_values = calculator.calculate_all(id)
  end

  private

  def calculable_attrs_calculated_flags
    @calculable_attrs_calculated_flags ||= {}
  end

  def check_calculable_attr_name!(name)
    unless self.class.calculable_attrs_calculators[name.to_sym]
      raise "CALCULABLE:  Unknown calculable attribute  #{ name } for model #{ self.class.name }"
    end
  end
end