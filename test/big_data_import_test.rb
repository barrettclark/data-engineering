root = File.expand_path(File.dirname(__FILE__))
require File.join(root, 'test_helper')
require File.join(root, '..', 'big_data_import')

class BigDataImportTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    BigDataImport
  end

  def test_index
    get '/'
    assert last_response.redirect?
    follow_redirect!
    assert_equal "http://example.org/login", last_request.url
    assert last_response.ok?
  end
end
