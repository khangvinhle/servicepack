class UsedUpServicePackJob < ApplicationJob
	attr_reader :sp
	def initialize(sp)
		@sp = sp
	end
	def perform
		User.where(admin: true).each do |user| ServicePacksMailer.used_up_email(user, @sp).deliver_now
	end
end