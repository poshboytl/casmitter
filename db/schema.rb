# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_02_19_235923) do
  create_table "attendances", force: :cascade do |t|
    t.integer "attendee_id"
    t.integer "episode_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
  end

  create_table "attendees", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.text "desc"
    t.string "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar_url"
  end

  create_table "episodes", force: :cascade do |t|
    t.string "name"
    t.string "file_uri"
    t.text "desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "summary"
    t.integer "status", default: 0, null: false
    t.string "keywords"
    t.integer "number", default: 999, null: false
    t.string "slug"
  end
end
