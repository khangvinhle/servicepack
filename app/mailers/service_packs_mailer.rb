class ServicePacksMailer < BaseMailer
  # layout -'user_mailer' # this layout has something about notifying choice that is unavailable for our plugin.
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
    mail to: email, subject: "The remain units service pack #{@sp.name} reached below the FIRST threshold!" do |format|
      format.text
      format.html
    end
  end

  def notify_under_threshold2(email, service_pack)
    # @user = user
    @sp = service_pack
    # binding.pry
    mail to: email, subject: "The service pack #{@sp.name} reached below the SECOND threshold!" do |format|
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
