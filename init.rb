require "#{ File.dirname __FILE__ }/lib/column_scope"
ActiveRecord::NamedScope::Scope.instance_eval { include ColumnScope::ScopeMethods }
ActiveRecord::Base.instance_eval { extend ColumnScope::ScopeMethods }
