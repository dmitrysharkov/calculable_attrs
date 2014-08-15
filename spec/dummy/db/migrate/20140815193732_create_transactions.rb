class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :account_id

      t.timestamps
    end
    add_index :transactions, :account_id
  end
end
