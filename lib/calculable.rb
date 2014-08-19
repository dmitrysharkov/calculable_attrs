module Calculable; end

require 'calculable/active_record'
require 'calculable/calculator'
require 'calculable/model_calculable_attrs_scope'

::ActiveRecord::Base.include(Calculable::ActiveRecord::Base)
::ActiveRecord::Relation.include(Calculable::ActiveRecord::Relation)
