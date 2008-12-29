class ColumnScope < ActiveRecord::NamedScope::Scope

  module ScopeMethods
    # Returns a ColumnScope.
    def selects(column_names)
      ColumnScope.new self, column_names
    end
    # Returns selected values of all records.
    def select_all(column_names, options = {})
      scope = selects column_names
      scope.all_values scope.all(options)
    end
    # Returns selected values of first record.
    def select_first(column_names, options = {})
      scope = selects column_names
      scope.values scope.first(options)
    end
    # Returns selected values of last record.
    def select_last(column_names, options = {})
      scope = selects column_names
      scope.values scope.last(options)
    end
  end

  def initialize(proxy_scope, column_names)
    initialize_extractor_and_select proxy_scope, column_names
    super proxy_scope, :select => @select_sql
  end

  # Extracts values from single record specified in column scope.
  def values(record)
    @value_extractor.call record
  end
  # Extracts values from multiple records specified in column scope.
  def all_values(records = all)
    records.map! { |record| values record }
  end

  def scopes #:nodoc:
    # inject scope to allow <tt>selects(:column).named_scope.values</tt>.
    cs = self

    super.merge :values => proc { |ps, *args|
      case arg = args.first
      when :first, :last
        cs.values ps.send(arg)
      when :all, nil
        cs.all_values ps.all
      end
    }
  end

  protected
  def initialize_extractor_and_select(proxy_scope, column_names) #:nodoc:
    column_names = "#{ column_names }"
    column_names = column_names.split('_and_').map! { |c| c.singularize }
    first_column_name = column_names.first

    @select_sql = first_column_name[0, 9] == 'distinct_' ?
      first_column_name.slice!(0, 9).gsub!('_', ' ').upcase :
      ''

    @value_extractor = column_names.size == 1 ?
      lambda { |record| record[first_column_name] } :
      lambda { |record| record.attributes.values_at(*column_names) }

    qtn = quoted_table_name_for proxy_scope
    @select_sql << column_names.map { |cn| "#{ qtn }.#{ cn }"} * ','
  end

  def quoted_table_name_for(object) #:nodoc:
    while object.class == ActiveRecord::NamedScope::Scope
      object = object.proxy_scope
    end

    object.quoted_table_name
  end

end
