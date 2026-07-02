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

ActiveRecord::Schema[7.2].define(version: 2026_07_02_231702) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "required_staff_settings", force: :cascade do |t|
    t.integer "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.integer "required_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shift_requests", force: :cascade do |t|
    t.bigint "staff_id", null: false
    t.date "request_date"
    t.integer "request_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.index ["staff_id"], name: "index_shift_requests_on_staff_id"
  end

  create_table "shift_rules", force: :cascade do |t|
    t.integer "day_of_week"
    t.time "start_time"
    t.time "end_time"
    t.integer "staff_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
    t.integer "staff_id"
    t.string "batch_id"
  end

  create_table "staffs", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_settings", force: :cascade do |t|
    t.integer "day_of_week"
    t.time "open_time"
    t.time "close_time"
    t.boolean "is_closed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_holiday_open"
  end

  add_foreign_key "shift_requests", "staffs"
end
