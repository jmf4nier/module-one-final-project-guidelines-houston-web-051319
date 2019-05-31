require_relative '../config/environment'
$prompt = TTY::Prompt.new

$user = nil
$ticket_master_api_key = "kNCnGHz4hY28w5c0svNDehC9BqiMzVrZ"

def situation_selection
    $prompt.select("Welcome to Ticket Master! What would you like to do?") do |menu|
        menu.choice 'Sign up'
        menu.choice 'Login'
        menu.choice 'Terminate program'
    end
end

#============================================================ City search methods =================================================================================
def city_events(city)
    response = RestClient.get('https://app.ticketmaster.com/discovery/v2/events.json?city=' + city + '&apikey=kNCnGHz4hY28w5c0svNDehC9BqiMzVrZ')
    jason_response = JSON.parse(response)
end

def city_events_by_name(city)
    events = city_events(city)
    if events["page"]["totalElements"] == 0
        return false
    else
        events["_embedded"]["events"].map do |event_obj| 
            event_obj["name"] + ", " + event_obj["dates"]["start"]["localDate"] + ", " + event_obj["id"]
        end
    end
end

def user_response_to_city
    response = $prompt.ask("Please enter a city") do |q|
        q.required true 
    end
    if city_events_by_name(response) == false  #checks if API query returns a valid result. if not asks for another input.
        puts "please choose again"
        user_response_to_city
    else
        event_data = city_events_by_name(response.capitalize)
        selection = $prompt.select("Choose an event to buy tickets or select back", "back", (event_data))
        #iterates the event name data through the prompt for selection by user
        if  selection == "back"
            #breaks method back to last call
            return
        else
            get_specific_event_city(response, selection)
        end 
    end
end

def get_specific_event_city(user_response, user_selection)
    event_array = city_events(user_response)["_embedded"]["events"].select do |event_obj|
         user_selection.include?(event_obj["id"])
          #searches selected event for event_id and returns event hash
    end
    event_array[0]   #converts array into hash for ease of use
end
#===================================================== State search info =================================================================================
def state_events(state)
    api_return = RestClient.get('https://app.ticketmaster.com/discovery/v2/events.json?stateCode=' + state + '&apikey=kNCnGHz4hY28w5c0svNDehC9BqiMzVrZ')
     JSON.parse(api_return)
end

def state_events_by_name(state)
    if state_events(state)["page"]["totalElements"] == 0
        return false
    else
        state_events(state)["_embedded"]["events"].map  do |event_obj| 
            event_obj["name"] + ", " + event_obj["dates"]["start"]["localDate"] + ", " + event_obj["id"]
        end
    end
end

def user_response_to_state
    response = $prompt.ask("Please enter a State (ie. TX, CA, CO, AZ)") do |q|
        q.required true 
    end
    if state_events_by_name(response) == false
        puts "please choose again"                         #checks if API query returns a valid result. if not asks for another input.
        user_response_to_state
    else
        event_data = state_events_by_name(response.upcase)
        selection = $prompt.select("Choose an event to buy tickets or select back", "back", (event_data))
        #iterates the event name data through the prompt for selection by user
        if  selection == "back"
            #breaks method back to last call
            return
        else
        get_specific_event_state(response, selection)
        end 
    end
end

def get_specific_event_state(user_response, user_selection)
    event_array = state_events(user_response)["_embedded"]["events"].select do |event_obj|
         user_selection.include?(event_obj["id"]) 
          #searches selected event for event_id and returns event array containing hash
    end
    event_array[0] #converts array into hash for ease of use
end
# ====================================================== Artist search method =============================================================================

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

#================================================================= Database instantiations ===========================================================================================

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
    confirmation = $prompt.yes?('Buy tickets?')
    if confirmation == true
        puts 'Congratulations!  You have tickets!'
        sleep(1)
        puts 'Returning to main menu...'
        sleep (2)
        event = store_artist_in_db(selected_event_hash)
        store_ticket_in_db($user, event)
    else
        puts 'Returning to main menu...'
        sleep(2)
        return
    end
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
        menu.choice 'Find event by searching for an artist/team'
        menu.choice 'Find event by City'
        menu.choice 'Find event by State'
        menu.choice 'View all your tickets'
        menu.choice 'Logout'
    end
end

#===========================================
#MAIN METHOD
while(true)
    authenticated = autheticate_user_screen
    while(authenticated)
        main_menu_selection = logged_in_screen
        if(main_menu_selection == "Find event by searching for an artist/team")
            selected_event = get_all_events_for_artist
            purchase_ticket(selected_event)
        elsif(main_menu_selection == "Find event by City")
            selected_event = user_response_to_city
            if selected_event == nil
                #breaks loop if 'back' selected
            else 
                purchase_ticket(selected_event)
            end
        elsif(main_menu_selection == "Find event by State")
            selected_event = user_response_to_state
            if selected_event == nil 
                #breaks loop if 'back' selected
            else 
                purchase_ticket(selected_event)
            end
        elsif(main_menu_selection == "View all your tickets")
            $user.get_all_tickets
        elsif(main_menu_selection == "Logout")
            $user = nil
            authenticated = false
        end
    end
end


