require 'rails_helper'

describe Calculable::ActiveRecord::Relation do
  describe '#calculate_attrs' do
    context 'method exists' do
      subject { Account.all }
      it { is_expected.to respond_to :calculate_attrs }
    end

    context 'method works in proper way' do
      before do
        3.times { |i| create(:account, tr_count: 10, tr_amount: 10 * (i + 1)) }
        Account.calculable_attr(balance: 'SUM(amount)'){ Transaction.joins(:account).all }
      end

      subject { Account.all.calculate_attrs(:balance) }

      it { expect(subject.map(&:balance).sort).to eq [100, 200, 300] }
      it { expect(subject.load).to be_executed_sqls(2) }
    end

  end
end