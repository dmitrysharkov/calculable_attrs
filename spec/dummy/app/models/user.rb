class User < ActiveRecord::Base
  has_many :accounts
end
