class User < ActiveRecord::Base
    has_many :tickets, dependent: :destroy
    has_many :events, through: :tickets

    def get_all_tickets
        self.events.each do |event|
            puts event.name
        end
    end
end