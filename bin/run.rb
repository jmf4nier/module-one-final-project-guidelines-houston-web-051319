require_relative '../config/environment'
prompt = TTY::Prompt.new


prompt.select("Welcome to Ticket Master! What would you like to do?", User.situation)


puts "HELLO WORLD"
