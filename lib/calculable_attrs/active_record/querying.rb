module CalculableAttrs::ActiveRecord::Querying
   delegate :calculate_attrs, :includes_calculable_attrs, :joins_calculable_attrs,  to: :all
end
