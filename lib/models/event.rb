class Event < ActiveRecord::Base
    has_many :appearances, dependent: :destroy
    has_many :artists, through: :appearances

    def get_string_artist_names
        output_string = ""
        artist_arr_length = self.artists.length
        self.artists.each_with_index do |artist, index|
            output_string = output_string + artist.name
            if(index != artist_arr_length-1)
                output_string = output_string + ", "
            end
        end
        output_string
    end

    def get_more_info
        puts "Event Name: #{self.name}"
        puts "Event Date: #{self.date}"
        puts "City: #{self.city}"
        puts "State: #{self.state}"
        puts "Venue: #{self.venue_name}"
        puts "Artist: #{self.get_string_artist_names}"
        puts ""
    end
end