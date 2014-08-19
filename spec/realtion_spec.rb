require 'rails_helper'

describe Calculable::ActiveRecord::Relation do
  describe '#calculate_attrs' do
    context 'method exists' do
      subject { Account.all }
      it { is_expected.to respond_to :calculate_attrs }
    end

    context 'method works in proper way' do
      before do
        3.times { |i| create(:account, tr_count: 10 * (i + 1), tr_amount: 10) }
        Account.calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)') { Transaction.joins(:account).all }
      end

      context 'one attribute' do
        subject { Account.all.calculate_attrs(:balance) }
        it { expect(subject.map(&:balance).sort).to eq [100, 200, 300] }
        it { expect(lambda { subject.load }).to be_executed_sqls(2) }
      end

      context 'two attributes' do
        subject { Account.all.calculate_attrs(:balance, :number_of_transactions) }
        it { expect(subject.map(&:balance).sort).to eq [100, 200, 300] }
        it { expect(subject.map(&:number_of_transactions).sort).to eq [10, 20, 30] }
        it { expect(lambda { subject.load }).to be_executed_sqls(2) }
      end

      context 'true as parameter' do
        subject { Account.all.calculate_attrs(true) }
        it { expect(subject.map(&:balance).sort).to eq [100, 200, 300] }
        it { expect(subject.map(&:number_of_transactions).sort).to eq [10, 20, 30] }
        it { expect(lambda { subject.load }).to be_executed_sqls(2) }
      end


      context 'no parameters' do
        subject { Account.all.calculate_attrs }
        it { expect(subject.map(&:balance).sort).to eq [100, 200, 300] }
        it { expect(subject.map(&:number_of_transactions).sort).to eq [10, 20, 30] }
        it { expect(lambda { subject.load }).to be_executed_sqls(2) }
      end
    end

    context 'method works in proper with subordinately objects' do
      before do
        2.times do |ui|
          user = create(:user)
          3.times { |i| create(:account, user: user, tr_count: 10 * (i + 1), tr_amount: 10 ** (ui + 1)) }
        end
        Account.calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)') { Transaction.joins(:account).all }
      end

      context 'one attribute' do
        subject { User.includes(:accounts).calculate_attrs(accounts: :balance).to_a.sort(&:id).map {|user| user.accouns.map(&:balance).sort } }
        it { is_expected.to eq [[100, 200, 300],[1000, 2000, 3000]] }
        it { expect(lambda { subject }).to be_executed_sqls(3) }
      end

    end

  end
end