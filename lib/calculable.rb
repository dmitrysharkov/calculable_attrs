module Calculable
end

require 'calculable/active_record'

::ActiveRecord::Base.include(Calculable::ActiveRecord::Base)
