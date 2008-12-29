require "#{ File.dirname __FILE__ }/lib/column_scope"
ActiveRecord::NamedScope::Scope.class_eval do
  include ColumnScope::ScopeMethods
end
ActiveRecord::Base.class_eval do
  extend ColumnScope::ScopeMethods
  def self.values
    ColumnScope::ValueExtractor.new self, column_names
  end
end
