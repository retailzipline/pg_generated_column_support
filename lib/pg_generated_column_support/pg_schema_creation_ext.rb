module PgGeneratedColumnSupport
  module PostgreSQLSchemaCreationExtension
    def add_column_options!(sql, options)
      if options[:collation]
        sql << " COLLATE \"#{options[:collation]}\""
      end

      # --- Begin Monkey Patch ----
      if as = options[:as]
        sql << " GENERATED ALWAYS AS (#{as})"

        if options[:stored]
          sql << " STORED"
        else
          raise ArgumentError, <<~MSG
            PostgreSQL currently does not support VIRTUAL (not persisted) generated columns.
            Specify 'stored: true' option for '#{options[:column].name}'
          MSG
        end
      end
      # --- End Monkey Patch ----

      super
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaCreation.send :include, PgGeneratedColumnSupport::PostgreSQLSchemaCreationExtension
