require 'test_helper'

class BCATest < Minitest::Test
  def setup
    @bca = BCA::Client.new ENV['BCA_USER_ID'], ENV['BCA_PASSWORD']
  end

  def test_that_it_has_a_version_number
    refute_nil ::BCA::VERSION
  end

  def test_it_fails_when_logging_in
    result, = @bca.login
    assert !result
  end

  def teardown
    @bca.logout
  end
end
