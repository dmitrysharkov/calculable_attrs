require 'rails_helper'

describe Calculable::ActiveRecord::Relation do
  describe '#calculate_attrs' do
    before do
      3.times { |i| create(:account, tr_count: 10, tr_amount: 10 * (i + 1)) }
    end
    subject { Account.all }
    it { is_expected.to respond_to :calculate_attrs }
    it { expect.to(subject.calculate_attrs(:balance).map(&:balance).sort).to eq [100, 200, 300] }

  end
end