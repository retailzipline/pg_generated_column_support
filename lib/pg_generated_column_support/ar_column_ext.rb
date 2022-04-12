module PgGeneratedColumnSupport
  module AbstractColumnExtension
    def virtual?
      false
    end
  end
end

ActiveRecord::ConnectionAdapters::Column.send :include, PgGeneratedColumnSupport::AbstractColumnExtension
