class ServicePacksMailer < ApplicationMailer
  default from: 'op@example.com'

  def expired_email(user, service_pack)
    @user = user
    @sp = service_pack
    # binding.pry

    mail to: @user.mail, subject: "The service pack #{@sp.name} has expired" do |format|
      format.text
      format.html
    end
  end

  def notify_under_threshold1(user, service_pack)
    @user = user
    @sp = service_pack
    # binding.pry
    mail to: @user.mail, subject: "The service pack #{@sp.name} is running out" do |format|
      format.text
      format.html
    end
  end
end
