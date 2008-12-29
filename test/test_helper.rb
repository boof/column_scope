require 'test/unit'

require 'rubygems'
require 'active_support'
require 'active_support/test_case'

module Rails

  LOGGER = ActiveSupport::BufferedLogger.new STDOUT
  def logger
    LOGGER
  end
  ROOT = File.dirname __FILE__
  def root
    ROOT
  end

  module_function :logger, :root

end
require 'active_record'

require "#{ File.dirname __FILE__ }/database_setup"
require "#{ File.dirname __FILE__ }/../init.rb"
