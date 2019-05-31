class Event < ActiveRecord::Base
    has_many :appearances, dependent: :destroy
    has_many :artists, through: :appearances

    def get_more_info
        puts "Event Name: #{self.name}"
        puts "Event Date: #{self.date}"
        puts "City: #{self.city}"
        puts "State: #{self.state}"
        puts "Venue: #{self.venue_name}"
        puts ""
    end
end