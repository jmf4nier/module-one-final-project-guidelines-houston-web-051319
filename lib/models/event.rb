class Event < ActiveRecord::Base
    has_many :appearances, dependent: :destroy
    has_many :artists, through: :appearances
    
    
    

end