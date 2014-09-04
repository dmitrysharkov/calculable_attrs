module CalculableAttrs
  module Utils; end
end

require 'calculable_attrs/active_record'
require 'calculable_attrs/calculator'
require 'calculable_attrs/model_calculable_attrs_scope'
require 'calculable_attrs/utils/sql_parser'

::ActiveRecord::Base.include(CalculableAttrs::ActiveRecord::Base)
::ActiveRecord::Relation.include(CalculableAttrs::ActiveRecord::Relation)
::ActiveRecord::Base.extend(CalculableAttrs::ActiveRecord::Querying)
