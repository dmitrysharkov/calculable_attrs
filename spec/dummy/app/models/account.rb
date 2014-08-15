class Account < ActiveRecord::Base
  has_many :transactions
end
