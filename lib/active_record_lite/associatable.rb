require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :primary_key, :foreign_key

  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    unless params[:class_name].nil?
      @other_class_name = params[:class_name]
    else
      @other_class_name = name.to_s.capitalize
      @other_class_name.gsub!(/_[a-z]/) { |w| w[1].upcase }
    end

    unless params[:primary_key].nil?
      @primary_key = params[:primary_key]
    else
      @primary_key = :id
    end

    unless params[:foreign_key].nil?
      @foreign_key = params[:foreign_key]
    else
      @foreign_key = "#{ name }_id".to_sym
    end
  end

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class) # Question: Need self_class?
    unless params[:class_name].nil?
      @other_class_name = params[:class_name]
      # TODO: Convert @other_class_name to snake case
    else
      other_class_name_snake = name.to_s.singularize
      @other_class_name = other_class_name_snake.capitalize
      @other_class_name.gsub!(/_[a-z]/) { |w| w[1].upcase }
    end

    unless params[:primary_key].nil?
      @primary_key = params[:primary_key]
    else
      @primary_key = :id
    end

    unless params[:foreign_key].nil?
      @foreign_key = params[:foreign_key]
    else
      @foreign_key = "#{ other_class_name_snake }_id".to_sym
    end
  end

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end

  def type
  end
end

module Associatable
  def assoc_params
    if @assoc_params.nil?
      @assoc_params = {}
    end

    @assoc_params
  end

  def belongs_to(name, params = {})
    assoc_params[name] = BelongsToAssocParams.new(name, params)
    aps = assoc_params[name]

    define_method(name) do

      other_record = DBConnection.execute(<<-SQL, send(aps.foreign_key))
        SELECT *
        FROM #{ aps.other_table }
        WHERE #{ aps.primary_key } = ?
      SQL

      aps.other_class.parse_all(other_record)
    end
  end

  def has_many(name, params = {})
    aps = HasManyAssocParams.new(name, params, self.class)

    define_method(name) do

      other_records = DBConnection.execute(<<-SQL, send(aps.primary_key))
        SELECT *
        FROM #{ aps.other_table }
        WHERE #{ aps.foreign_key } = ?
      SQL

      aps.other_class.parse_all(other_records)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    aps1 = assoc_params[assoc1]


    define_method(name) do
      aps2 = aps1.other_class.assoc_params[assoc2]

      assoc1_id = send(aps1.foreign_key)
      assoc2_id = aps1.other_class.find(assoc1_id).send(aps2.foreign_key)

      other_record = DBConnection.execute(<<-SQL, assoc1_id, assoc2_id)
        SELECT #{ aps2.other_table }.*
        FROM #{ aps2.other_table }
        JOIN #{ aps1.other_table }
        ON #{ aps2.other_table }.#{ aps2.primary_key } = #{ aps2.foreign_key }
        WHERE #{ aps1.other_table }.#{ aps1.primary_key } = ?
        AND #{ aps2.other_table }.#{ aps2.primary_key } = ?
      SQL

      aps2.other_class.parse_all(other_record)
    end
  end
end
