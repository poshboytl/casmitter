require "test_helper"

class EpisodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @episode = episodes(:ep1)
  end

  test "should get index" do
    get episodes_url
    assert_response :success
  end

end
