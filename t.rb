a = [5,7,1,3, 1]

b = a.select do |n|
    n == 1
end

p b