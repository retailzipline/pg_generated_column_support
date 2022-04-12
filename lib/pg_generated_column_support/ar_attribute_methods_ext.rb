module PgGeneratedColumnSupport
  module AttributeMethodsExtension
    def attributes_for_update(attribute_names)
      attribute_names &= self.class.column_names
      attribute_names.delete_if do |name|
        self.class.readonly_attribute?(name) ||
          column_for_attribute(name).virtual?
      end
    end

    def attributes_for_create(attribute_names)
      attribute_names &= self.class.column_names
      attribute_names.delete_if do |name|
        (pk_attribute?(name) && id.nil?) ||
          column_for_attribute(name).virtual?
      end
    end
  end
end

ActiveRecord::AttributeMethods.send :include, PgGeneratedColumnSupport::AttributeMethodsExtension
