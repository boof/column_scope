require 'test_helper'

module ColumnScopeTestHelper

  def self.included(base)
    const_set :Item, Class.new(ActiveRecord::Base)
  end

  def content
    'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
  end
  def with_items
    Item.create :name => 'foo', :value => 1, :content => content
    Item.create :name => 'bar', :value => 2, :content => content
    Item.create :name => 'baz', :value => 3, :content => content
    yield if block_given?
  ensure
    Item.delete_all
  end

end

class ColumnScopeTest < ActiveSupport::TestCase
  include ColumnScopeTestHelper

  test "verify that items.name column is selected" do
    assert Item.selects(:names).proxy_options[:select] == '"items".name'
  end
  test "verify that items.name column is selected with distinct" do
    assert Item.selects(:distinct_name).proxy_options[:select] == 'DISTINCT "items".name'
  end
  test "verify that items.name and items.value columns are selected" do
    assert Item.selects(:name_and_value).proxy_options[:select] == '"items".name,"items".value'
  end

  test "verify all names are foo bar and baz" do
    with_items do
      expectation = %w[foo bar baz]
      result1     = Item.select_all :names, :order => 'id'
      result2     = Item.selects(:names).scoped(:order => 'id').values

      assert_equal expectation, result1
      assert_equal expectation, result2
    end
  end
  test "verify last value is 3" do
    with_items do
      expectation = 3
      result1     = Item.select_last :value, :order => 'id'
      result2     = Item.selects(:value).scoped(:order => 'id').values(:last)

      assert_equal expectation, result1
      assert_equal expectation, result2
    end
  end
  test "verify first distinct content is the lorem ipsum" do
    with_items do
      expectation = content
      result1     = Item.select_first :distinct_content

      assert_equal expectation, result1
    end
  end
  test "verify find returns 3 and baz" do
    with_items do
      expectation = [3, 'baz']
      result1     = Item.select_first :value_and_name, :conditions => {:name => 'baz'}
      result2     = Item.scoped(:conditions => {:name => 'baz'}).select_first(:value_and_name)

      assert_equal expectation, result1
      assert_equal expectation, result2
    end
  end

end
