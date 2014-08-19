module Calculable; end

require 'calculable_attrs/active_record'
require 'calculable_attrs/calculator'
require 'calculable_attrs/model_calculable_attrs_scope'

::ActiveRecord::Base.include(CalculableAttrs::ActiveRecord::Base)
::ActiveRecord::Relation.include(CalculableAttrs::ActiveRecord::Relation)
