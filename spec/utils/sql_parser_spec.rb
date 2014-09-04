require 'rails_helper'

describe CalculableAttrs::Utils::SqlParser do
  let(:parser) { CalculableAttrs::Utils::SqlParser.new(sql) }

  describe '#first_select_snippet' do
    subject { parser.first_select_snippet }


    [
      ['SELECT * FROM accounts', '*'],
      ['SELECT id, name, accounts.* FROM (SELECT * FROM transactions) accounts', 'id, name, accounts.*'],
      ['SELECT *, (SELECT MAX(amount) FROM transactions WHERE transaction.account_id=accounts.id) AS xxx FROM accounts', '*, (SELECT MAX(amount) FROM transactions WHERE transaction.account_id=accounts.id) AS xxx'],
      ["SELECT 'FROM' AS abc, accounts.* FROM accounts", "'FROM' AS abc, accounts.*"]
    ].each do |pair|
      context pair[0]  do
        let(:sql) { pair[0] }
        it { is_expected.to eq pair[1] }
      end
    end
  end

  describe '#last_where_snippet' do
    subject { parser.last_where_snippet }


    [
      [
        'SELECT * FROM accounts WHERE accounts.balance > 100',
       'accounts.balance > 100'
      ],
      [
        'SELECT id, name, accounts.* FROM (SELECT * FROM transactions WHERE transactions.id > 100) accounts WHERE (accounts.balance > 100) AND (account.id < \'ORDER\') ORDER BY id',
        '(accounts.balance > 100) AND (account.id < \'ORDER\')'
      ],
    ].each do |pair|
      context pair[0]  do
        let(:sql) { pair[0] }
        it { is_expected.to eq pair[1] }
      end
    end
  end

end