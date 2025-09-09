class AddConfigurableToVisualComponents < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_reference :visual_components,
                  :configurable,
                  polymorphic: true,
                  type: :string,
                  null: true,
                  index: { algorithm: :concurrently }
  end
end
