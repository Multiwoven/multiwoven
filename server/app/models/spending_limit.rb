# frozen_string_literal: true

class SpendingLimit < ApplicationRecord
  MIN_ALERT_THRESHOLD = 1
  MAX_ALERT_THRESHOLD = 99
  DEFAULT_ALERT_THRESHOLDS = [80, 90].freeze
  ALLOCATION_NAME = "Workspace allocation"
  ALWAYS_ALERT_AT = 100
  # An empty list means "every one of them", so these carry no null state.
  TARGET_FILTERS = %i[scope_ids providers models].freeze
  MAX_TARGET_FILTER_ENTRIES = 100

  belongs_to :organization
  belongs_to :workspace
  belongs_to :created_by, class_name: "User", optional: true

  has_many :spending_limit_counters, dependent: :destroy

  # Explicit values: index_spending_limits_one_allocation_per_workspace is partial on level = 1.
  enum :level, { limit: 0, allocation: 1 }, scopes: false
  enum :scope_type, %i[workspace workflow data_app user role]
  enum :limit_type, %i[cost tokens both]
  enum :period, %i[daily weekly monthly]
  enum :action_on_exhaust, %i[warn block]

  before_validation :start_counting, on: :create
  before_validation :normalize_alert_thresholds
  before_validation :normalize_target_filters

  validates :name, presence: true, uniqueness: { scope: :workspace_id }
  # The partial unique index is the real guarantee; this only turns the ordinary case into a 422.
  validates :workspace_id, uniqueness: { conditions: -> { where(level: :allocation) },
                                         message: "already has an allocation" }, if: :allocation?
  validates :cost_limit, presence: true, if: -> { cost? || both? }
  validates :token_limit, presence: true, if: -> { tokens? || both? }
  validates :cost_limit, numericality: { greater_than: 0 }, allow_nil: true
  validates :token_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates(*TARGET_FILTERS, length: { maximum: MAX_TARGET_FILTER_ENTRIES,
                                       too_long: "has too many entries (maximum is #{MAX_TARGET_FILTER_ENTRIES})" })
  validate :alert_thresholds_in_range
  validate :allocation_name_is_reserved

  def meters_cost?
    cost? || both?
  end

  def meters_tokens?
    tokens? || both?
  end

  def percent_used(snapshot)
    percentages = []
    percentages << ratio(snapshot&.spent_cost || 0, cost_limit) if meters_cost?
    percentages << ratio(snapshot&.spent_tokens || 0, token_limit) if meters_tokens?
    percentages.compact.max || 0
  end

  # LedgerScope clamps its sum to this.
  def restart_counting!
    update_columns(counting_started_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  # Recovery reads this; settlement cannot, because a crossing is only visible in one upsert.
  def thresholds_reached(counter)
    used = percent_used(counter)
    alerting_thresholds.select { |threshold| used >= threshold }
  end

  def thresholds_crossed(before, after)
    wanted = alerting_thresholds
    from = percent_used(before)
    to = percent_used(after)
    wanted.select { |threshold| from < threshold && to >= threshold }
  end

  scope :limits, -> { where(level: :limit) }
  scope :allocations, -> { where(level: :allocation) }
  scope :enabled, -> { where(enabled: true) }
  scope :for_workspace, ->(workspace_id) { where(workspace_id:) }

  # The array type turns a lone string into [] before any callback sees it, so wrap in the writer.
  TARGET_FILTERS.each do |field|
    define_method(:"#{field}=") { |value| super(Array.wrap(value)) }
  end

  private

  def alerting_thresholds
    (Array(alert_thresholds).map(&:to_i) + [ALWAYS_ALERT_AT]).uniq.sort
  end

  def start_counting
    self.counting_started_at ||= Time.current
  end

  def ratio(spent, cap)
    return nil if cap.blank? || cap.to_d <= 0

    (spent.to_d / cap.to_d) * 100
  end

  # [] means no early warnings and is kept; only nil takes the default.
  def normalize_alert_thresholds
    return self.alert_thresholds = DEFAULT_ALERT_THRESHOLDS.dup if alert_thresholds.nil?
    return unless alert_thresholds.is_a?(Array) && alert_thresholds.all?(Numeric)

    self.alert_thresholds = alert_thresholds.map(&:to_i).uniq.sort
  end

  def normalize_target_filters
    TARGET_FILTERS.each do |field|
      entries = Array.wrap(public_send(field)).map { |entry| entry.to_s.strip }.reject(&:empty?).uniq
      public_send(:"#{field}=", entries)
    end
  end

  # The (workspace_id, name) index is level agnostic, so a limit may not take the allocation's name.
  def allocation_name_is_reserved
    return unless limit?
    return unless name.to_s.strip.casecmp?(ALLOCATION_NAME)

    errors.add(:name, "is reserved for the workspace allocation")
  end

  # The integer[] cast leaves a nested array alone, and that answers neither to_i nor between?.
  def alert_thresholds_in_range
    return errors.add(:alert_thresholds, "must be a list of numbers") unless alert_thresholds.is_a?(Array)
    return if alert_thresholds.blank?
    return errors.add(:alert_thresholds, "must be a list of numbers") unless alert_thresholds.all?(Integer)
    return if alert_thresholds.all? { |threshold| threshold.between?(MIN_ALERT_THRESHOLD, MAX_ALERT_THRESHOLD) }

    errors.add(:alert_thresholds, "must be between #{MIN_ALERT_THRESHOLD} and #{MAX_ALERT_THRESHOLD}")
  end
end
