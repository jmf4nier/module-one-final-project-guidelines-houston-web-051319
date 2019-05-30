require 'tty-prompt'
require 'rest-client'
require 'json'
$prompt = TTY::Prompt.new

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
            event_obj["name"] + ", " + event_obj["dates"]["start"]["localDate"]
        end
    end
end


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


 def user_response_to_city
    response = $prompt.ask("Please enter a city") 
    if  response == nil
        puts "Please enter a response or push 'CTR C' to quit"
        sleep(1)
        user_response_to_city
    elsif city_events_by_name(response) == false
        puts "please choose again"
        user_response_to_city
    else
        event_data = city_events_by_name(response.capitalize)
        selection = $prompt.select("Choose an event to buy tickets!", "back", (event_data))
        if  selection == "back"
            return
        end 
    end
    selection
end


def user_response_to_state
    response = $prompt.ask("Please enter a State (ie. TX, CA, CO, AZ)") 
    if  response == nil
        puts "Please enter a response or push 'CTR C' to quit"
        sleep(1)
        user_response_to_state
    elsif state_events_by_name(response) == false
        puts "please choose again"
        user_response_to_state
    else
        event_data = state_events_by_name(response.upcase)
        selection = $prompt.select("Choose an event to buy tickets!", "back", (event_data))
        if  selection == "back"
            return
        else
            get_specific_event_state(response, selection)
        end 
    end
    
end
def get_specific_event_state(user_response, user_selection)
    state_events(user_response)["_embedded"]["events"].select do |event_obj|
         user_selection.include?(event_obj["id"]) 
          #searches selected event for event_id and returns event hash
    end
end

 
# =====================================================================================================================
user_response_to_state


