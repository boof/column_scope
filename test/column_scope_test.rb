require 'test_helper'

module ColumnScopeTestHelper

  def self.content
    'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
  end

  class Item < ActiveRecord::Base
    named_scope :with_name, proc { |name|
      { :conditions => ['name = ?', name] }
    }
  end
  Item.create :name => 'foo', :value => 1, :content => content
  Item.create :name => 'bar', :value => 2, :content => content
  Item.create :name => 'baz', :value => 3, :content => content

end

class ColumnScopeTest < ActiveSupport::TestCase
  include ColumnScopeTestHelper

  test "verify that items name column is selected" do
    assert Item.selects(:names).proxy_options[:select] == '"items".name'
# Quoting of column names when distinct brakes ARs orm'ing!
#    assert Item.selects(:names).proxy_options[:select] == '"items"."name"'
  end
  test "verify that items name column is selected with distinct" do
    assert Item.selects(:distinct_name).proxy_options[:select] == 'DISTINCT "items".name'
# Quoting of column names when distinct brakes ARs orm'ing!
#    assert Item.selects(:distinct_name).proxy_options[:select] == 'DISTINCT "items"."name"'
  end
  test "verify that items name and items.value columns are selected" do
    assert Item.selects(:name_and_value).proxy_options[:select] == '"items".name,"items".value'
# Quoting of column names when distinct brakes ARs orm'ing!
#    assert Item.selects(:name_and_value).proxy_options[:select] == '"items"."name","items"."value"'
  end

  test "verify all names are foo bar and baz" do
    expectation = %w[foo bar baz]
    result1     = Item.select_all :names, :order => 'id'
    result2     = Item.selects(:names).values.all :order => 'id'

    assert_equal expectation, result1
    assert_equal expectation, result2
  end
  test "verify last value is 3" do
    expectation = 3
    result1     = Item.select_last :value, :order => 'id'
    result2     = Item.selects(:values).values.last :order => 'id'

    assert_equal expectation, result1
    assert_equal expectation, result2
  end
  test "verify first distinct content is the lorem ipsum" do
    expectation = ColumnScopeTestHelper.content
    result      = Item.select_first :distinct_content

    assert_equal expectation, result
  end
  test "verify find returns 3 and baz" do
    expectation = ['baz', 3]
    result1     = Item.with_name('baz').selects(:name_and_value).values.first
    result2     = Item.with_name('baz').rejects(:content_and_id).values.first

    assert_equal expectation, result1
    assert_equal expectation, result2
  end
  test "verify values returns values" do
    expectation = [
      ['foo', 1, ColumnScopeTestHelper.content],
      ['bar', 2, ColumnScopeTestHelper.content],
      ['baz', 3, ColumnScopeTestHelper.content]
    ]
    result = Item.values.all.each { |tuple| tuple.shift }

    assert_equal expectation, result
  end

end
