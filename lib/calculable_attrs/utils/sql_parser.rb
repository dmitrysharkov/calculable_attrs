class CalculableAttrs::Utils::SqlParser
  def initialize(sql)
    @sql = sql
    @masked_sql = mask_sql(sql)
  end

  def first_select_snippet
    match = @masked_sql.match(/SELECT (?<select>.*?) FROM/)
    from, to = *match.offset(:select)
    @sql[from..to-1]
  end

  def last_where_snippet
    last_where_start_at = @masked_sql.rindex('WHERE')
    return unless last_where_start_at
    masted_sql_starting_with_last_where = @masked_sql[last_where_start_at..-1]
    match = masted_sql_starting_with_last_where.match(/WHERE (?<where>.*?)( GROUP| ORDER| LIMIT| OFFSET|$)/)
    from, to = *match.offset(:where)
    @sql[last_where_start_at + from..last_where_start_at+to-1]
  end


  private

  def mask_sql(sql)
    sql = mask_strings(sql)
    sql = mask_brackets(sql)
    sql
  end

  def mask_strings(sql, mask='x')
    idx = 0
    len = sql.size
    masked_sql = ''
    inside_string = false
    while idx < len
      ch = sql[idx]
      if ch == '\''
        if inside_string
          next_not_apostroph_index = sql.index(/[^']/,idx)
          next_not_apostroph_index = len unless next_not_apostroph_index
          apostrophs_length = next_not_apostroph_index - idx
          idx = next_not_apostroph_index
          masked_sql << mask * apostrophs_length
          inside_string = !(apostrophs_length % 2 == 1)
        else
          inside_string = true
          masked_sql << mask
          idx += 1
        end
      else
        if inside_string
          masked_sql << mask
        else
          masked_sql << ch
        end
        idx += 1
      end
    end

    masked_sql
  end


  def mask_brackets(sql, mask='y')
    idx = 0
    len = sql.size
    masked_sql = ''
    stack_size = 0
    while idx < len
      ch = sql[idx]
      case ch
        when '('
          stack_size += 1
          masked_sql << mask
        when ')'
          stack_size -= 1
          masked_sql << mask
        else
          if stack_size > 0
            masked_sql << mask
          else
            masked_sql << ch
          end
      end
      idx += 1
    end

    masked_sql
  end
end