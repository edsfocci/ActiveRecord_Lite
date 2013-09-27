require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable, Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name
  end

  def self.all
    all_array = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{ table_name }
    SQL

    parse_all(all_array)
  end

  def self.find(id)
    table_entry = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{ table_name }
      WHERE id = ?
    SQL

    new(table_entry.first)
  end

  # TODO: Fix so that there are no multiple entries of the same attributes
  def save
    if self.id.nil?
      insert
    else
      update
    end
  end

  private
  def insert
    DBConnection.execute(<<-SQL, attribute_values[1..-1])
      INSERT INTO #{ self.class.table_name }
        (#{ self.class.attributes[1..-1].join(', ') })
      VALUES (#{ (['?'] * attribute_values[1..-1].size).join(', ') })
    SQL

    new_id = DBConnection.execute(<<-SQL, attribute_values[1..-1])
      SELECT id
      FROM #{ self.class.table_name }
      WHERE #{ particular_attrs.join(' AND ') }
    SQL

    p new_id
    self.id = new_id.first['id']
  end

  def update
    DBConnection.execute(<<-SQL, attribute_values.rotate)
      UPDATE #{ self.class.table_name }
      SET #{ particular_attrs.join(', ') }
      WHERE id = ?
    SQL
  end

  def attribute_values
    self.class.attributes.map do |attribute|
      send(attribute)
    end
  end

  def particular_attrs
    self.class.attributes[1..-1].map do |attr_name|
      "#{ attr_name } = ?"
    end
  end
end
