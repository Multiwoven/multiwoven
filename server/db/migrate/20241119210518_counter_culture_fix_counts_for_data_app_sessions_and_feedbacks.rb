class CounterCultureFixCountsForDataAppSessionsAndFeedbacks < ActiveRecord::Migration[7.1]
  def change
    DataAppSession.counter_culture_fix_counts
    Feedback.counter_culture_fix_counts
  end
end
