require_relative '../config/environment'
$prompt = TTY::Prompt.new

$user = nil

def situation_selection
    $prompt.select("Welcome to Ticket Master! What would you like to do?") do |menu|
        menu.choice 'Sign up'
        menu.choice 'Login'
    end
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
 autheticate_user_screen
 logged_in_screen
 puts "Working Program!!"