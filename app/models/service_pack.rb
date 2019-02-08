class ServicePack < ApplicationRecord
  before_create :default_remained_units
  after_save :revoke_all_assignments, if: :expired? # should be time-based only.
  has_many :assigns, dependent: :destroy
  has_many :projects, through: :assigns
  has_many :mapping_rates, inverse_of: :service_pack, dependent: :destroy
  has_many :time_entry_activities, through: :mapping_rates, source: :activity
  has_many :service_pack_entries, inverse_of: :service_pack, dependent: :destroy
  # :source is the name of association on the "going out" side of the joining table
  # (the "going in" side is taken by this association)
  # example: User has many :pets, Dog is a :pets and has many :breeds. Breeds have ...
  # Rails will look for :dog_breeds by default! (e.g. User.pets.dog_breeds)
  # sauce: https://stackoverflow.com/a/4632472

  accepts_nested_attributes_for :mapping_rates, allow_destroy: true, reject_if: lambda {|attributes| attributes['units_per_hour'].blank?}


  validates_presence_of :name, :threshold1, :threshold2, :expired_date, :started_date, :total_units

  validates_uniqueness_of :name

  validates_numericality_of :total_units, only_integer: true, greater_than: 0
  validates_numericality_of :threshold1, :threshold2, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, :only_integer => false

  validate :threshold2_is_greater_than_threshold1
  validate :end_after_start
  validate :must_not_expire_in_the_past

  scope :assignments, ->{joins(:assigns).where(assigned: true)}
  scope :availables, ->{where("remained_units > 0 and expired_date >= ?", Date.today)}
  # scope :gone_low, ->{where('remained_units <= total_units / 100.0 * threshold1')}


  def default_remained_units
    self.remained_units = self.total_units
  end

  def revoke_all_assignments 
    assignments.update_all(assigned: false, unassign_date: Date.today)
  end

  def expired?
    true if Time.now > expired_date
  end

  def used_up?
    true if remained_units <= 0
  end

  def unavailable? # available SP might not be assignable
    used_up? && expired?
  end

  def available?
    !unavailable?
  end

  # FOR TESTING ONLY
  def expired_notification # send to the first user in the first record in the DB
    if expired?
      user = User.first
      ExpiredSpMailer.expired_email(user, self).deliver_later
    end
  end

  def cron_send_specific
    # modify the User param
    ExpiredSpMailer.expired_email(User.last, self).deliver_later
  end

  def self.cron_send_default
    # modify the User param
    ServicePack.find_each do |sp|
      ExpiredSpMailer.expired_email(User.last, sp).deliver_later
    end
  end
  # END TESTING ONLY

  def self.gone_too_low_notification
    ServicePack.gone_low.includes(:assigns).where(assigns: {active: true}) do |assignment|

    end
    all_active_assignment = ServicePack.includes(:assigns).references(:assigns).where(assigns: {active: true})
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

	def must_not_expire_in_the_past
		@errors.add(:expired_date, 'must not be in the past') if expired_date < Date.today
	end
end
