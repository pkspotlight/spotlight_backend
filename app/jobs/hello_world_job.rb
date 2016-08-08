class HelloWorldJob < ApplicationJob
  queue_as :urgent

  def perform(*args)
    # Do something later
    puts "Hello world!!!"
  end
end
