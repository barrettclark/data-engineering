if ENV['RACK_ENV'] == 'production' && ENV['SHARED_DATABASE_URL']
  # This is heroku
  DB = Sequel.connect(ENV['SHARED_DATABASE_URL'])
else
  settings = YAML::load(File.open(File.join(File.dirname(__FILE__), '..', 'config', 'database.yml')))
  config = settings[ENV['RACK_ENV']]
  DB = Sequel.postgres(
    :host     => config['host'],
    :port     => config['port'],
    :user     => config['user'],
    :password => config['password'],
    :database => config['database']
  )
end

# Create the tables if they don't exist
DB.create_table? :imports do
  primary_key :id
  column :filename, :text
  column :created_at, :timestamp
end

DB.create_table? :purchasers do
  primary_key :id
  column :purchaser_name, :text
  column :created_at, :timestamp
end

DB.create_table? :items do
  primary_key :id
  column :item_description, :text
  column :item_price, :real
  column :created_at, :timestamp

  index [:item_description, :item_price], {:unique => true}
end

DB.create_table? :merchants do
  primary_key :id
  column :merchant_name, :text
  column :merchant_address, :text
  column :created_at, :timestamp
end

DB.create_table? :purchase_histories do
  primary_key :id
  column :purchaser_id, :integer
  column :item_id, :integer
  column :purchase_count, :integer
  column :merchant_id, :integer
  column :created_at, :timestamp
end

# Model the data access and persistence
module BaseModel
  def before_create
    self.created_at ||= Time.now.utc
    super
  end
end

class Import < Sequel::Model
  include BaseModel
end

class Purchaser < Sequel::Model
  include BaseModel
  one_to_many :purchase_histories
end

class Item < Sequel::Model
  include BaseModel
  one_to_many :purchase_histories
end

class Merchant < Sequel::Model
  include BaseModel
  one_to_many :purchase_histories
end

class PurchaseHistory < Sequel::Model
  include BaseModel
  many_to_one :purchaser
  many_to_one :item
  many_to_one :merchant

  def self.import_text_file_record(params)
    purchaser = Purchaser.find_or_create(:purchaser_name => params[:purchaser_name])
    item = Item.find_or_create(:item_description => params[:item_description], :item_price => params[:item_price].to_f)
    merchant = Merchant.find_or_create(:merchant_name => params[:merchant_name], :merchant_address => params[:merchant_address])
    create(:purchaser_id => purchaser.id, :item_id => item.id, :merchant_id => merchant.id, :purchase_count => params[:purchase_count].to_i)
  end

  def revenue
    item.item_price * purchase_count
  end
end
