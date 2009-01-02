require "#{ File.dirname __FILE__ }/lib/active_record/named_scope/column_scope"

ActiveRecord::Base.class_eval do
  extend ActiveRecord::NamedScope::ColumnScope::ScopeMethods

  def self.values
    ActiveRecord::NamedScope::ColumnScope::
        ValueExtractor.new self, column_names
  end

end

ActiveRecord::NamedScope::Scope.class_eval do
  include ActiveRecord::NamedScope::ColumnScope::ScopeMethods
end
