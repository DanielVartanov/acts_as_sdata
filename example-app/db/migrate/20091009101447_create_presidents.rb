class CreatePresidents < ActiveRecord::Migration
  def self.up
    create_table :presidents do |t|
      t.string :first_name
      t.string :last_name
      t.integer :born_at
      t.integer :died_at
      t.integer :order
      t.string :party
      t.integer :term_started_at
      t.integer :term_ended_at
      t.timestamps
    end
  end

  def self.down
    drop_table :presidents
  end
end
