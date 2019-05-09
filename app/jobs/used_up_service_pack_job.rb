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
    ServicePacksMailer.used_up_email(@sp.additional_notification_email, @sp).deliver_later unless @sp.additional_notification_email.nil?
  end

end
