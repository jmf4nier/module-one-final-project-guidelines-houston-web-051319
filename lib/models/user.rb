class User < ActiveRecord::Base
    has_many :tickets, dependent: :destroy
    has_many :events, through: :tickets

    def get_all_user_events
        self.events
    end

    def get_all_tickets
        puts "Tickets:".blue
        self.get_all_user_events.each do |event|
            puts event.name
        end
        puts ""
    end

    def get_more_event_info
        self.get_all_user_events.each_with_index do |event, index|
            puts "Event #{index+1}:".blue
            event.get_more_info
        end
    end
end