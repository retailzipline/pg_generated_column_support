require "active_support/core_ext/object/blank"

module PgGeneratedColumnSupport
  module PostgreSQLColumnExtension
    def initialize(*, serial: nil, generated: nil, **)
      super
      @serial = serial
      @generated = generated
    end

    def virtual?
      # We assume every generated column is virtual, no matter the concrete type
      @generated.present?
    end

    def has_default?
      super && !virtual?
    end
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQL::Column.send :include, PgGeneratedColumnSupport::PostgreSQLColumnExtension
