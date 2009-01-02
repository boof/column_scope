# = ColumnScope
#
# To create a column scope invoke either <tt>selects</tt> or <tt>rejects</tt>
# on a scope (which is either a model or a named scope) with the column names
# you want to select:
#
#   Item.selects :name, :value
#       # => "items"."name","items"."value"
#   Item.rejects :id, :content, :timestamps
#       # => "items"."name","items"."value"
#
# To make the select <tt>DISTICT</tt> you must invoke <tt>uniq!</tt> on the
# column scope.
#
#   Item.selects(:name).uniq! # => DISTINCT "items"."name"
#
# When you invoke <tt>find</tt> on a scope that is chained with a column scope
# only the named columns are selected by SQL.
# This gives you the instances of your model with the selected attributes
# assigned.
#
# If you only want the plain values invoke <tt>values</tt> on a scope before
# you invoke <tt>all</tt>, <tt>first</tt> or <tt>last</tt>.
#
# == Shortcuts
#
# select_all, select_first and select_last are shortcuts. They accept a symbol
# (or string) in the following format:
#
#   :name
#   :name__value      # => "name","value"
#   :distinct_name    # => DISTINCT "name"
#   :name__timestamps # => "name","created_at","updated_at"
module ActiveRecord::NamedScope
  class ColumnScope < Scope

    def self.split__column_names(column_names) #:nodoc:
      column_names  = column_names.to_s
      column_names  = column_names.split('__')
      first_cn      = column_names.first
      distinct      = first_cn[0, 9] = '' if first_cn[0, 9] == 'distinct_'

      [ distinct, column_names ]
    end
    def self.stringify_names(names) #:nodoc:
      stringified_names = []
      names.length.times do |i|
        unless names[i].to_sym == :timestamps
          stringified_names << names[i].to_s
        else
          stringified_names << 'created_at'
          stringified_names << 'updated_at'
        end
      end
      stringified_names
    end

    module ScopeMethods

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
      # you load the records with <tt>all</tt>, <tt>first</tt> or
      # <tt>last</tt>.
      def selects(*selected_cns)
        selected_cns = ColumnScope.stringify_names selected_cns
        ColumnScope.new self, selected_cns
      end
      # Returns a ColumnScope w/o named columns.
      #
      # To get the selected values invoke <tt>values</tt> on this scope before
      # you load the records with <tt>all</tt>, <tt>first</tt>
      # or <tt>last</tt>.
      #
      # Note: The attribute order is the same as in <tt>column_names</tt> w/o
      # the named columns.
      def rejects(*rejected_cns)
        rejected_cns = ColumnScope.stringify_names rejected_cns
        ColumnScope.new self, column_names - rejected_cns
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
        distinct, column_names = ColumnScope.split__column_names column_names
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
      select = proxy_options[:select]
      select.insert 0, 'DISTINCT ' if select[0, 9] != 'DISTINCT '

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
          map { |cn| "#{ qtn }.#{ con.quote_column_name cn }" }

      "#{ sanitized_column_names * ',' }"
    end

    class ValueExtractor

      # FIXME: It would be nice to have the attributes taken directly from a
      # array (connection.select_rows) without loading them into a model.

      def initialize(scope, column_names) #:nodoc:
        @column_names, @scope = column_names, scope
        @extract_method_sym   = :extract_multiple_columns

        if column_names.size == 1
          @first_column_name  = column_names.first
          @extract_method_sym = :extract_single_column
        end
      end

      # Returns selected values of all records (in scope).
      def all(opts = {})
        @scope.find(:all, opts).map! { |r| send @extract_method_sym, r }
      end
      # Returns selected values of first record (in scope).
      def first(opts = {})
        if r = @scope.first(opts) then send @extract_method_sym, r end
      end
      # Returns selected values of last record (in scope).
      def last(opts = {})
        if r = @scope.last(opts) then send @extract_method_sym, r end
      end
    
      def find(*args) #:nodoc:
        raise NotImplementedError
      end

      protected
      def extract_single_column(record) #:nodoc:
        record[@first_column_name]
      end
      def extract_multiple_columns(record) #:nodoc:
        record.attributes.values_at(*@column_names)
      end

    end

  end
end
