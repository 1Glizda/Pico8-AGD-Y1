pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
    hold_frames = 0
    time_left = 10
    seq = ""
    
    printh("new game", "debug.txt", true) 
end

function _update()
    --timer
    if time_left > 0 then
        time_left -= 1/30 --pico runs at 30fps
    else
        time_left = 0
    end
    
    --input handler
    if btn(5) then
        hold_frames += 1
    else
        if hold_frames > 0 then
            local sym = "."
            if hold_frames > 6 then 
                sym = "-" 
            end
            seq = seq .. sym --append
            printh("symbol: " .. sym .. " | time: " .. flr(time_left) .. " | sequence: " .. seq, "debug.txt")
            hold_frames = 0 
        end
    end
end

function _draw()
    cls(0)
    
    print("morse code game", 40, 10, 5)
    print("use button 'x'", 40, 20, 5)

    if hold_frames > 0 then
        if hold_frames > 6 then
            -- dash
            rectfill(15, 62, 35, 64, 7)
        else
            -- dot
            circfill(25, 63, 2, 7)
        end
    else
        -- idle
        print("-", 23, 61, 5)
    end
    
    --timer
    print(flr(time_left), 100, 60, 8)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
