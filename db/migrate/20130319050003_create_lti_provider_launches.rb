class CreateLtiProviderLaunches < ActiveRecord::Migration
  def change
    create_table "lti_provider_launches", :force => true do |t|
      t.string   "canvas_url"
      t.string   "nonce"
      t.text     "provider_params"

      t.timestamps
    end
  end
end
