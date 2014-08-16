class Calculable::Calculator
  CALCULABLE_FOREIGN_KEY = '__calculable_id__'
  attr_reader :attrs

  def initialize(relation: nil, foreign_key: nil, attributes: nil)
    @relation = relation
    @foreign_key = foreign_key

    @attrs = []
    @formulas = {}

    attributes.each do |key, val|
      key = key.to_sym
      @formulas[key] = val
      @attrs << key
    end
  end

  def calculate(attrs, id)
    if(id.is_a?(Array))
      calculate_many(attrs, id)
    else
      calculate_one(attrs, id)
    end
  end

  def calculate_many(attrs, ids)
    query = base_query(attrs, ids).select("#{ @foreign_key } AS #{ CALCULABLE_FOREIGN_KEY }").group(@foreign_key)
    records = query.load
    noramlize_many_records_result(ids, attrs, records)
  end

  def calculate_one(attrs, id)
    record = base_query(attrs, id).load.first
    noramlize_one_record_result(attrs, record)
  end

  def calculate_all(id)
    calculate(attrs, id)
  end

  private

  def base_query(attrs, id)
    @relation.call.select(build_select(attrs)).where( @foreign_key => id)
  end

  def noramlize_many_records_result(ids, attrs, records)
    normalized = {}
    records.each do |row|
      id = row[CALCULABLE_FOREIGN_KEY].to_i
      normalized[id] = noramlize_one_record_result(attrs, row)
    end
    ids.each  do |id|
      normalized[id] ||= noramlize_one_record_result(attrs, nil)
    end
    normalized
  end

  def noramlize_one_record_result(attrs, record)
    attrs.map { |a| [a, record.try(a) || 0] }.to_h
  end


  def build_select(attrs)
    attrs.map { |a| "#{ @formulas[a] } AS #{ a }" }.join(', ')
  end
end