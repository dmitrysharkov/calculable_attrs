# Calculable Attrs

calculable_attrs gem allows you to add dynamically calculable attributes (like balance) to your models.
Let's say you have the following data model in your project:
  User -<has many>-> Account -<has many>-> Transaction

Account's balance is a sum all transactions assigned to the account.
User's balance is a sum of all transactions assigned to this user's accounts.

calculable_attrs allows you to define dynamically calculable attributes balance and number of transactions as following:

```ruby
  class User < ActiveRecord::Base
    has_many :accounts
    calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)', foreign_key: 'accounts.user_id') do
      Transaction.joins(:account).all
    end
  end
```

```ruby
  class Account < ActiveRecord::Base
    has_many :transactions
    belongs_to :user
    calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)') { Transaction.joins(:account).all }
  end
```

```ruby
  class Transaction < ActiveRecord::Base
    belongs_to :account
  end
```

*NOTE:*
 - calculable_attr accepts a hash of calculable attributes { attribute_name: 'formula' } where formula is SQL aggregation function
 - the block after calculable_attr method has to return relation. This relation will be used as basis for aggregation functions mentioned above
 - you can use calculable_attr ..., from: -> { ... } instead of calculable_attr (...) { ... }
 - the default value for calculable_attr is 0 but you can specify it like:

  ```ruby
    class Account < ActiveRecord::Base
      has_many :transactions
      belongs_to :user
      calculable_attr(balance: ['SUM(amount)', '-'], number_of_transactions: ['COUNT(*)', nil]) { Transaction.joins(:account).all }
    end
  ```
 - the default value for aggregation key is <relation>.id, but you can specify it with foreign_key:

Then you'll be able to use these fields like in the following examples:

```ruby
  b = User.first.balance
```

```ruby
  @accounts = Account.calculate_attrs

  ...

  <% @accounts.each |acc|%>
    Account Balance: <%= acc.balance %>
  <% end %>
```


```ruby
  @users = User.includes(:accounts).calculate_attrs(accounts: :balance)

  ...

  <% @users.each |user|%>
    <% users.accounts.each |acc|%>
      User Account Balance: <%= acc.balance %>
    <% end %>
  <% end %>
```

```ruby
  @users = User.includes(:accounts).calculate_attrs(:balance, :number_of_transactions, accounts: [:balance, :number_of_transactions])

  ...

  <% @users.each |user|%>
    User Balance: <%= user.balance %>
    User Transactions: <%= user.number_of_transactions %>
    <% users.accounts.each |acc|%>
      User Account Balance: <%= acc.balance %>
      User Account Transactions: <%= acc.number_of_transactions %>
    <% end %>
  <% end %>
```

```ruby
  @users = User.includes(:accounts).calculate_attrs(true, accounts: true)

  ...

  <% @users.each |user|%>
    User Balance: <%= user.balance %>
    User Transactions: <%= user.number_of_transactions %>
    <% users.accounts.each |acc|%>
      User Account Balance: <%= acc.balance %>
      User Account Transactions: <%= acc.number_of_transactions %>
    <% end %>
  <% end %>
```

*NOTE:*
 - calculate_attrs solves n+1 queries problem
 - calculate_attrs takes an array of attributes to be pre-calculated
 - calculate_attrs undergrads associations (just like`includes` or `joins`)
 - calculate_attrs(true) means "calculate all attributes"
 - calculate_attrs with no parameters acts just like calculate_attrs(true)

