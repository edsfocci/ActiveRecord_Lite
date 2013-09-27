require_relative './db_connection'

module Searchable
  def where(params)
    where_clause = params.keys.map do |key|
      "#{key} = ?"
    end

    where_array = DBConnection.execute(<<-SQL, params.values)
      SELECT *
      FROM #{ self.table_name }
      WHERE #{ where_clause.join(' AND ') }
    SQL

    parse_all(where_array)
  end
end