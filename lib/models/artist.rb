class Artist < ActiveRecord::Base
    has_many :appearances, dependent: :destroy
    has_many :events, through: :appearances
end