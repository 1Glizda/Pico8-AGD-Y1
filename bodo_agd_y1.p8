pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
    hold_frames = 0
    gap_frames = 0
    time_left = 30
    seq = ""
    won = false
    
    morse_codes = {
        [".-"]="a", ["-..."]="b", ["-.-."]="c", ["-.."]="d", ["."]="e",
        ["..-."]="f", ["--."]="g", ["...."]="h", [".."]="i", [".---"]="j",
        ["-.-"]="k", [".-.."]="l", ["--"]="m", ["-."]="n", ["---"]="o",
        [".--."]="p", ["--.-"]="q", [".-."]="r", ["..."]="s", ["-"]="t",
        ["..-"]="u", ["...-"]="v", [".--"]="w", ["-..-"]="x", ["-.--"]="y", ["--.."]="z"
    }

    --game manager
    manager = {
        target = "agd",
        typed = "",
        status = "waiting..."
    }
    
    printh("new game", "debug.txt", true) 
end

function _update()
    if won then return end

   --timer
    if time_left > 0 then
        time_left -= 1/30 
        
        if time_left <= 0 then
            time_left = 0
            manager.status = "gata!"
            printh("time's up!", "debug.txt") -- only fires once now
        end
    end
    
    --input handler
    if btn(5) then
        hold_frames += 1
        gap_frames = 0
    else

        --check symbol
        if hold_frames > 0 then
            local sym = "."
            if hold_frames > 6 then 
                sym = "-" 
            end
            seq = seq .. sym --append
            printh("symbol: " .. sym .. " | time: " .. flr(time_left) .. " | sequence: " .. seq, "debug.txt")
            hold_frames = 0 
        end

        --check if letter exists
        if seq != "" then
            gap_frames += 1
            if gap_frames > 20 then -- ~0.6s 
                if morse_codes[seq] then
                    manager.typed ..= morse_codes[seq]
                    manager.status = "found letter: "..morse_codes[seq]
                    printh("letter sequence: " .. manager.typed .. " | time: " .. flr(time_left) .. " | symbol sequence: " .. seq, "debug.txt")

                    --check win condition
                    if manager.typed == manager.target then
                        manager.status = "you win!"
                        won = true  
                        printh("win! time: " .. flr(time_left), "debug.txt")
                    end
                else
                    manager.status = "wrong code!"
                end
                seq = "" 
                gap_frames = 0
            end
        end
    end
end

function _draw()
    cls(0)
    
    print("morse code game", 40, 10, 5)
    print("use button 'x'", 40, 16, 5)
    
    local target_col = won and 11 or 7 -- green or white
    print("target: "..manager.target, 40, 25, target_col)
    print("typed:  "..manager.typed, 40, 35, 11) -- green
    
    local won_msg = won and 11 or 8 -- green or red
    print(manager.status, 40, 45, won_msg)

    if not won then
        print("input: "..seq, 40, 60, 12)
        
        if hold_frames > 0 then
            if hold_frames > 6 then
                --dash
                rectfill(15, 62, 35, 64, 7)
            else
                --dot
                circfill(25, 63, 2, 7)
            end
        else
            --nothing
            print("-", 23, 61, 5)
        end
    end
    
    --timer
    print(flr(time_left), 110, 10, 8)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
