class User < ActiveRecord::Base
    has_many :tickets, dependent: :destroy
    has_many :events, through: :tickets
end