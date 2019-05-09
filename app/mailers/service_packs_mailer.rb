class ServicePacksMailer < ApplicationMailer
  def expired_email(email, service_pack)
    # @user = user
    @sp = service_pack
    # binding.pry

    mail to: email, subject: "The service pack #{@sp.name} has expired" do |format|
      format.text
      format.html
    end
  end

  def notify_under_threshold1(email, service_pack)
    # @user = user
    @sp = service_pack
    # binding.pry
    mail to: email, subject: "The service pack #{@sp.name} is running out" do |format|
      format.text
      format.html
    end
  end

  def notify_under_threshold2(email, service_pack)
    # @user = user
    @sp = service_pack
    # binding.pry
    mail to: email, subject: "The service pack #{@sp.name} is running out" do |format|
      format.text
      format.html
    end
  end

  def used_up_email(email, service_pack)
    # @user = user
    @sp = service_pack

    mail to: email, subject: "The service pack #{@sp.name} ran out of units" do |format|
      format.text
      format.html
    end

  end
end
