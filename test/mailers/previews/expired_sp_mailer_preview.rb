# Preview all emails at http://localhost:3000/rails/mailers/expired_sp_mailer
class ExpiredSpMailerPreview < ActionMailer::Preview
  def expired_mail
    ExpiredSpMailer.expired_email(User.first, ServicePack.first)
  end
end
