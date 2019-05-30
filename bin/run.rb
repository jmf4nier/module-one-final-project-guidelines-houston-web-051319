require_relative '../config/environment'
$prompt = TTY::Prompt.new

$user = nil
$ticket_master_api_key = "kNCnGHz4hY28w5c0svNDehC9BqiMzVrZ"

def situation_selection
    $prompt.select("Welcome to Ticket Master! What would you like to do?") do |menu|
        menu.choice 'Sign up'
        menu.choice 'Login'
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
    
    #======================================================
    #AFTER THIS LOOP, events CONTAINS AN ARRAY OF EVENTS...WHAT TO DO NEXT? PURCHASE? SHOW MORE INFO?
    puts "Here are the events with those artist"
    events = events_with_artist.map do |event_hash|
        event_hash["name"]
    end

    event_selection= $prompt.select("Here are the events with those artist. Please select the one that you would like more information", events)
    generated_events.select do |event_hash|
        event_hash["name"] == event_selection
    end
    #PERHAPS RETURN CHOSEN EVENT AND THEN INVOKE A PURCHASE TICKET METHOD WITH SELECTED EVENT...CAN MAKE $selected_event A GLOBAL VARIABLE IF THAT MAKES IT EASIER
    #======================================================
    #PROBABLY BEST TO LET USER SELECT AN EVENT AND THEN OUTPUT THE ENTIRE HASH FOR THAT EVENT
end

def autheticate_user_screen
    while($user == nil)
        selection = situation_selection
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
    #logged_in_screen
end

def logged_in_screen
    $prompt.select("What would you like to do?") do |menu|
        menu.choice 'View all purchased tickets'
        menu.choice 'View events in a specified city'
    end
end

#===========================================
#MAIN METHOD
 #autheticate_user_screen
 #logged_in_screen
 get_all_events_for_artist
 puts "Working Program!!"

