class CalculableAttrs::Calculator
  CALCULABLE_FOREIGN_KEY = '__calculable_id__'
  attr_reader :attrs, :relation, :foreign_key

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

  def calculate_many(attrs, ids)
    query = base_query(attrs, ids).select("#{ @foreign_key } AS #{ CALCULABLE_FOREIGN_KEY }").group(@foreign_key)
    records = query.load
    normalize_many_records_result(ids, attrs, records)
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
    @relation.call.where( @foreign_key => id)
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
    attrs.map { |a| [a, record.try(a) || ( @defaults.key?(a) ? @defaults[a] : 0)] }.to_h
  end


  def build_select(attrs)
    attrs.map { |a| "#{ @formulas[a] } AS #{ a }" }.join(', ')
  end
end
