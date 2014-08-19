require 'rails_helper'
describe CalculableAttrs::ActiveRecord::Querying do
  it 'has to delegate calculate_attrs to all' do
    all = double(:all)
    expect(all).to receive(:calculate_attrs)
    expect(Account).to receive(:all).and_return(all)
    Account.calculate_attrs(:balance)
  end
end