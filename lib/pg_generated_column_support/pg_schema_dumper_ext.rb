module PgGeneratedColumnSupport
  module PostgreSQLSchemaDumperExtension
    def prepare_column_options(column)
      spec = super
      spec[:array] = "true" if column.array?

      # ---- Being Monkey Patch -----
      if @connection.supports_virtual_columns? && column.virtual?
        spec[:as] = extract_expression_for_virtual_column(column)
        spec[:stored] = true
        spec = { type: schema_type(column).inspect }.merge!(spec)
      end
      # ---- End Monkey Patch -----

      spec
    end

    private

    def extract_expression_for_virtual_column(column)
      column.default_function.inspect
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.send :include, PgGeneratedColumnSupport::PostgreSQLSchemaDumperExtension
