module PgGeneratedColumnSupport
  module PostgreSQLAdapterExtension
    # -- New Method
    def supports_virtual_columns?
      database_version >= 120_000 # >= 12.0
    end

    private

    # Returns the list of a table's column names, data types, and default values.
    #
    # The underlying query is roughly:
    #  SELECT column.name, column.type, default.value, column.comment
    #    FROM column LEFT JOIN default
    #      ON column.table_id = default.table_id
    #     AND column.num = default.column_num
    #   WHERE column.table_id = get_table_id('table_name')
    #     AND column.num > 0
    #     AND NOT column.is_dropped
    #   ORDER BY column.num
    #
    # If the table name is not prefixed with a schema, the database will
    # take the first match from the schema search path.
    #
    # Query implementation notes:
    #  - format_type includes the column size constraint, e.g. varchar(50)
    #  - ::regclass is a function that gives the id for a table name
    def column_definitions(table_name)
      query(<<~SQL, "SCHEMA")
          SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                 pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
                 c.collname, col_description(a.attrelid, a.attnum) AS comment,
                 -- Begin Monkey Patch
                 #{supports_virtual_columns? ? 'attgenerated' : quote('')} as attgenerated
                 -- End Monkey Patch
            FROM pg_attribute a
            LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
            LEFT JOIN pg_type t ON a.atttypid = t.oid
            LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
           WHERE a.attrelid = #{quote(quote_table_name(table_name))}::regclass
             AND a.attnum > 0 AND NOT a.attisdropped
           ORDER BY a.attnum
      SQL
    end
  end

  module PostgreSQLSchemaStatementsExtension
    private

    def new_column_from_field(table_name, field)
      # ---- Begin Monkey Patch -----
      column_name, type, default, notnull, oid, fmod, collation, comment, attgenerated = field
      # ---- End Monkey Patch -------
      type_metadata = fetch_type_metadata(column_name, type, oid.to_i, fmod.to_i)
      default_value = extract_value_from_default(default)
      default_function = extract_default_function(default_value, default)

      if match = default_function&.match(/\Anextval\('"?(?<sequence_name>.+_(?<suffix>seq\d*))"?'::regclass\)\z/)
        serial = sequence_name_from_parts(table_name, column_name, match[:suffix]) == match[:sequence_name]
      end

      # ---- Begin Monkey Patch -----
      ActiveRecord::ConnectionAdapters::PostgreSQL::Column.new(
        column_name,
        default_value,
        type_metadata,
        !notnull,
        default_function,
        collation: collation,
        comment: comment.presence,
        serial: serial,
        generated: attgenerated
      )
      # ---- End Monkey Patch -------
    end
  end

  module AbstractDatabaseStatementsExtension
    private

    def build_fixture_sql(fixtures, table_name)
      # ---- Begin Monkey Patch --
      columns = schema_cache.columns_hash(table_name).reject { |_, column| supports_virtual_columns? && column.virtual? }
      # ---- End Monkey Patch ----

      values_list = fixtures.map do |fixture|
        fixture = fixture.stringify_keys

        unknown_columns = fixture.keys - columns.keys
        if unknown_columns.any?
          raise Fixture::FixtureError, %(table "#{table_name}" has no columns named #{unknown_columns.map(&:inspect).join(', ')}.)
        end

        columns.map do |name, column|
          if fixture.key?(name)
            type = lookup_cast_type_from_column(column)
            with_yaml_fallback(type.serialize(fixture[name]))
          else
            default_insert_value(column)
          end
        end
      end

      table = Arel::Table.new(table_name)
      manager = Arel::InsertManager.new
      manager.into(table)

      if values_list.size == 1
        values = values_list.shift
        new_values = []
        columns.each_key.with_index { |column, i|
          # ---- Begin Monkey Patch - workaround private constant reference error --
          unless values[i].equal?(ActiveRecord::ConnectionAdapters::DatabaseStatements.const_get(:DEFAULT_INSERT_VALUE))
          # ---- End Monkey Patch --------------------------------------------------
            new_values << values[i]
            manager.columns << table[column]
          end
        }
        values_list << new_values
      else
        columns.each_key { |column| manager.columns << table[column] }
      end

      manager.values = manager.create_values_list(values_list)
      visitor.compile(manager.ast)
    end
  end
end

# I don't know why I need to do prepend here instead of include. For some reason
# the column_definitions method doesn't get overwritten if I use include.
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :prepend, PgGeneratedColumnSupport::PostgreSQLAdapterExtension
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PgGeneratedColumnSupport::PostgreSQLSchemaStatementsExtension
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PgGeneratedColumnSupport::AbstractDatabaseStatementsExtension
