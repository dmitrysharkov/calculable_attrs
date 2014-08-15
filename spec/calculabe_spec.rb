require 'spec_helper'

describe 'Calculable' do
  describe '#calcualble_attr' do

    it 'will allow define calculable attributes in model' do
      Account.calculable_attr(balance: 'SUM(amount)'){ Transaction.all }
    end

    it 'will allow define several attributes in model' do
      Account.calculable_attr balance: 'SUM(transactions.amount)', number_of_transactions: 'COUNT(transactions.*)' do |variable|
        Transaction.all
      end
    end

    it 'will allow define specific foreign key' do
      Account.calculable_attr balance: 'SUM(amount)', forign_key: 'transactions.account_id' do
        Transaction.all
      end
    end

    it 'will raise exception if no scope provided' do
      no_scope = proc do
        Account.calculable_attr balance: 'SUM(amount)'
      end
      expect(no_scope).to raise_error("CALCULABLE: Scope missed")
    end

    it 'will allow provide relation as relation: lambda' do
      Account.calculable_attr balance: 'SUM(amount)', relation: ->{ Transaction.all }
    end

  end
end