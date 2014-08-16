module Calculable; end

require 'calculable/active_record'
require 'calculable/calculator'

::ActiveRecord::Base.include(Calculable::ActiveRecord::Base)
::ActiveRecord::Relation.include(Calculable::ActiveRecord::Relation)
