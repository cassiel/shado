local f1 = { }

function f1.process(g, how)
    if how == 1 then
        for x = 1, 16 do
            for y = 1, 8 do
                g:led(x, y, math.random(15))
            end
        end
    else
        g:all(0)
    end
    
    g:refresh()
end

print("returning:")
print(f1)
return f1
