module CalculableAttrs::ActiveRecord::Relation
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
        append_calculable_attrs
        @records
      end
    end
  end

  private

  def append_calculable_attrs
    unless calculate_attrs_values.empty?
      models_calculable_scopes= {}
      collect_models_calculable_attrs(models_calculable_scopes, klass, calculate_attrs_values)
      models_calculable_scopes = models_calculable_scopes.select { |model, scope| scope.has_attrs }
      collect_models_ids(models_calculable_scopes, @records, calculate_attrs_values)
      models_calculable_scopes.each { |model, sope| sope.calculate }
      put_calcaulated_values(models_calculable_scopes, @records, calculate_attrs_values)
    end

    @records
  end

  def collect_models_calculable_attrs(models_calculable_scopes, klass, attrs_to_calcualte)
    attrs_to_calcualte = [attrs_to_calcualte] unless attrs_to_calcualte.is_a?(Array)
    scope = (models_calculable_scopes[klass] ||= CalculableAttrs::ModelCalculableAttrsScope.new(klass))
    attrs_to_calcualte.each do |attrs_to_calcualte_item|

      case attrs_to_calcualte_item
      when Symbol
        if klass.reflect_on_association(attrs_to_calcualte_item)
          collect_association_calculable_attrs(models_calculable_scopes, klass, attrs_to_calcualte_item, true)
        else
          scope.add_attr(attrs_to_calcualte_item)
        end
      when true
        scope.add_all_attrs
      when Hash
        attrs_to_calcualte_item.each do |association_name, association_attrs_to_calcualte|
          collect_association_calculable_attrs(models_calculable_scopes, klass, association_name, association_attrs_to_calcualte)
        end
      end
    end
  end

  def collect_association_calculable_attrs(models_calculable_scopes, klass, assocaition_name, association_attrs_to_calcualte)
    assocaition = klass.reflect_on_association(assocaition_name)
    if assocaition
      collect_models_calculable_attrs(models_calculable_scopes, assocaition.klass, association_attrs_to_calcualte)
    else
      p "CALCUALBLE_ATTRS: WAINING: Model #{ klass.name } does't have association attribute #{ assocaition_name }."
    end
  end

  def collect_models_ids(models_calculable_scopes, records, attrs_to_calculate)
    itereate_scoped_records_recursively(models_calculable_scopes, records, attrs_to_calculate) do |scope, record|
      scope.add_id(record.id)
    end
  end


  def put_calcaulated_values(models_calculable_scopes, records, attrs_to_calculate)
    itereate_scoped_records_recursively(models_calculable_scopes, records, attrs_to_calculate) do |scope, record|
      record.calculable_attrs_values = scope.calcualted_attrs_values(record.id)
    end
  end

  def itereate_scoped_records_recursively(models_calculable_scopes, records, attrs_to_calculate, &block)
    itereate_records_recursively(records, attrs_to_calculate) do |record|
      scope = models_calculable_scopes[record.class]
      block.call(scope, record) if scope
    end
  end

  def itereate_records_recursively(records, attrs_to_calculate, &block)
    attrs_to_calcualte = [attrs_to_calcualte] unless attrs_to_calcualte.is_a?(Array)
    records = [records] unless records.is_a?(Array)

    records.each do |record|
      block.call(record)

      attrs_to_calculate.select {|item| item.is_a?(Hash)}.each do |hash|
        hash.each do |assocaition_name, assocaition_attributes|
          if record.respond_to?(assocaition_name)
            associated_records = record.send(assocaition_name)
            associated_records = associated_records.respond_to?(:to_a) ? associated_records.to_a : associated_records
            itereate_records_recursively(associated_records, attrs_to_calculate, &block)
          end
        end
      end
    end
  end
end