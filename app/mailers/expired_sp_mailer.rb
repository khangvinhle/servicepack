class ExpiredSpMailer < ApplicationMailer

  def expired_email(user, service_pack)
    @user = user
    @sp = service_pack
    mail(to: @user.mail, subject: "The service pack #{@sp.name} has expired")
  end
end
