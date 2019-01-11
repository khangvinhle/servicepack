class ServicePack < ApplicationRecord
  
  has_many :assigns
  has_many :projects, through: :assigns

  has_many :mapping_rates
  has_many :time_entry_activities, through: :mapping_rates, source: :activity

  # validates_presence_of :name, :threshold1, :threshold2, :expired_date, :start_date, :total_units, :other, :management, :developent, :support, :testing, :specification
  validates_uniqueness_of :name
  validates_numericality_of :total_units, only_integer: true, greater_than: 0
  # validates_numericality_of :support, :specification, :developent, :testing, :management, :other, only_integer: true, greater_than: 0
  
  validates_numericality_of :threshold1, :threshold2, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, :only_integer => false
  
  validate :threshold2_is_greater_than_threshold1
  validate :end_after_start


  def default_remained_units
      self.remained_units = self.total_units
  end

  private

    def expired?
      true if Time.now > expired_date
    end

    def threshold2_is_greater_than_threshold1
      @errors.add(:threshold2, 'must be less than threshold 1') if threshold2 > threshold1
    end

    def end_after_start
      @errors.add(:expired_date, 'must be after start date') if expired_date < started_date
    end



end
