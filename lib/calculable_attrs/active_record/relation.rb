module CalculableAttrs::ActiveRecord::Relation
  def includes_calculable_attrs(*attrs)
    spawn.includes_calculable_attrs!(*attrs)
  end
  alias_method :calculate_attrs, :includes_calculable_attrs

  def includes_calculable_attrs!(*attrs)
    set_calculable_attrs_included(refine_calculable_attrs(attrs))
    self
  end
  alias_method :calculate_attrs!, :includes_calculable_attrs!

  def joins_calculable_attrs(*attrs)
    spawn.joins_calculable_attrs!(*attrs)
  end

  def joins_calculable_attrs!(*attrs)
    set_calculable_attrs_joined(refine_calculable_attrs(attrs))
    self
  end


  def self.included(base)
    base.class_eval do
      alias_method :calculable_orig_exec_queries, :exec_queries
      alias_method :calculable_orig_calculate, :calculate

      def exec_queries
        if calculable_attrs_joined.empty?
          calculable_orig_exec_queries
        else
          relation = CalculableAttrs::Prejoiner.new(self).wrap_with_calculable_joins
          @records = relation.send(:calculable_orig_exec_queries)
          @loaded = true
        end
        CalculableAttrs::Preloader.new(self).preload(@records)
      end

      def calculate(operation, column_name, options = {})
        if calculable_attrs_joined.empty?
          calculable_orig_calculate(operation,column_name,options)
        else
          relation = CalculableAttrs::Prejoiner.new(self).wrap_with_calculable_joins
          relation.calculable_orig_calculate(operation,column_name,options)
        end
      end
    end
  end

  def calculable_attrs_joined
    @values[:calculable_attrs_joined] || []
  end

  def calculable_attrs_included
    @values[:calculable_attrs_included] || []
  end

  private


  def refine_calculable_attrs(attrs)
    attrs.reject!(&:blank?)
    attrs.flatten!
    attrs = [true] if attrs.empty?
    attrs
  end


  def set_calculable_attrs_joined(values)
    raise ImmutableRelation if @loaded
    @values[:calculable_attrs_joined] = [] unless @values[:calculable_attrs_joined]
    @values[:calculable_attrs_joined] |= values
  end


  def set_calculable_attrs_included(values)
    raise ImmutableRelation if @loaded
    @values[:calculable_attrs_included] = [] unless @values[:calculable_attrs_included]
    @values[:calculable_attrs_included] |= values
  end


end
