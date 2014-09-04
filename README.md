# Calculable Attrs
calculable_attrs gem allows you to add dynamically calculable attributes (like balance) to your models.

##Installation
Just add recent version to your Gemfile:

```ruby
gem 'calculable_attrs', '0.0.11'
```

##Usage

###Calculable attributes definition
Let's say you have the following data model in your project:

```
User (one)->(many) Account (one) -> (many) Transaction
```

Account's balance is a sum all transactions assigned to the account.
User's balance is a sum of all transactions assigned to this user's accounts.


calculable_attrs allows you to define dynamically calculable attributes balance and number of transactions as following:

```ruby
  class User < ActiveRecord::Base
    has_many :accounts
    calculable_attr(balance: 'SUM(amount)', number_of_transactions: 'COUNT(*)', foreign_key: 'accounts.user_id') do
      Transaction.joins(:account)
    end
  end
```

```ruby
  class Account < ActiveRecord::Base
    has_many :transactions
    belongs_to :user
    calculable_attr balance:                'SUM(amount)',
                    number_of_transactions: 'COUNT(*)',
                    from:                    -> { Transaction.joins(:account) }
  end
```

```ruby
  class Transaction < ActiveRecord::Base
    belongs_to :account
  end
```

####NOTES
 - `#calculable_attr` accepts a hash of calculable attributes (like `{ attribute_name: 'formula' }` where formula is SQL aggregation function).
 - the block after calculable_attr method has to return relation. This relation will be used as basis for aggregation functions mentioned above
 - you can use `calculable_attr ..., from: -> { ... }` instead of `calculable_attr (...) { ... }`
 - the default value for calculable_attr is 0 but you can specify it like:
```ruby
  class Account < ActiveRecord::Base
    has_many :transactions
    belongs_to :user
    calculable_attr(balance: ['SUM(amount)', '-'], number_of_transactions: ['COUNT(*)', nil]) { Transaction.joins(:account).all }
  end
```
 - the default value for aggregation key is `"#{ Model }.id"`, but` you can specify it with `foreign_key:` like in example below:
```ruby
 class Account < ActiveRecord::Base
   has_many :transactions
   belongs_to :user
   calculable_attr(balance: 'SUM(amount)', foreign_key: 'account_id') { Transaction.all }
 end
```

###Single record
After calculable attributes defined you'll be able to use these fields like in the following examples:

```ruby
b = User.first.balance
````

####NOTES
 - calculate_attrs caches the value. So next call to `b.balance` will *NOT* run anothes SQL query

###Relation
You will be able to include calculable attrs in the your queries like blow
```ruby
  @accounts = Account.includes_calculable_attrs(:balance)
```
...

```erb
  <% @accounts.each |acc|%>
    Account Balance: <%= acc.balance %>
  <% end %>
```

The code below will run 2 SQL queries.
```sql
SELECT * FROM balances;
SELECT SUM(amount) from transacitons WHERE account_id IN (1,2,3, /* ect */)
```
As you can see calculable_attrs does kind of eager loading. Just like standard `ActiveRecord::Relation#includes(...)` work.
You also can call `#includes_calculable_attrs` without parameters. In this case *all* calculable attributes will be included.


It's also possible to calculate attrs for subordinate queries.
```ruby
  @users = User.includes(:accounts).includes_calculable_attrs(accounts: :balance)
```
...

```erb
 <% @users.each |user|%>
    <% users.accounts.each |acc|%>
      User Account Balance: <%= acc.balance %>
    <% end %>
  <% end %>
```
Eager loading will work for this case also.

Take a look of several more possible combinations of parameters below.
```ruby
  @users = User.includes(:accounts).includes_calculable_attrs(:balance, :number_of_transactions, accounts: [:balance, :number_of_transactions])
```
...

```erb
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
  @users = User.includes(:accounts).includes_calculable_attrs(true, accounts: true)
```
...

