module ActiveRecord
  class QueryCounter
    attr_reader :query_count
    def initialize
      @query_count  = 0
    end

    IGNORED_SQL = [/^PRAGMA (?!(table_info))/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/, /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/, /^SHOW max_identifier_length/]

    def call(name, start, finish, message_id, values)
      @query_count += 1 unless IGNORED_SQL.any? { |r| values[:sql] =~ r }
    end
  end
end

module ActiveRecord
  class Base
    def self.count_queries(&block)
      counter =  ActiveRecord::QueryCounter.new
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record', counter)
      yield
      ActiveSupport::Notifications.unsubscribe(subscriber)
      counter.query_count
    end
  end
end

RSpec::Matchers.define :be_executed_sqls do |expected|
  match do |block|
    @sql_queries = ActiveRecord::Base.count_queries(&block)
    @sql_queries == expected
  end

  description do
    "execute #{expected} sql queries"
  end

  failure_message do
    "expected to #{description} but executed #{ @sql_queries }"
  end
end
