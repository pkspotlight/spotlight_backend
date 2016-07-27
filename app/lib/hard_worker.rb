class HardWorker
  include Sidekiq::Worker

  def perform(name, count)
    count.times do
      puts name
    end
  end
end
