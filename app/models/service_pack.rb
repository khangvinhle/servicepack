class ServicePack < ApplicationRecord
  before_create :default_remained_units
  has_many :assigns
  has_many :projects, through: :assigns
  has_many :mapping_rates, inverse_of: :service_pack, dependent: :destroy
=======
  has_many :mapping_rates, dependent: :destroy, inverse_of: :service_pack
>>>>>>> master
  has_many :time_entry_activities, through: :mapping_rates, source: :activity
  # :source is the name of association on the "going out" side of the joining table
  # (the "going in" side is taken by this association)
  # example: User has many :pets, Dog is a :pets and has many :breeds. Breeds have ...
  # Rails will look for :dog_breeds by default! (e.g. User.pets.dog_breeds)
  # sauce: https://stackoverflow.com/a/4632472

  accepts_nested_attributes_for :mapping_rates, allow_destroy: true,  reject_if: lambda {|attributes| attributes['units_per_hour'].blank?}


  validates_presence_of :name, :threshold1, :threshold2, :expired_date, :started_date, :total_units
  
  validates_uniqueness_of :name

  validates_numericality_of :total_units, only_integer: true, greater_than: 0
  validates_numericality_of :threshold1, :threshold2, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, :only_integer => false

  validate :threshold2_is_greater_than_threshold1
  validate :end_after_start

  scope :assignments, ->{assigns.where(assigned: true)}


  def default_remained_units
    self.remained_units = self.total_units
  end

  def expired?
    true if Time.now > expired_date
  end

  def used_up?
    true if remained_units <= 0
  end

  def unavailable? # available SP might not be assignable - TODO: solved by another module
    used_up? && expired?
  end

  def available?
    !unavailable?
  end

  def assigned?
    assigns.where(assigned: true).exists?
  end

  def assignments
    assigns.where(assigned: true)
  end

  private

    def threshold2_is_greater_than_threshold1
      @errors.add(:threshold2, 'must be less than threshold 1') if threshold2 > threshold1
    end

    def end_after_start
      @errors.add(:expired_date, 'must be after start date') if expired_date < started_date
    end
end
