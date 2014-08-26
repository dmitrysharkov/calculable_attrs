require 'rails_helper'

describe CalculableAttrs::ActiveRecord::Base do
  describe '#calcualble_attr' do
    context 'without defaults' do
      subject { create(:account, tr_count: 5, tr_amount: 10) }

      context 'one attr and block' do
        before do
          Account.calculable_attr(balance: 'SUM(amount)'){ Transaction.joins(:account).all }
        end
        it { is_expected.to respond_to :balance }
        it { expect(subject.balance).to eq 50 }
        it do
          subject #force to execute insertions before
          expect(->{ 10.times { subject.balance } } ).to be_executed_sqls(1)
        end
      end

      context 'one attr and lambda' do
        before do
          Account.calculable_attr balance: 'SUM(amount)', from: ->{ Transaction.joins(:account).all}
        end
        it { is_expected.to respond_to :balance }
        it { expect(subject.balance).to eq 50 }
      end

      context 'many attrs and block' do
        before do
          Account.calculable_attr balance: 'SUM(transactions.amount)', number_of_transactions: 'COUNT(*)' do
            Transaction.joins(:account).all
          end
        end
        it { is_expected.to respond_to :balance }
        it { expect(subject.balance).to eq 50 }
        it { is_expected.to respond_to :number_of_transactions }
        it { expect(subject.number_of_transactions).to eq 5 }
      end

      context 'many attrs and block' do
        before do
          Account.calculable_attr balance:                'SUM(transactions.amount)',
                                  number_of_transactions: 'COUNT(*)',
                                  from:                    ->{ Transaction.joins(:account).all }
        end

        it { is_expected.to respond_to :balance }
        it { expect(subject.balance).to eq 50 }
        it { is_expected.to respond_to :number_of_transactions }
        it { expect(subject.number_of_transactions).to eq 5 }
      end

      it 'will raise exception if no scope provided' do
        no_scope = proc do
          Account.calculable_attr balance: 'SUM(amount)'
        end
        expect(no_scope).to raise_error('CALCULABLE_ATTRS: Relation was missed.')
      end
    end

    context 'with defaults' do
      subject { create(:account) }

      context 'explicit defaults' do
        before do
          Account.calculable_attr(balance: ['SUM(amount)', '-']){ Transaction.joins(:account).all }
        end
        it { expect(subject.balance).to eq '-'}
      end

      context 'implicit default is zero' do
        before do
          Account.calculable_attr(balance: 'SUM(amount)'){ Transaction.joins(:account).all }
        end
        it { expect(subject.balance).to eq 0 }
      end
    end
  end

  describe '#calcualble_attrs_calculators' do
    let(:account) { create(:account, tr_count: 5, tr_amount: 10) }
    before do
      Account.calculable_attr(balance: 'SUM(amount)'){ Transaction.joins(:account).all }
    end
    it { expect(Account).to respond_to(:calculable_attr_calculator) }
    context 'calculator' do
      subject { Account.calculable_attr_calculator(:balance) }
      it { expect(subject).to be_a CalculableAttrs::Calculator }
      it { expect(subject.attrs).to eq [:balance]  }
      it { expect(subject.scoped_relation(account.id).map(&:amount)).to eq [10, 10, 10, 10, 10]  }
    end
  end
end
