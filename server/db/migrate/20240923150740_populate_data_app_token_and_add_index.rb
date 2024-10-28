class PopulateDataAppTokenAndAddIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    DataApp.find_each do |data_app|
      begin
        unique_token = generate_unique_token
        data_app.update!(data_app_token: unique_token)
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Failed to update DataApp #{data_app.id}: #{e.message}"
      end
    end

    add_index :data_apps, :data_app_token, unique: true, algorithm: :concurrently
  end


  def down
    remove_index :data_apps, :data_app_token if index_exists?(:data_apps, :data_app_token)
  end

  private

  def generate_unique_token
    loop do
      token = Devise.friendly_token
      break token unless DataApp.exists?(data_app_token: token)
    end
  end
end
