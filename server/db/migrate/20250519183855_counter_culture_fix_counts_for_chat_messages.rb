class CounterCultureFixCountsForChatMessages < ActiveRecord::Migration[7.1]
  def change
    ChatMessage.counter_culture_fix_counts
  end
end
