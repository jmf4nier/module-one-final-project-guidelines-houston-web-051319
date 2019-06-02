require_relative '../config/environment'
$prompt = TTY::Prompt.new
require 'pry'

$user = nil
$ticket_master_api_key = "" #insert your api key here

def situation_selection
    $prompt.select("Welcome to Ticket Master! What would you like to do?") do |menu|
        menu.choice 'Sign up'
        menu.choice 'Login'
        menu.choice 'Terminate program'
    end
end

def get_all_events_for_artist
    puts "Please enter an artist"
    artist = gets.chomp
    
    api_response = RestClient.get("https://app.ticketmaster.com/discovery/v2/events.json?size=20&keyword=#{artist}&apikey=#{$ticket_master_api_key}")
    json_response = JSON.parse(api_response)

    overlapping_attractions = []
    generated_events = json_response["_embedded"]["events"]
    generated_events.each do |event_hash|
        if(event_hash["_embedded"]["attractions"] != nil)
            sub_arr = event_hash["_embedded"]["attractions"].map do |attraction_hash|
                attraction_hash["name"]
            end
            sub_arr = sub_arr.join(", ")
            overlapping_attractions << sub_arr
        end
    end
    
    overlapping_attractions = overlapping_attractions.uniq
    
    attraction_selection = $prompt.select("Please select the artist or group of artist that you are interested in", overlapping_attractions).split(", ")
    
    events_with_artist = []
    generated_events.each do |event_hash|
        if(event_hash["_embedded"]["attractions"] != nil)
            count = 0
            desired_count = attraction_selection.length
            event_hash["_embedded"]["attractions"].each do |attraction_hash|
                attraction_selection.each do |attraction_name|
                    if(attraction_name == attraction_hash["name"])
                        count += 1
                    end
                end
            end
            if(count == desired_count)
                events_with_artist << event_hash
            end
        end
    end
    
    puts "Here are the events with those artist"
    events = events_with_artist.map do |event_hash|
        event_hash["name"]
    end

    selected_event_hash = []
    event_selection= $prompt.select("Here are the events with those artist. Please select the one that you would like more information", events)

    generated_events.each do |event_hash|
        if(event_hash["name"] == event_selection)
            selected_event_hash << event_hash
        end
    end
    selected_event_hash[0]#TRY TO FINISH A HASH AND NOT AN ARRAY...USE EVENT IDs TO DIFFERENTIATE BETWEEN EVENTS WITH SAME NAMES
end

def store_event_in_db(event_hash)
    newEvent = Event.new(name: event_hash["name"], date: event_hash["dates"]["start"]["localDate"], city: event_hash["_embedded"]["venues"][0]["city"]["name"], state: event_hash["_embedded"]["venues"][0]["state"]["name"], venue_name: event_hash["_embedded"]["venues"][0]["name"])
    newEvent.save 
    newEvent
end

def store_ticket_in_db(user, event)
    new_ticket = Ticket.new(user_id: user.id, event_id: event.id)
    new_ticket.save
    new_ticket
end

def store_appearance_in_db(event, artist)
    new_appearance = Appearance.new(event_id: event.id, artist_id: artist.id)
    new_appearance.save
    new_appearance
end

def store_artist_in_db(event_hash)
    stored_event = store_event_in_db(event_hash)

    event_hash["_embedded"]["attractions"].each do |attraction_hash|
        new_artist = Artist.new(name: attraction_hash["name"])
        new_artist.save
        store_appearance_in_db(stored_event, new_artist)
    end
    stored_event
end

def purchase_ticket(selected_event_hash)
    event = store_artist_in_db(selected_event_hash)
    store_ticket_in_db($user, event)
 end

def autheticate_user_screen
    while($user == nil)
        selection = situation_selection
        if(selection == "Terminate program")
            exit(0)
        end
        if(selection == "Sign up")#Create new user and save to data base. Then enter logged in screen
            puts "Please enter a name"
            name = gets.chomp
            new_user = User.new(name: name)
            new_user.save
            $user = new_user
        else#User selected Login. 
            loop do 
                puts "Please enter a name"
                name = gets.chomp
                break if name == "back"
                authenticated_user = User.all.find_by(name: name)
                if(authenticated_user != nil)
                    $user = authenticated_user
                    break
                end
                puts "Incorrect Name. Try again" #Name for now. In the future, program may be updated to contain username/password
            end     
        end
    end
    true
end

def logged_in_screen
    $prompt.select("What would you like to do?") do |menu|
        menu.choice 'Find event by searching for an artist'
        menu.choice 'View all your tickets'
        menu.choice 'Get more information for all your events'
        menu.choice 'Logout'
    end
end

#===========================================
#MAIN METHOD
while(true)
    authenticated = autheticate_user_screen
    while(authenticated)
        main_menu_selection = logged_in_screen
        if(main_menu_selection == "Find event by searching for an artist")
            selected_event = get_all_events_for_artist
            purchase_ticket(selected_event)
        elsif(main_menu_selection == "View all your tickets")
            $user.get_all_tickets
        elsif(main_menu_selection == "Get more information for all your events")
            $user.get_more_event_info
        elsif(main_menu_selection == "Logout")
            $user = nil
            authenticated = false
        end
    end
end



