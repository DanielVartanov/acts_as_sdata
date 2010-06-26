create_table "sd_digest_entries", :force => true do |t|
  t.integer  "sd_digest_id"
  t.integer  "tick"
  t.string   "endpoint"
  t.integer  "conflict_priority"
  t.datetime "created_at"
  t.datetime "updated_at"
end

add_index "sd_digest_entries", ["sd_digest_id", "endpoint"], :name => "index_sd_digest_entries_on_sd_digest_id_and_endpoint", :unique => true

create_table "sd_digests", :force => true do |t|
  t.integer  "created_by_id"
  t.string   "sd_class"
  t.datetime "locked_at"
  t.datetime "created_at"
  t.datetime "updated_at"
end

add_index "sd_digests", ["created_by_id", "sd_class"], :name => "index_sd_digests_on_created_by_id_and_sd_class", :unique => true

create_table "sd_sync_runs", :force => true do |t|
  t.integer  "created_by_id"
  t.string   "tracking_id"
  t.string   "run_name"
  t.integer  "lock_version"
  t.string   "sd_class"
  t.string   "sync_mode"
  t.text     "objects_data",       :limit => 2147483647
  t.text     "target_digest_data"
  t.text     "source_digest_data"
  t.string   "phase"
  t.string   "phase_detail"
  t.datetime "created_at"
  t.datetime "updated_at"
end

create_table "sd_sync_states", :force => true do |t|
  t.integer  "sd_digest_id"
  t.integer  "sd_uuid_id"
  t.integer  "tick"
  t.datetime "created_at"
  t.datetime "updated_at"
  t.string   "endpoint"
end

add_index "sd_sync_states", ["sd_digest_id", "sd_uuid_id"], :name => "index_sd_sync_states_on_sd_digest_id_and_sd_uuid_id", :unique => true

create_table "sd_ticks", :force => true do |t|
  t.integer  "user_id"
  t.integer  "tick"
  t.datetime "locked_at"
  t.datetime "created_at"
  t.datetime "updated_at"
end

add_index "sd_ticks", ["user_id"], :name => "index_sd_ticks_on_user_id", :unique => true

create_table "sd_uuids", :force => true do |t|
  t.string   "sd_class"
  t.integer  "bb_model_id"
  t.string   "bb_model_type"
  t.string   "uuid"
  t.datetime "created_at"
  t.datetime "updated_at"
end

add_index "sd_uuids", ["sd_class", "bb_model_type", "uuid"], :name => "index_sd_uuids_on_sd_class_and_bb_model_type_and_uuid", :unique => true

