class CalculableAttrs::Calculator
  CALCULABLE_FOREIGN_KEY = '__calculable_id__'
  attr_reader :attrs, :relation, :foreign_key, :defaults

  def initialize(relation: nil, foreign_key: nil, attributes: nil)
    @relation = relation
    @foreign_key = foreign_key

    @attrs = []
    @formulas = {}
    @defaults = {}

    attributes.each do |key, val|
      key = key.to_sym
      save_attribute_value(key, val)
      @attrs << key
    end
  end

  def calculate(attrs, id)
    if id.is_a?(Array)
      calculate_many(attrs, id)
    else
      calculate_one(attrs, id)
    end
  end

  def calculable_foreign_key
    CALCULABLE_FOREIGN_KEY
  end

  def calculate_many(attrs, ids)
    query = query_with_grouping(attrs, ids)
    records = query.load
    normalize_many_records_result(ids, attrs, records)
  end

  def query_with_grouping(attrs, ids)
    base_query(attrs, ids).select("#{ @foreign_key } AS #{ calculable_foreign_key }").group(@foreign_key)
  end

  def calculate_one(attrs, id)
    record = base_query(attrs, id).load.first
    normalize_one_record_result(attrs, record)
  end

  def calculate_all(id)
    calculate(attrs, id)
  end

  def base_query(attrs, id)
    scoped_relation(id).select(build_select(attrs))
  end

  def scoped_relation(id)
    if id
      @relation.call.where( @foreign_key => id)
    else
      @relation.call
    end
  end

  def default(attr)
    @defaults.key?(attr) ? @defaults[attr] : 0
  end

  private

  def save_attribute_value(name, value)
    case value
    when String
      @formulas[name] = value
    when Array
      if value.size == 2
        @formulas[name] = value[0]
        @defaults[name] = value[1]
      else
        raise "CALCULABLE_ATTRS: Invalid attribute array for  #{ name }. Expected ['formula', default_value]"
      end
    else
      raise "CALCULABLE_ATTRS: Invalid attribute value for  #{ name }"
    end
  end


  def normalize_many_records_result(ids, attrs, records)
    normalized = {}
    records.each do |row|
      id = row[CALCULABLE_FOREIGN_KEY].to_i
      normalized[id] = normalize_one_record_result(attrs, row)
    end
    ids.each  do |id|
      normalized[id] ||= normalize_one_record_result(attrs, nil)
    end
    normalized
  end

  def normalize_one_record_result(attrs, record)
    attrs.map { |a| [a, record.try(a) || default(a)] }.to_h
  end


  def build_select(attrs)
    attrs.map { |a| "#{ @formulas[a] } AS #{ a }" }.join(', ')
  end
end