```erb
  <% @users.each |user|%>
    User Balance: <%= user.balance %>
    User Transactions: <%= user.number_of_transactions %>
    <% users.accounts.each |acc|%>
      User Account Balance: <%= acc.balance %>
      User Account Transactions: <%= acc.number_of_transactions %>
    <% end %>
  <% end %>
```

####NOTES
 - `#includes_calculable_attrs` solves n+1 queries problem
 - `#includes_calculable_attrs` takes an array of attributes to be pre-calculated
 - `#includes_calculable_attrs` undergrads associations (just like`includes` or `joins`)
 - `#includes_calculable_attrs(true)` means "calculate all attributes"
 - `#includes_calculable_attrs` with no parameters acts just like calculate_attrs(true)

###Where clause
If you're using PostgreSQL or MySQL 5.1+ it's also possible to use calculable attributes in your where clauses.
To do this you have to use `#joins_calcululable_attrs`

Take a look on example below.
```ruby
  @users = Account.joins_calculable_attrs(:balance).where('accounts.balance > ?', 1000 )
```
You jast use `accounts.balance > ?` condition like if `balance` filed were a part of `accounts` table.

It will generate the following SQL:
```sql
  SELECT accounts.*, COALESCE(__calculated_attrs_0__.account_balance, 0) AS account_balance
    FROM "accounts"
    LEFT JOIN
      (
        SELECT SUM(amount) AS account_balance, accounts.id AS __calculable_id__
        FROM "transactions"
          INNER JOIN "accounts" ON "accounts"."id" = "transactions"."account_id"
        GROUP BY accounts.id
      )
      AS __calculated_attrs_0__
      ON __calculated_attrs_0__.__calculable_id__ = accounts.id
    WHERE (COALESCE(__calculated_attrs_0__.account_balance, 0) > 1000)

```
As you can see a subquery is used here that's why it will for work for SQLite. But anyway it generates only ony SQL query.
Note that calculated attribute name in the resulting query will be `#{ Model.name.underscore}_#{ attr_name }`,
but calculable_attrs will include it in resulting `Account` record anyway.

You can also use hash style to specify where clause.
```ruby
  @accounts = Account.joins_calculable_attrs(:balance).where(accounts: { balance: [50..100] })
```
...

```erb
 <% @users.each |user|%>
    <% users.accounts.each |acc|%>
      User Account Balance: <%= acc.balance %>
    <% end %>
  <% end %>
```
The `balance` calculable attribute will be eager loaded so that there will be *NO* SQL queries in the loop.

One more example.
```ruby
  @accounts = Account.joins_calculable_attrs(:balance).where(balance: [50..100])
```



You will be able to combine `#joins_calculable_attrs` with `#includes_calculable_attrs` like in example below.

```ruby
  @users = User.includes(:accounts)
    .joins_calculable_attrs(:balance)
    .includes_calculable_attrs(:balance, :number_of_transactions, accounts: [:balance, :number_of_transactions])
    .where('account_balance > ?', 1000 )
```
*BUT* you can *NOT* to this ~(yet :)~
```ruby
  @users = Account.includes(:user)
    .joins_calculable_attrs(user: :balance)
    .where('account_balance > ?', 1000 )
```
~I'm going to implement this in the new version ~

####NOTES
 - `#joins_calculable_attrs` allow usage calculable attributes in where clauses.
 - `#joins_calculable_attrs` will generate left-joins subquery (will *NOT* work in SQLite).
 - `#joins_calculable_attrs` undergrads associations (just like`includes` or `joins`)
 - It's possible to combine `#joins_calculable_attrs` with `#includes_calculable_attrs`. Calculable_attrs will minimize number of SQL queries in this case.
 - `#joins_calculable_attrs` for nested records is *NOT* implemented yet.

###Calulations
Calulations are *NOT* impelemted for calculable atts yet. But you can user where clayses for in static fields calculations.
See examples blow

```ruby
  c1 = Account.includes_calculable_attrs.where('accounts.balance > 1000').count(*)
  c2 = Account.includes_calculable_attrs.where('accounts.balance > 1000').min(:id)
```