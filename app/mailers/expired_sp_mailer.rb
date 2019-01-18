class ExpiredSpMailer < ApplicationMailer
  default from: 'from@example.com'

  def expired_email(user, sp_name)
    @user = user
    @sp = sp_name
    mail(to: @user.mail, subject: "The service pack #{sp_name.name} has expired")
  end
end
