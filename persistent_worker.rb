require 'sidekiq'
class PersistentWorker
	include Sidekiq::Worker

	def perform(path, data)
		
	end
end