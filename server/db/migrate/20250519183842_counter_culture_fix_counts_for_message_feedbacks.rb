class CounterCultureFixCountsForMessageFeedbacks < ActiveRecord::Migration[7.1]
  def change
    MessageFeedback.counter_culture_fix_counts
  end
end
