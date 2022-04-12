module PgGeneratedColumnSupport
  module PostgreSQLTableDefinitionExtension
    def new_column_definition(name, type, **options) # :nodoc:
      case type
      when :virtual
        type = options[:type]
      end

      super
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.send :include, PgGeneratedColumnSupport::PostgreSQLTableDefinitionExtension
