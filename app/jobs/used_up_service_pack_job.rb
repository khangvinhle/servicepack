class UsedUpServicePackJob < ApplicationJob
  # queue_as :default
  attr_reader :sp

  def initialize(sp)
    @sp = sp
  end

  def perform
    User.where(admin: true).each do |user|
      ServicePacksMailer.used_up_email(user.mail, @sp).deliver_later
    end
    ServicePacksMailer.notify_under_threshold1(@sp.additional_notification_email, @sp)
  end

end
