class User < ActiveRecord::Base
    has_many :tickets, dependent: :destroy
    has_many :events, through: :tickets

    @@situation = ["Sign up", "Login"]

    def self.situation
        @@situation
    end

end