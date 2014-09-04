require 'rails_helper'

describe CalculableAttrs::ActiveRecord::Relation do
  describe '#joins_calculable_attrs' do
    before do
      Account.calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)') { Transaction.joins(:account).all }
      User.calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)', foreign_key: 'accounts.user_id') { Transaction.joins(:account).all }
      User.calculable_attr(number_of_accounts: 'COUNT(*)', foreign_key: 'accounts.user_id') { Account.all }
    end

    context 'method exists' do
      subject { Account.all.joins_calculable_attrs }
      it { is_expected.to respond_to :joins_calculable_attrs }
    end

    describe 'without subordinated objects' do
      before do
        5.times { |i| create(:account, tr_count: 10 * (i + 1), tr_amount: 10) }
        5.times { |i| create(:account, tr_count: 0) }
      end

      context 'whithout where' do
        shared_examples 'balance attribute works in proper way' do
          it { expect(subject.map(&:balance).sort).to eq [0, 0, 0, 0, 0, 100, 200, 300, 400, 500] }
          it { expect(lambda { subject.load }).to be_executed_sqls(1) }
        end

        shared_examples 'balance and number_of_transactions attributes in proper way' do
          it_behaves_like 'balance attribute works in proper way'
          it { expect(subject.map(&:number_of_transactions).sort).to eq [0, 0, 0, 0, 0, 10, 20, 30, 40, 50] }
        end

        context 'one attribute' do
          subject { Account.all.joins_calculable_attrs(:balance) }
          it_behaves_like  'balance attribute works in proper way'
        end

        context 'two attributes' do
          subject { Account.all.joins_calculable_attrs(:balance, :number_of_transactions) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end

        context 'true as parameter' do
          subject { Account.all.joins_calculable_attrs(true) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end

        context 'no parameters' do
          subject { Account.all.joins_calculable_attrs }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end
      end

      context 'with where' do
        context 'with strign condition' do
          context 'one attribute' do
            subject { Account.all.joins_calculable_attrs(:balance).where('accounts.balance < 300') }
            it { expect(subject.map(&:number_of_transactions).sort).to eq [0, 0, 0, 0, 0, 10, 20] }
            it { expect(subject.map(&:balance).sort).to eq [0, 0, 0, 0, 0, 100, 200] }
            it { expect(subject.count('*')).to eq 7 }
            it { expect(subject.sum('1')).to eq 7 }
            it { expect(subject.sum(:id)).to be > 7 }
            it { expect(lambda { subject.load }).to be_executed_sqls(1) }
          end

          context 'two attributes' do
            context 'one attribute' do
              subject { Account.all.joins_calculable_attrs(:balance, :number_of_transactions).where('accounts.balance < 300 OR accounts.number_of_transactions >= 3') }
              it { expect(subject.map(&:balance).sort).to eq [0, 0, 0, 0, 0, 100, 200, 300, 400, 500] }
              it { expect(subject.map(&:number_of_transactions).sort).to eq [0, 0, 0, 0, 0, 10, 20, 30, 40, 50] }
              it { expect(subject.count('*')).to eq 10 }
              it { expect(subject.sum('1')).to eq 10 }
              it { expect(subject.sum(:id)).to be > 10 }
              it { expect(lambda { subject.load }).to be_executed_sqls(1) }
            end
          end
        end

        context 'with hash condition' do
          context 'one attribute with table prefiex' do
            subject { Account.all.joins_calculable_attrs(:balance).where(accounts: { balance: [0...300] })}
            it { expect(subject.map(&:number_of_transactions).sort).to eq [0, 0, 0, 0, 0, 10, 20] }
            it { expect(subject.map(&:balance).sort).to eq [0, 0, 0, 0, 0, 100, 200] }
            it { expect(subject.count('*')).to eq 7 }
            it { expect(lambda { subject.load }).to be_executed_sqls(1) }
          end

          context 'one attribute without table prefiex' do
            subject { Account.all.joins_calculable_attrs(:balance).where( balance: [0...300] )}
            it { expect(subject.map(&:number_of_transactions).sort).to eq [0, 0, 0, 0, 0, 10, 20] }
            it { expect(subject.map(&:balance).sort).to eq [0, 0, 0, 0, 0, 100, 200] }
            it { expect(subject.count('*')).to eq 7 }
            it { expect(subject.sum('1')).to eq 7 }
            it { expect(subject.sum(:id)).to be > 7 }
            it { expect(lambda { subject.load }).to be_executed_sqls(1) }
          end

        end
      end
    end

    describe 'with subordinated objects' do
      before do
        3.times do |ui|
          user = create(:user)
          3.times { |i| create(:account, user: user, tr_count: 10 * (i + 1), tr_amount: 10 ** (ui + 1)) }
        end
      end

      context 'when has many' do
        let(:shared_scope) { User.includes(:accounts).order(:id) }

        subject(:users_balances) { scope.map(&:balance) }
        subject(:users_number_of_transactions) { scope.map(&:number_of_transactions) }
        subject(:users_number_of_accounts) { scope.map(&:number_of_accounts) }

        subject(:accounts_balances) { scope.map {|user| user.accounts.map(&:balance).sort } }
        subject(:accounts_number_of_transactions) { scope.map {|user| user.accounts.map(&:number_of_transactions).sort } }

        shared_examples 'balance attribute works in proper way' do
          it { expect(users_balances).to eq [600, 6000, 60000] }
          it { expect(accounts_balances).to eq [[100, 200, 300], [1000, 2000, 3000], [10000, 20000, 30000]] }
          it { expect(lambda { scope.load }).to be_executed_sqls(3) }
        end

        shared_examples 'balance and number_of_transactions attributes in proper way' do
          it { expect(users_balances).to eq [600, 6000, 60000] }
          it { expect(accounts_balances).to eq [[100, 200, 300], [1000, 2000, 3000], [10000, 20000, 30000]] }
          it { expect(users_number_of_transactions).to eq [60, 60, 60] }
          it { expect(users_number_of_accounts).to eq [3, 3, 3] }
          it { expect(accounts_number_of_transactions).to eq [[10, 20, 30], [10, 20, 30], [10, 20, 30]] }
          it { expect(lambda { scope.load }).to be_executed_sqls(3) }
        end

        context 'one attribute' do
          let(:scope) { shared_scope.joins_calculable_attrs(:balance).calculate_attrs(accounts: :balance) }
          it_behaves_like 'balance attribute works in proper way'
        end

        context 'tree attributes' do
          let(:scope) { shared_scope.joins_calculable_attrs(:balance, :number_of_transactions, :number_of_accounts).calculate_attrs(accounts: [:balance, :number_of_transactions]) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end

        context 'one attribute' do
          let(:scope) { shared_scope.joins_calculable_attrs(:balance).calculate_attrs(:balance, accounts: :balance) }
          it_behaves_like 'balance attribute works in proper way'
        end

        context 'tree attributes' do
          let(:scope) { shared_scope.joins_calculable_attrs(:balance, :number_of_transactions, :number_of_accounts).calculate_attrs(:balance, :number_of_transactions, :number_of_accounts, accounts: [:balance, :number_of_transactions]) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end

        context 'no parameters' do
          let(:scope) { shared_scope.joins_calculable_attrs.calculate_attrs(true, accounts: true) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end

        context 'no parameters' do
          let(:scope) { shared_scope.joins_calculable_attrs.calculate_attrs(true, :accounts) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end

        context 'true as parameter' do
          let(:scope) { shared_scope.joins_calculable_attrs(true).calculate_attrs(true, accounts: true) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end

        context 'no parameters' do
          let(:scope) { shared_scope.joins_calculable_attrs(true).calculate_attrs(true, :accounts) }
          it_behaves_like 'balance and number_of_transactions attributes in proper way'
        end



      end

    end

  end
end
