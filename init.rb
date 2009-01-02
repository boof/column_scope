require "#{ File.dirname __FILE__ }/lib/active_record/named_scope/column_scope"

module ActiveRecord

  Base.extend NamedScope::ColumnScope::ScopeMethods
  # Overwrite <tt>Base.values</tt> to directly call <tt>column_names</p>.
  def Base.values
    NamedScope::ColumnScope::ValueExtractor.new self, column_names
  end

  module NamedScope
    Scope.class_eval { include ColumnScope::ScopeMethods }
  end

end

