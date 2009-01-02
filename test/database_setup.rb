ActiveRecord::Base.colorize_logging = false
#ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new STDOUT

ActiveRecord::Base.establish_connection(
 :adapter => 'sqlite3',
 :database  => ':memory:'
)

ActiveRecord::Base.connection.instance_eval do
  create_table :items do |t|
    t.string :name
    t.integer :value
    t.text :content
    t.timestamps
  end
end

# ... maybe I should Stub a database Adapter?
