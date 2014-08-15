module Calculable::ActiveRecord::Base
  module ClassMethods
    def calculable_attr(attrs, &block)
      relation = block ? lambda(&block) : attrs.delete(:from)
      raise "CALCULABLE: Relation was missed." unless relation
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end