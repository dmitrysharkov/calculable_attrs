require 'rails_helper'
describe CalculableAttrs::ActiveRecord::Querying do
  it 'has to delegate calculate_attrs to all' do
    all = double(:all)
    expect(all).to receive(:calculate_attrs)
    expect(Account).to receive(:all).and_return(all)
    Account.calculate_attrs(:balance)
  end

  it 'has to delegate includes_calculable_attrs to all' do
    all = double(:all)
    expect(all).to receive(:includes_calculable_attrs)
    expect(Account).to receive(:all).and_return(all)
    Account.includes_calculable_attrs(:balance)
  end

  it 'has to delegate joins_calculable_attrs to all' do
    all = double(:all)
    expect(all).to receive(:joins_calculable_attrs)
    expect(Account).to receive(:all).and_return(all)
    Account.joins_calculable_attrs(:balance)
  end

end