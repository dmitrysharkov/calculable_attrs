require 'rails_helper'

describe Calculable::ActiveRecord::Relation do
  describe '#calculate_attrs' do
    context 'method exists' do
      subject { Account.all }
      it { is_expected.to respond_to :calculate_attrs }
    end

    describe 'without subordinately objects' do
      before do
        3.times { |i| create(:account, tr_count: 10 * (i + 1), tr_amount: 10) }
        Account.calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)') { Transaction.joins(:account).all }
      end

      shared_examples 'balance attribute works in proper way' do
        it { expect(subject.map(&:balance).sort).to eq [100, 200, 300] }
        it { expect(lambda { subject.load }).to be_executed_sqls(2) }
      end

      shared_examples 'balance and  number_of_transactions attributes in proper way' do
        it_behaves_like 'balance attribute works in proper way'
        it { expect(subject.map(&:number_of_transactions).sort).to eq [10, 20, 30] }
      end

      context 'one attribute' do
        subject { Account.all.calculate_attrs(:balance) }
        it_behaves_like  'balance attribute works in proper way'
      end

      context 'two attributes' do
        subject { Account.all.calculate_attrs(:balance, :number_of_transactions) }
        it_behaves_like 'balance and  number_of_transactions attributes in proper way'
      end

      context 'true as parameter' do
        subject { Account.all.calculate_attrs(true) }
        it_behaves_like 'balance and  number_of_transactions attributes in proper way'
      end

      context 'no parameters' do
        subject { Account.all.calculate_attrs }
        it_behaves_like 'balance and  number_of_transactions attributes in proper way'
      end
    end

    describe 'with subordinately objects' do
      before do
        3.times do |ui|
          user = create(:user)
          3.times { |i| create(:account, user: user, tr_count: 10 * (i + 1), tr_amount: 10 ** (ui + 1)) }
        end
        Account.calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)') { Transaction.joins(:account).all }
        User.calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)', foreign_key: 'accounts.user_id') { Transaction.joins(:account).all }
      end

      context 'when has many' do
        context 'one attribute' do
          subject { User.includes(:accounts).calculate_attrs(accounts: :balance).order(:id).to_a.map {|user| user.accounts.map(&:balance).sort } }
          it { is_expected.to eq [[100, 200, 300], [1000, 2000, 3000], [10000, 20000, 30000]] }
          it { expect(lambda { subject }).to be_executed_sqls(3) }
        end

        context 'two attributes' do
          subject {
            User.includes(:accounts).calculate_attrs(accounts: [:balance, :number_of_transactions])
              .order(:id).to_a.map {|user| user.accounts.map { |acc| [acc.balance, acc.number_of_transactions] }.sort }
          }
          it { is_expected.to eq [[[100,10], [200,20], [300,30]], [[1000, 10], [2000,20], [3000,30]], [[10000,10], [20000,20], [30000,30]]] }
          it { expect(lambda { subject }).to be_executed_sqls(3) }
        end
      end

      context 'when belongs to' do
        context 'one attribute' do
          subject { Account.includes(:user).calculate_attrs(user: :balance).order(:user_id).map {|acc| acc.user.balance}.sort }
          it { is_expected.to eq [600, 600, 600, 6000, 6000, 6000, 60000, 60000, 60000] }
          it { expect(lambda { subject }).to be_executed_sqls(3) }
        end

        context 'two attributes' do
          subject {
            Account.includes(:user).calculate_attrs(user: [:balance, :number_of_transactions]).order(:user_id)
             .to_a.map {|acc| [acc.user.balance, acc.user.number_of_transactions] }
          }
          it { is_expected.to eq [[600,60], [600,60], [600,60], [6000, 60], [6000,60], [6000,60], [60000,60], [60000,60], [60000,60]] }
          it { expect(lambda { subject }).to be_executed_sqls(3) }
        end
      end
    end

  end
end