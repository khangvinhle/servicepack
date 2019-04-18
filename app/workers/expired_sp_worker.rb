require 'sidekiq-scheduler'

class ExpiredSpWorker
  include Sidekiq::Worker

  def perform
    expired_sp_s = ServicePack.expired
    return if expired_sp_s.count.zero?
    ServicePacksMailer.expired_email(ServicePack.expired)
  end
end
