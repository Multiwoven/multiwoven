# frozen_string_literal: true

class CreateModelPricings < ActiveRecord::Migration[7.2]
  def change
    create_table :model_pricings do |t|
      t.string :provider, null: false
      t.string :model, null: false
      t.decimal :input_rate, precision: 16, scale: 10, null: false, default: 0
      t.decimal :output_rate, precision: 16, scale: 10, null: false, default: 0
      t.decimal :cache_read_rate, precision: 16, scale: 10, null: false, default: 0
      t.decimal :cache_write_rate, precision: 16, scale: 10, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.integer :source, null: false, default: 0
      t.datetime :effective_from, null: false
      t.datetime :effective_to

      t.timestamps

      t.index %i[provider model effective_from]
      t.index %i[provider model], unique: true, where: "effective_to IS NULL",
                                  name: "index_model_pricings_in_force"
    end
  end
end
