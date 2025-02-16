require "application_system_test_case"

class EpisodesTest < ApplicationSystemTestCase
  setup do
    @episode = episodes(:one)
  end

  test "visiting the index" do
    visit episodes_url
    assert_selector "h1", text: "Episodes"
  end

  test "should create episode" do
    visit episodes_url
    click_on "New episode"

    fill_in "Desc", with: @episode.desc
    fill_in "File uri", with: @episode.file_uri
    fill_in "Name", with: @episode.name
    click_on "Create Episode"

    assert_text "Episode was successfully created"
    click_on "Back"
  end

  test "should update Episode" do
    visit episode_url(@episode)
    click_on "Edit this episode", match: :first

    fill_in "Desc", with: @episode.desc
    fill_in "File uri", with: @episode.file_uri
    fill_in "Name", with: @episode.name
    click_on "Update Episode"

    assert_text "Episode was successfully updated"
    click_on "Back"
  end

  test "should destroy Episode" do
    visit episode_url(@episode)
    click_on "Destroy this episode", match: :first

    assert_text "Episode was successfully destroyed"
  end
end
