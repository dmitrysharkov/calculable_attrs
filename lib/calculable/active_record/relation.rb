module Calculable::ActiveRecord::Relation
  def calculate_attrs(*attrs)
    spawn.calculate_attrs!(*attrs)
  end

  def calculate_attrs!(*attrs)
    attrs.reject!(&:blank?)
    attrs.flatten!

    attrs = [true] if attrs.empty?

    self.calculate_attrs_values |= attrs
    self
  end

  def calculate_attrs_values
    @values[:calculate_attrs] || []
  end

  def calculate_attrs_values=(values)
    raise ImmutableRelation if @loaded
    #check_cached_relation
    @values[:calculate_attrs] = values
  end


  def self.included(base)
    base.class_eval do
      alias_method :calculable_orig_exec_queries, :exec_queries
      def exec_queries
        calculable_orig_exec_queries
        calculable_calculate_attrs
        @records
      end
    end
  end

  private

  def calculable_calculate_attrs
    attrs_to_calcualte  = build_attrs_to_calcualte

    ids = @records.map(&:id) unless attrs_to_calcualte.empty?

    attrs_to_calcualte.each do |calc, attrs|
      values = calc.calculate(attrs, ids)
      @records.each { |r| r.calculable_attrs_values = values[r.id] }
    end
    @records
  end

  def build_attrs_to_calcualte
    if calculate_attrs_values.size == 1 && calculate_attrs_values[0] == true
      attrs = klass.calculable_attrs
    else
      attrs = calculate_attrs_values.map(&:to_sym)
    end
    build_attrs_to_calculate_for_class(klass, attrs)
  end

  def build_attrs_to_calculate_for_class(cls, attrs)
    attrs_to_calculate = {}
    attrs.each do |a|
      calculator = cls.calculable_attrs_calculators[a]
      if calculator
        attrs_to_calculate[calculator] = (attrs_to_calculate[calculator] || []) | [a]
      else
        p "DYNAT WAINING: Model #{ klass.name } does't have dynamic attribute #{ a }. Probably you have to define it."
      end
    end
    attrs_to_calculate
  end
end