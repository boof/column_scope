require 'test_helper'

class Item < ActiveRecord::Base
  named_scope :named, proc { |n| { :conditions => ['name = ?', n] } }
end
CONTENT = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'

Item.create :name => 'foo', :value => 1, :content => CONTENT
Item.create :name => 'bar', :value => 2, :content => CONTENT
Item.create :name => 'baz', :value => 3, :content => CONTENT

class ColumnScopeTest < ActiveSupport::TestCase

  test "verify that items name column is selected" do
    assert_equal '"items"."name"', Item.selects(:name).proxy_options[:select]
  end
  test "verify that items name column is selected with distinct" do
    assert_equal 'DISTINCT "items"."name"', Item.selects(:name).uniq!.proxy_options[:select]
  end
  test "verify that items name and items value columns are selected" do
    expectation = '"items"."name","items"."value"'
    result1     = Item.selects(:name, :value).proxy_options[:select]
    result2     = Item.rejects(:id, :content, :timestamps).proxy_options[:select]

    assert_equal expectation, result1
    assert_equal expectation, result2
  end

  test "verify select only name results in an array with foo bar and baz" do
    expectation = %w[foo bar baz]
    result1     = Item.select_all :name, :order => 'id'
    result2     = Item.selects(:name).values.all :order => 'id'

    assert_equal expectation, result1
    assert_equal expectation, result2
  end
  test "verify last value is 3" do
    expectation = 3
    result1     = Item.select_last :value, :order => 'id'
    result2     = Item.selects(:value).values.last :order => 'id'

    assert_equal expectation, result1
    assert_equal expectation, result2
  end
  test "verify first distinct content is the lorem ipsum" do
    expectation = CONTENT
    result      = Item.select_first :distinct_content

    assert_equal expectation, result
  end
  test "verify find returns 3 and baz" do
    expectation = ['baz', 3]
    result1     = Item.named('baz').selects(:name, :value).values.first
    result2     = Item.named('baz').rejects(:content, :id, :timestamps).values.first
    result3     = Item.named('baz').select_first(:name__value)

    assert_equal expectation, result1
    assert_equal expectation, result2
    assert_equal expectation, result3
  end
  test "verify values returns values ordered" do
    expectation = [['foo',1,CONTENT],['bar',2,CONTENT],['baz',3,CONTENT]]
    # select values and drop id and timestamps
    result = Item.values.all.each { |tpl| tpl.shift; tpl.pop; tpl.pop }

    assert_equal expectation, result
  end

end
