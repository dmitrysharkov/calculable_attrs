class CalculableAttrs::Prejoiner
  JOINED_RELATION_NAME = 'calculated_attrs'

  def initialize(relation)
    @relation = relation.spawn
  end


  def wrap_with_calculable_joins
    klass = @relation.klass
    scope = CalculableAttrs::ModelCalculableAttrsScope.new(klass)
    scope.add_attrs(@relation.calculable_attrs_joined)

    original_sql = @relation.to_sql

    sql_parser = CalculableAttrs::Utils::SqlParser.new(original_sql)
    where_sql_snippet = sql_parser.last_where_snippet
    @relation.reset

    scope.calculators_to_use.each_with_index do |calcualtor, index|
      joined_relation_name = '__' + JOINED_RELATION_NAME + '_' + index.to_s + '__'

      attrs_to_calculate = scope.attrs && calcualtor.attrs
      left_join_sql = "LEFT JOIN ( #{ calcualtor.query_with_grouping(attrs_to_calculate, nil).to_sql })" +
        " AS #{ joined_relation_name }" +
        " ON #{ joined_relation_name }.#{ calcualtor.calculable_foreign_key } = #{ klass.table_name }.id"



      if where_sql_snippet
        table_name = klass.table_name.underscore
        attrs_to_calculate.each do |attr|
          original_names = [
            "#{ table_name }.#{ attr }",
            "\"#{ table_name }\".#{ attr }",
            "#{ table_name }.\"#{ attr }\"",
            "\"#{ table_name }\".\"#{ attr }\"",
          ]
          replacement_name = "#{ joined_relation_name }.#{ attr }"
          replacement = klass.send(:sanitize_sql, ["COALESCE(#{ replacement_name }, ?)", calcualtor.default(attr)])
          original_names.each { |original_name| where_sql_snippet.gsub!(original_name, replacement) }
        end
      end

      @relation.joins!(left_join_sql)

    end

    if where_sql_snippet
      @relation.where_values = nil
      @relation.where!(where_sql_snippet)
    end
    @relation
  end
end