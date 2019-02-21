# Preview all emails at http://localhost:3000/rails/mailers/service_pack_mailer
class ServicePackMailerPreview < ActionMailer::Preview
  def expired
    ServicePackMailer.expired(ServicePack.expired)
  end
end
