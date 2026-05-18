pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
    hold_frames = 0
    gap_frames = 0
    time_left = 30 
    max_time = 30
    seq = ""
    won = false 
    played_dash_sfx = false -- flag to stop loop-playing the dash sound
    
    morse_codes = {
        [".-"]="a", ["-..."]="b", ["-.-."]="c", ["-.."]="d", ["."]="e",
        ["..-."]="f", ["--."]="g", ["...."]="h", [".."]="i", [".---"]="j",
        ["-.-"]="k", [".-.."]="l", ["--"]="m", ["-."]="n", ["---"]="o",
        [".--."]="p", ["--.-"]="q", [".-."]="r", ["..."]="s", ["-"]="t",
        ["..-"]="u", ["...-"]="v", [".--"]="w", ["-..-"]="x", ["-.--"]="y", ["--.."]="z"
    }

    letters = {}
    for code, ltr in pairs(morse_codes) do
        letters[ltr] = code
    end

    manager = {
        target = "pico",
        typed = "",
        message = "waiting..."
    }

    ui = {
        draw = function(self)
            local bar_w = 100
            local current_w = (time_left / max_time) * bar_w
            rect(13, 109, 14+bar_w, 115, 6) 
            rectfill(14, 110, 13+current_w, 114, 8) 
            
            -- print("cheat sheet:", 15, 72, 5)
            
            local cx = 15
            local cy = 82 
            
            for i=1, #manager.target do
                local char = sub(manager.target, i, i)
                local code = letters[char]
                local col = (i <= #manager.typed) and 11 or 7
                
                local txt = char..":"..code
                local txt_w = #txt * 4
                
                if cx + txt_w > 115 then
                    cx = 15    
                    cy += 9   
                end
                
                print(txt, cx, cy, col)
                cx += txt_w + 6 
            end
        end
    }

    fx = {
        shake = 0,
        particles = {},
        
        spawn = function(self, px, py, color)
            for i=1, 15 do
                add(self.particles, {
                    x = px, y = py,
                    dx = rnd(2)-1, dy = rnd(2)-1,
                    life = 10 + rnd(10),
                    c = color
                })
            end
        end,
        
        update = function(self)
            if self.shake > 0 then
                self.shake *= 0.8
                if self.shake < 0.5 then self.shake = 0 end
            end
            
            for p in all(self.particles) do
                p.x += p.dx
                p.y += p.dy
                p.life -= 1
                if p.life <= 0 then del(self.particles, p) end
            end
        end,
        
        draw = function(self)
            if self.shake > 0 then
                camera(rnd(self.shake)-self.shake/2, rnd(self.shake)-self.shake/2)
            else
                camera(0,0)
            end
            
            for p in all(self.particles) do
                pset(p.x, p.y, p.c)
            end
        end
    }
end

function _update()
    fx:update() 

    if won then return end

    if time_left > 0 then
        time_left -= 1/30 
        if time_left <= 0 then
            time_left = 0
            manager.message = "time out!"
            fx.shake = 3
            sfx(3) 
        end
    end
    
    if time_left > 0 then
        if btnp(4) then
            if seq != "" then
                seq = ""
                manager.message = "input cleared!"
            elseif #manager.typed > 0 then
                manager.typed = sub(manager.typed, 1, #manager.typed - 1)
                manager.message = "backspaced!"
                sfx(1) 
            end
            hold_frames = 0
            gap_frames = 0
        end

        if btn(5) then
            hold_frames += 1
            gap_frames = 0
            
            -- SOUND CHANGE: play dot immediately on the first frame of pressing
            if hold_frames == 1 then
                sfx(0) -- initial beep for dot
            end
            
            -- SOUND CHANGE: switch to dash sound the exact frame it registers as a line
            if hold_frames > 6 and not played_dash_sfx then
                sfx(1) -- switch to bap for dash
                played_dash_sfx = true -- stop it from triggering every frame
            end
        else
            if hold_frames > 0 then
                local sym = "."
                if hold_frames > 6 then
                    sym = "-"
                end
                
                seq = seq .. sym 
                hold_frames = 0 
                played_dash_sfx = false -- reset tracker for next press
            end

            if seq != "" then
                gap_frames += 1
                if gap_frames > 20 then 
                    local letter = morse_codes[seq]
                    if letter then
                        manager.typed ..= letter
                        manager.message = "found: "..letter
                        fx:spawn(40 + (#manager.typed * 4), 35, 11) 
                        fx.shake = 2
                        sfx(2) 
                        
                        seq = "" 
                        
                        if manager.typed == manager.target then
                            won = true
                            manager.message = "message sent!"
                            fx.shake = 5
                            fx:spawn(64, 64, 9) 
                            sfx(4) 
                        end
                    else
                        manager.message = "wrong code!"
                        fx.shake = 3
                        fx:spawn(64, 64, 8) 
                        sfx(3) 
                        seq = "" 
                    end
                    gap_frames = 0
                end
            end
        end
    end
end

function _draw()
    cls(0)
    fx:draw() 
    
    print("bunker comms", 40, 5, 5)
    
    local target_col = won and 11 or 7
    print("target: "..manager.target, 40, 20, target_col)
    print("typed:  "..manager.typed, 40, 30, 11)
    
    local msg_col = won and 11 or 6
    print(manager.message, 40, 40, msg_col)

    if not won then
        print("input: "..seq, 40, 55, 12)
        print("press 'z' to backspace", 25, 65, 5) 
        
        if hold_frames > 0 then
            if hold_frames > 6 then
                rectfill(15, 57, 35, 59, 7)
            else
                circfill(25, 58, 2, 7)
            end
        else
            print("-", 23, 56, 5)
        end
    end
    
    ui:draw() 
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400003a0503a0403903000000000003c0003b0003b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700000e3500e3500b3600c30002300003000b30000000000002b3002b3002b3002b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 09424344

