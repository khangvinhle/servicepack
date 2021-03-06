# freeze_literal_string: true
class ServicePack < ApplicationRecord
  # put feature switch here
  # SWITCH_USE_UNASSIGNED_CHECK = 1

  before_create :default_remained_units
  after_save :revoke_all_assignments, if: :expired? # last-ditch effort, should be done by cron or jobs
  after_save :knock_out, if: :used_up?, on: :consumption

  has_many :assigns, dependent: :delete_all
  has_many :active_assignments, -> {where('assigned = ? and unassign_date > ?', true, Date.today)}, class_name: 'Assign'
  has_many :projects, through: :assigns
  has_many :consuming_projects, through: :active_assignments, source: :project
  has_many :mapping_rates, inverse_of: :service_pack, dependent: :delete_all
  # Nothing can be done in TimelogController
  has_many :time_entries, dependent: :nullify # disassociate immediately after deleting
  has_many :time_entry_activities, through: :mapping_rates, source: :activity
  has_many :service_pack_entries, inverse_of: :service_pack, dependent: :delete_all
  # :source is the name of association on the "going out" side of the joining table
  # (the "going in" side is taken by this association)
  # example: User has many :pets, Dog is a :pets and has many :breeds. Breeds have ...
  # Rails will look for :dog_breeds by default! (e.g. User.pets.dog_breeds)
  # sauce: https://stackoverflow.com/a/4632472

  accepts_nested_attributes_for :mapping_rates, allow_destroy: true, reject_if: ->(attributes) {attributes['units_per_hour'].blank?}

  validates_presence_of :name, :threshold1, :threshold2, :expired_date, :started_date, :total_units

  validates_uniqueness_of :name, on: [:create, :update]
  # https://rubular.com/r/CCtRDRq9jDuMmb

  validates_format_of :name, with: /\A[^_`~^*\\+=\{\}\|\\;"'<>.\/]+\Z/, message: 'has invalid character(s)', on: [:create, :update]
  validates_email_format_of :additional_notification_email, allow_blank: true, on: [:create, :update]

  validates_numericality_of :total_units, greater_than: 0
  validates_numericality_of :threshold1, :threshold2, only_integer: true, greater_than: 0

  validate :threshold2_is_greater_than_threshold1, on: [:create, :update]
  validate :end_after_start, on: [:create, :update]
  validate :must_not_expire_in_the_past, on: [:create, :update]
  validate :threshold1_is_greater_than_total_units
  validate :threshold2_is_greater_than_total_units

  scope :assigned, -> {where("id IN (#{Assign.active.select(:service_pack_id).to_sql})")}
  scope :availables, -> {where('remained_units > 0 and expired_date >= ?', Date.today)}
  scope :notifiable, ->(thresno) {where("remained_units <= threshold#{thresno}")}

  def default_remained_units
    self.remained_units = total_units
  end

  def revoke_all_assignments
    assigns.where(assigned: true).update_all(assigned: false, unassign_date: Date.today)
  end

  def grant(units)
    self.total_units += units
    self.remained_units += units
    self
  end

  def reset_threshold_notified_flag
    self.threshold1_notified = false if self.remained_units > self.threshold1
    self.threshold2_notified = false if self.remained_units > self.threshold2
    self
  end

  ### CHECKERS ###
  def expired?
    true if Time.now > expired_date
  end

  def used_up?
    true if remained_units <= 0
  end

  def unavailable? # available SP might not be assignable
    used_up? || expired?
  end

  def available?
    !unavailable?
  end

  def is_notify?
    # so what is with the two thresholds!?
    dates_to_notify = (expired_date - Date.today).to_i
    dates_to_notify.between?(1, 2)
  end

  def assigned?
    active_assignments.exists?
  end

  # def total_unit_updatable?(new_value, old_value = total_units)
  #   # old_value=total_units
  #   if new_value > old_value
  #     true
  #   elsif new_value == old_value
  #     true
  #   elsif new_value < old_value
  #     unit_subtract_number = old_value - new_value
  #     !(remained_units < unit_subtract_number)
  #   end
  # end

  ### END CHECKERS ###

  # FOR TESTING ONLY
  def expired_notification # send to the first user in the first record in the DB
    if expired?
      user = User.first
      ServicePacksMailer.expired_email(user, self).deliver_later
    end
  end

  def cron_send_specific
    # modify the User param
    ServicePacksMailer.expired_email(User.last, ServicePack.first).deliver_later
  end

  # def self.cron_send_default
  #   # modify the User param
  #   ServicePack.find_each do |sp|
  #     ExpiredSpMailer.expired_email(User.last, sp).deliver_now
  #   end
  # end
  # END TESTING ONLY

  ### START CRON JOBS ###
  # modify User param first
  # deliver_later doesn't work

=begin
  def self.check_expired_sp
    ServicePack.find_each do |sp|
      ServicePacksMailer.expired_email(User.last, sp).deliver_now if sp.expired?
    end
  end

  # will be replaced
  # # notify immediately at entries
  #   def self.check_used_up
  #     ServicePack.find_each do |sp|
  #       ServicePacksMailer.used_up_email(User.last, sp).deliver_now if sp.used_up?
  #     end
  #   end

  def self.check_threshold1
    ServicePack.notifiable(1).find_each do |sp|
      ServicePacksMailer.notify_under_threshold1(User.last, sp).deliver_now
    end
  end

  def self.check_threshold2
    ServicePack.notifiable(2).find_each do |sp|
      ServicePacksMailer.notify_under_threshold2(User.last, sp).deliver_now
    end
  end
=end

  ### END CRON JOBS ###

  private

  def threshold1_is_greater_than_total_units
    @errors.add(:threshold1, 'must be smaller than total units') if threshold1 >= total_units
  end

  def threshold2_is_greater_than_total_units
    @errors.add(:threshold2, 'must be smaller than total units') if threshold2 >= total_units
  end

  def threshold2_is_greater_than_threshold1
    @errors.add(:threshold2, 'must be less than threshold 1') if threshold2 >= threshold1
  end

  def end_after_start
    @errors.add(:expired_date, 'must be after start date') if expired_date < started_date
  end

  def must_not_expire_in_the_past
    @errors.add(:expired_date, 'must not be in the past') if expired_date < Date.today
  end

  def knock_out
    revoke_all_assignments
    Delayed::Job.enqueue UsedUpServicePackJob.new(self)
  end
end
