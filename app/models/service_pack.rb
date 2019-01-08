class ServicePack < ApplicationRecord
  has_many :assigns
  has_many :projects, through: :assigns
  has_many :time_entry_activities, through: :mapping_rates

  before_create :set_remain_units

  validates_presence_of :name, :threshold1, :threshold2, :expired_date, :start_date, :total_units, :other, :management, :development, :support, :testing, :specification
  validates_uniqueness_of :name
  validates_numericality_of :total_units, only_integer: true, greater_than: 0
  validates_numericality_of :support, :specification, :development, :testing, :management, :other, only_integer: true, greater_than: 0
  validates_numericality_of :threshold1, :threshold2, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, :only_integer => false
  validates_numericality_of :threshold1, :threshold2, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, :only_integer => false
  validate :threshold2_is_greater_than_threshold1
  validate :end_after_start

  private

  def expired?
    true if Time.now > expired_date
  end

  def threshold2_is_greater_than_threshold1
    @errors.add(:threshold2, 'must be less than threshold 1') if threshold2 > threshold1
  end

  def end_after_start
    @errors.add(:expired_date, 'must be after start date') if expired_date < start_date
  end

  def set_remain_units
    self.remain_units = self.total_units
  end
end
