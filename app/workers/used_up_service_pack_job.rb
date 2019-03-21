class UsedUpServicePackJob < ApplicationJob
	attr_reader :sp
	def initialize(sp)
		@sp = sp
	end
	def perform
		ServicePacksMailer.used_up_email(*(User.where(admin: true)), @sp).deliver_now
	end
end