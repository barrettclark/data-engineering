root = File.expand_path(File.dirname(__FILE__))
require File.join(root, 'test_helper')
require File.join(root, '..', 'lib', 'db')

class SequelTestCase < Test::Unit::TestCase
  def run(*args, &block)
    Sequel::Model.db.transaction(:rollback=>:always){super}
  end
end

class PurchaserTest < SequelTestCase
  def test_new_purchaser
    purchaser = Purchaser.create(:purchaser_name => 'A Man')
    assert_equal 'A Man', purchaser.purchaser_name
    assert purchaser.id > 0
    assert_not_nil purchaser.created_at
  end
end

class ItemTest < SequelTestCase
  def test_unique_index
    values = {:item_description => 'Cool Stuff', :item_price => 1.0}
    Item.find_or_create(values)
    assert_raises Sequel::DatabaseError do
      Item.create(values)
    end
  end

  def test_clean_find_or_create
    values = {:item_description => 'Cool Stuff', :item_price => 1.0}
    item = Item.find_or_create(values)
    duplicate_item = Item.find_or_create(values)
    assert_equal item, duplicate_item
  end
end

class MerchantTest < SequelTestCase
  def test_new_merchant
    merchant = Merchant.create(:merchant_name => 'A Merchant', :merchant_address => '27 Second St.')
    assert_equal 'A Merchant', merchant.merchant_name
    assert merchant.id > 0
    assert_not_nil merchant.created_at
  end
end

class PurchaseHistoryTest < SequelTestCase
  def setup
    params = {
      :purchaser_name   => "Snake Plissken",
      :item_description => "$10 off $20 of food",
      :item_price       => "10.0",
      :purchase_count   => "2",
      :merchant_address => "987 Fake St",
      :merchant_name    => "Bob's Pizza"
    }
    @purchase_history = PurchaseHistory.import_text_file_record(params)
  end

  def test_import_text_file_record
    assert_equal 2, @purchase_history.purchase_count
  end
  def test_revenue
    assert_equal 20, @purchase_history.revenue
  end
  def test_import_text_file_record_with_data_to_normalize
    params = {
      :purchaser_name   => "Snake Plissken",
      :item_description => "$20 Sneakers for $5",
      :item_price       => "5.0",
      :purchase_count   => "4",
      :merchant_address => "123 Fake St",
      :merchant_name    => "Sneaker Store Emporium"
    }
    second_purchase_history = PurchaseHistory.import_text_file_record(params)
    assert_equal 4, second_purchase_history.purchase_count
    assert_equal @purchase_history.purchaser_id, second_purchase_history.purchaser_id
    assert_not_equal @purchase_history.merchant_id, second_purchase_history.merchant_id
  end
end
