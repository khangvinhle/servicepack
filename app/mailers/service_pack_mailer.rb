class ServicePackMailer < ApplicationMailer
  def expired(expired_service_packs)

    return if (expired_service_packs.count = 0)
    @sps = expired_service_packs
    user_mails = User.pluck(:mail)
    mail(to: user_mails, subject: 'Service ' + pluralize(@sps.count, 'pack') + 'expired')
  end
end