FactoryGirl.define do
  factory :user do
  end

  factory :transaction do
  end

  factory :account do
    ignore do
      tr_count 0
      tr_amount 10
    end

    after(:create) do |account, evaluator|
      create_list(:transaction, evaluator.tr_count, account: account, amount: evaluator.tr_amount)
    end
  end
end