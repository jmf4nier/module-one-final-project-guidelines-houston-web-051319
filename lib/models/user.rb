class User < ActiveRecord::Base
    has_many :tickets, dependent: :destroy
    has_many :events, through: :tickets

    def get_all_tickets
        selected_events = []
        user_tickets = Ticket.all.select do |ticket|
            ticket.user_id == self.id 
        end
        user_tickets.each  do |ticket|
            Event.all.each do |event|
                if(event.id == ticket.event_id)
                    selected_events << event
                end
            end
        end
        selected_events.each do |event|
            puts event.name
        end
    end
end