# = ColumnScope
#
# To create a column scope invoke either <tt>selects</tt> or <tt>rejects</tt>
# on a scope (which is either a model or a named scope).
#
# When you invoke <tt>find</tt> on a scope that is chained with a column scope
# only the named columns are selected by SQL.
# This gives you the instances of your model with the selected attributes
# assigned.
#
# If you only want the plain values invoke <tt>values</tt> on a scope before
# you invoke <tt>find</tt>.
#
# == Shortcuts
#
# select_all, select_first and select_last are shortcuts. They accept a symbol
# (or string) in the following format:
#
#   :name
#   :names # => name
#   :name_and_value # => name, value
#   :distinct_name # => DISTINCT name
class ColumnScope < ActiveRecord::NamedScope::Scope

  module ScopeMethods

    def self.splat_timestamps!(column_names) #:nodoc:
      if i = column_names.index('timestamps')
        column_names.delete_at i
        column_names << 'created_at'
        column_names << 'updated_at'
      end

      column_names
    end

    # Returns an instance of ValueExtractor with scope and column names.
    #
    # The ValueExtractor invokes a find on the scope and maps the results
    # to the selected values.
    #
    # Note: This method is overwritten for ActiveRecord::Base to invoke
    # column_names on self.
    def values
      ColumnScope::ValueExtractor.new self, proxy_scope.column_names
    end
    # Returns a ColumnScope with named columns.
    #
    # To get the selected values invoke <tt>values</tt> on this scope before
    # you load the records with <tt>all</tt>, <tt>first</tt> or <tt>last</tt>.
    def selects(*selected_cns)
      selected_cns = selected_cns.map {|cn|cn.to_s}
      ColumnScope.new self, ScopeMethods.splat_timestamps!(selected_cns)
    end
    # Returns a ColumnScope w/o named columns.
    #
    # To get the selected values invoke <tt>values</tt> on this scope before
    # you load the records with <tt>all</tt>, <tt>first</tt> or <tt>last</tt>.
    #
    # Note: The attribute order is the same as in <tt>column_names</tt> w/o
    # the named columns.
    def rejects(*rejected_cns)
      rejected_cns = rejected_cns.map {|cn|cn.to_s}
      ScopeMethods.splat_timestamps! rejected_cns

      ColumnScope.new self, column_names - rejected_cns
    end

    def self.split_column_names(column_names) #:nodoc:
      column_names  = "#{ column_names }"
      column_names  = column_names.split('__').map! { |c| c.singularize }
      first_cn      = column_names.first

      distinct =  if first_cn[0, 9] == 'distinct_'
        first_cn.slice!(0, 9).gsub!('_', ' ').upcase
      end

      return distinct, column_names
    end

    # This shortcut returns selected values of all records.
    def select_all(column_names, options = {})
      select_values(column_names).all options
    end
    # This shortcut returns selected values of first record.
    def select_first(column_names, options = {})
      select_values(column_names).first options
    end
    # This shortcut returns selected values of last record.
    def select_last(column_names, options = {})
      select_values(column_names).last options
    end

    protected
    def select_values(column_names) #:nodoc:
      distinct, column_names = ScopeMethods.split_column_names column_names
      scope = selects(*column_names)
      scope.uniq if distinct

      scope.values
    end

  end

  def initialize(proxy_scope, column_names) #:nodoc:
    super(proxy_scope, {}) do
      define_method(:values) { ValueExtractor.new self, column_names }
    end
    proxy_options[:select] = select_sql column_names
  end

  # Makes select DISTINCT and returns self.
  def uniq!
    proxy_options[:select][0, 9] == 'DISTINCT ' or
    proxy_options[:select][0, 0] = 'DISTINCT '

    self
  end

  protected
  def select_sql(column_names) #:nodoc:
    base_class = proxy_scope
    while base_class.class == ActiveRecord::NamedScope::Scope
      base_class = base_class.proxy_scope
    end
    con, qtn = base_class.connection, base_class.quoted_table_name
    sanitized_column_names = column_names.
        map { |cn| "#{ qtn }.#{ cn }" }
# Quoting of column names when distinct brakes ARs orm'ing!
#        map { |cn| "#{ qtn }.#{ con.quote_column_name cn }" }

    "#{ sanitized_column_names * ',' }"
  end

  class ValueExtractor
    def initialize(scope, column_names) #:nodoc:
      first_column_name = column_names.first
      @extracting = column_names.size == 1 ?
        lambda { |record| record[first_column_name] } :
        lambda { |record| record.attributes.values_at(*column_names) }

      @scope = scope
    end

    # Returns selected values of all records (in scope).
    def all(options = {})
      @scope.find(:all, options).map! { |record| @extracting[record] }
    end
    # Returns selected values of first record (in scope).
    def first(options = {})
      record = @scope.first options
      @extracting[record] if record
    end
    # Returns selected values of last record (in scope).
    def last(options = {})
      record = @scope.last options
      @extracting[record] if record
    end

  end

end
