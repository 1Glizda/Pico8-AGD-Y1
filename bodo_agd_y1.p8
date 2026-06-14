pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
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

    alpha = "abcdefghijklmnopqrstuvwxyz"
    glow_timers = {}

    -- morse binary tree: {letter, x, y, parent_index}
    -- parent 0 = start node at (64,14)
    -- left child = dot, right child = dash
    tree_nodes = {
        {"e",30,24,0},{"t",96,24,0},
        {"i",14,34,1},{"a",46,34,1},{"n",80,34,2},{"m",112,34,2},
        {"s",6,44,3},{"u",22,44,3},{"r",38,44,4},{"w",54,44,4},
        {"d",72,44,5},{"k",88,44,5},{"g",104,44,6},{"o",120,44,6},
        {"h",2,54,7},{"v",10,54,7},{"f",18,54,8},{"l",34,54,9},
        {"p",50,54,10},{"j",58,54,10},{"b",68,54,11},{"x",76,54,11},
        {"c",84,54,12},{"y",92,54,12},{"z",100,54,13},{"q",108,54,13}
    }

    ui = {
        get_cs_pos = function(self, index)
            local cx, cy = 15, 82 
            for i=1, index do
                local char = sub(manager.target, i, i)
                local code = letters[char]
                if not code then return cx, cy end
                local txt = char..":"..code
                local txt_w = #txt * 4
                
                if cx + txt_w > 115 then
                    cx = 15    
                    cy += 9   
                end
                
                if i == index then
                    return cx, cy
                end
                
                cx += txt_w + 6 
            end
            return cx, cy
        end,
        draw = function(self)
            local bar_w = 100
            local current_w = (time_left / max_time) * bar_w
            rect(13, 109, 14+bar_w, 115, 6) 
            rectfill(14, 110, 13+current_w, 114, 8) 
            
            -- print("cheat sheet ("..difficulty..")", 15, 72, 5)
            local cx, cy = 15, 82 
            
            for i=1, #manager.target do
                local char = sub(manager.target, i, i)
                local code = letters[char]
                local col = 7
                if i <= #manager.typed then
                    local typed_char = sub(manager.typed, i, i)
                    if difficulty == "amateur" and typed_char != char then
                        col = 8
                    else
                        col = 11
                    end
                end
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
        shake = 0, particles = {},
        spawn = function(self, px, py, color)
            for i=1, 15 do
                add(self.particles, {
                    x=px, y=py, dx=rnd(2)-1, dy=rnd(2)-1, life=10+rnd(10), c=color
                })
            end
        end,
        update = function(self)
            if self.shake > 0 then
                self.shake *= 0.8
                if self.shake < 0.5 then self.shake = 0 end
            end
            for p in all(self.particles) do
                p.x += p.dx p.y += p.dy p.life -= 1
                if p.life <= 0 then del(self.particles, p) end
            end
        end,
        draw = function(self)
            if self.shake > 0 then camera(rnd(self.shake)-self.shake/2, rnd(self.shake)-self.shake/2) else camera(0,0) end
            for p in all(self.particles) do pset(p.x, p.y, p.c) end
        end
    }

    intro_text = "internet is down,\n\nlearn to use\n\nmorse code."
    intro_chars = 0
    
    story_scenes = {
        {
            text = "the radio crackles...\n\n\"anyone out there?\n  send sos if you\n  can hear us.\"",
            target = "sos"
        },
        {
            text = "\"signal received!\n\n  where are you?\n  transmit your\n  location.\"",
            target = "bunker"
        },
        {
            text = "\"we found you on\n  the grid.\n\n  confirm status.\n  are you alive?\"",
            target = "alive"
        }
    }
    
    ending_text = "\"help is on the way.\n\n  stay put, survivor.\n\n  you did well.\""
    ending_chars = 0
    
    current_level = 1
    story_chars = 0
    
    -- Difficulty selection setup
    difficulty = "training" 

    state = "start"
    reset_game()
end

function reset_game()
    hold_frames = 0
    gap_frames = 0
    seq = ""
    won = false 
    played_dash_sfx = false
    
    local scene = story_scenes[current_level]
    local target_word = scene and scene.target or "sos"
    
    -- Tweak timing parameters based on selection
    if difficulty == "amateur" then
        dash_threshold = 6
        letter_gap = 20
        max_time = #target_word * 10
    else
        -- Real life proportions & strict timer adjustments
        dash_threshold = 9 
        letter_gap = 10   
        max_time = #target_word * 5
    end
    
    time_left = max_time
    
    manager = {
        target = target_word,
        typed = "",
        message = "waiting..."
    }
    
    fx.particles = {}
    fx.shake = 0
end

function _update()
    fx:update() 

    if state == "start" then
        if intro_chars < #intro_text then
            intro_chars += 0.5 
        end
        
        if btnp(5) or btnp(4) then
            if intro_chars < #intro_text then
                intro_chars = #intro_text
            else
                state = "mode_select" -- Route to pop-up selection screen
                sfx(5)
            end
        end

    elseif state == "mode_select" then
        -- Toggle difficulty using Up (2) and Down (3) d-pad
        if btnp(2) then
            if difficulty == "training" then
                difficulty = "pro"
            elseif difficulty == "amateur" then
                difficulty = "training"
            else
                difficulty = "amateur"
            end
            sfx(5)
        elseif btnp(3) then
            if difficulty == "training" then
                difficulty = "amateur"
            elseif difficulty == "amateur" then
                difficulty = "pro"
            else
                difficulty = "training"
            end
            sfx(5)
        end
        
        -- Press X to lock it in and begin playing
        if btnp(5) then
            if difficulty == "training" then
                -- go straight to training
                hold_frames = 0
                gap_frames = 0
                seq = ""
                played_dash_sfx = false
                dash_threshold = 6
                letter_gap = 20
                glow_timers = {}
                fx.particles = {}
                fx.shake = 0
                state = "training"
                ignore_x = true
                sfx(5)
            else
                current_level = 1
                story_chars = 0
                reset_game()
                state = "story"
                sfx(5)
            end
        end

    elseif state == "story" then
        local scene = story_scenes[current_level]
        if scene then
            if story_chars < #scene.text then
                story_chars += 0.5
            end
            
            if btnp(5) or btnp(4) then
                if story_chars < #scene.text then
                    story_chars = #scene.text
                else
                    reset_game()
                    state = "play"
                    ignore_x = true
                    sfx(5)
                end
            end
        end

    elseif state == "ending" then
        if ending_chars < #ending_text then
            ending_chars += 0.5
        end
        
        if btnp(5) or btnp(4) then
            if ending_chars < #ending_text then
                ending_chars = #ending_text
            else
                state = "gameover"
            end
        end

    elseif state == "won" then
        won_timer -= 1
        if won_timer <= 0 or btnp(5) then
            fx.particles = {}
            if current_level < #story_scenes then
                current_level += 1
                story_chars = 0
                state = "story"
            else
                ending_chars = 0
                state = "ending"
                sfx(9)
            end
        end

    elseif state == "gameover" then
        if btnp(5) then
            state = "start"
            current_level = 1
            intro_chars = 0 
            sfx(5) 
        end

    elseif state == "training" then
        -- update glow timers
        for k, v in pairs(glow_timers) do
            glow_timers[k] -= 1/30
            if glow_timers[k] <= 0 then
                glow_timers[k] = nil
            end
        end

        -- Z resets input sequence
        if btnp(4) then
            seq = ""
            hold_frames = 0
            gap_frames = 0
        end

        if btn(5) then
            if not ignore_x then
                hold_frames += 1
                gap_frames = 0
                if hold_frames == 1 then sfx(0) end
                if hold_frames > dash_threshold and not played_dash_sfx then
                    sfx(1)
                    played_dash_sfx = true
                end
            end
        else
            ignore_x = false
            if hold_frames > 0 then
                local sym = "."
                if hold_frames > dash_threshold then sym = "-" end
                seq = seq .. sym
                hold_frames = 0
                played_dash_sfx = false
            end

            if seq != "" then
                gap_frames += 1
                if gap_frames > letter_gap then
                    local letter = morse_codes[seq]
                    if letter then
                        glow_timers[letter] = 2
                        fx:spawn(64, 20, 11)
                        fx.shake = 2
                        sfx(6)
                    else
                        fx.shake = 3
                        sfx(7)
                    end
                    seq = ""
                    gap_frames = 0
                end
            end
        end

        -- Left to go back
        if btnp(0) then
            state = "mode_select"
            sfx(5)
        end

    elseif state == "play" then
        if time_left > 0 then
            time_left -= 1/30 
            if time_left <= 0 then
                time_left = 0
                manager.message = "time out!"
                fx.shake = 3
                sfx(8) 
                state = "gameover" 
            end
        end
        
        if btnp(4) and difficulty == "amateur" then
            if seq != "" then
                seq = ""
                manager.message = "input cleared!"
            elseif #manager.typed > 0 then
                local lx = 40 + 32 + ((#manager.typed - 1) * 4) + 2
                fx:spawn(lx, 32, 8)
                if #manager.typed <= #manager.target then
                    local cs_x, cs_y = ui:get_cs_pos(#manager.typed)
                    fx:spawn(cs_x + 2, cs_y + 2, 8)
                end
                fx.shake = 2
                manager.typed = sub(manager.typed, 1, #manager.typed - 1)
                manager.message = "reset!"
                sfx(1) 
            end
            hold_frames = 0
            gap_frames = 0
        end

        if btn(5) then
            if not ignore_x then
                hold_frames += 1
                gap_frames = 0
                
                if hold_frames == 1 then sfx(0) end
                
                -- Replaced hardcoded values with dynamic 'dash_threshold'
                if hold_frames > dash_threshold and not played_dash_sfx then
                    sfx(1) 
                    played_dash_sfx = true 
                end
            end
        else
            ignore_x = false
            if hold_frames > 0 then
                local sym = "."
                if hold_frames > dash_threshold then sym = "-" end
                seq = seq .. sym 
                hold_frames = 0 
                played_dash_sfx = false 
            end

            if seq != "" then
                gap_frames += 1
                -- Replaced hardcoded confirmation frames with dynamic 'letter_gap'
                if gap_frames > letter_gap then 
                    local letter = morse_codes[seq]
                    if letter then
                        if difficulty == "pro" and letter != sub(manager.target, #manager.typed + 1, #manager.typed + 1) then
                            for i=1, #manager.typed do
                                fx:spawn(40 + 32 + ((i-1) * 4) + 2, 32, 8)
                                if i <= #manager.target then
                                    local cs_x, cs_y = ui:get_cs_pos(i)
                                    fx:spawn(cs_x + 2, cs_y + 2, 8)
                                end
                            end
                            manager.typed = ""
                            manager.message = "wrong letter!"
                            fx.shake = 3
                            fx:spawn(64, 64, 8) 
                            sfx(7) 
                            seq = "" 
                        else
                            manager.typed ..= letter
                            manager.message = "found: "..letter
                            
                            if letter != sub(manager.target, #manager.typed, #manager.typed) then
                                sfx(7)
                            else
                                fx:spawn(40 + 32 + ((#manager.typed - 1) * 4) + 2, 32, 11) 
                                fx.shake = 2
                                if manager.typed != manager.target then
                                    sfx(6)
                                end
                            end
                            
                            seq = "" 
                            
                            if manager.typed == manager.target then
                                won = true
                                manager.message = "message sent!"
                                fx.shake = 5
                                fx:spawn(64, 64, 9) 
                                sfx(9) 
                                state = "won"
                                won_timer = 60
                            end
                        end
                    else
                        manager.message = "wrong code!"
                        if difficulty == "pro" then
                            for i=1, #manager.typed do
                                fx:spawn(40 + 32 + ((i-1) * 4) + 2, 32, 8)
                                if i <= #manager.target then
                                    local cs_x, cs_y = ui:get_cs_pos(i)
                                    fx:spawn(cs_x + 2, cs_y + 2, 8)
                                end
                            end
                            manager.typed = ""
                        end
                        fx.shake = 3
                        fx:spawn(64, 64, 8) 
                        sfx(7) 
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
    
    if state == "start" then
        local current_text = sub(intro_text, 1, flr(intro_chars))
        print(current_text, 30, 40, 11)
        
        if intro_chars >= #intro_text then
            if t() % 1 < 0.5 then
                print("press 'x' to continue", 24, 90, 7)
            end
        end
        
    elseif state == "mode_select" then
        -- THE POP-UP WINDOW INTERFACE
        rectfill(14, 30, 114, 92, 1)
        rect(13, 29, 115, 93, 7)
        
        print("select mode", 40, 36, 11)
        
        -- Draw options
        local tr_col = (difficulty == "training") and 12 or 5
        local am_col = (difficulty == "amateur") and 10 or 5
        local pro_col = (difficulty == "pro") and 8 or 5
        
        print("training", 44, 52, tr_col)
        print("arcade", 48, 62, am_col)
        print("realism", 46, 72, pro_col)
        
        -- Selection arrow
        local arrow_y = 52
        if difficulty == "amateur" then arrow_y = 62
        elseif difficulty == "pro" then arrow_y = 72 end
        print("\x8e", 36, arrow_y, 7)
        
        if t() % 1 < 0.5 then
            print("press 'x' to lock in", 24, 84, 7)
        end

    elseif state == "story" then
        local scene = story_scenes[current_level]
        if scene then
            -- Level indicator
            print("transmission "..current_level.."/"..#story_scenes, 30, 10, 5)
            
            -- Draw radio static line decoration
            for i=0, 127 do
                if rnd(100) < 3 then
                    pset(i, 25 + rnd(2), 5)
                end
            end
            
            local current_text = sub(scene.text, 1, flr(story_chars))
            print(current_text, 18, 35, 11)
            
            -- Show the word they need to spell next
            if story_chars >= #scene.text then
                print("spell: "..scene.target, 18, 90, 10)
                if t() % 1 < 0.5 then
                    print("press 'x' to begin", 26, 105, 7)
                end
            end
        end

    elseif state == "ending" then
        print("transmission complete", 24, 10, 11)
        
        -- Draw radio static line decoration
        for i=0, 127 do
            if rnd(100) < 3 then
                pset(i, 25 + rnd(2), 5)
            end
        end
        
        local current_text = sub(ending_text, 1, flr(ending_chars))
        print(current_text, 18, 35, 11)
        
        if ending_chars >= #ending_text then
            if t() % 1 < 0.5 then
                print("press 'x' to finish", 26, 105, 7)
            end
        end

    elseif state == "gameover" then
        if won then
            print("YOU WON!", 48, 40, 11)
        else
            print("GAME OVER", 46, 40, 8)
        end
        if t() % 1 < 0.5 then
            print("press 'x' to restart", 24, 60, 10)
        end

    elseif state == "training" then
        print("training", 48, 3, 12)
        print("\x8b back", 5, 3, 5)
        
        -- draw start node
        print("\x8e", 63, 14, 6)
        print(".", 54, 10, 5)
        print("-", 72, 10, 5)
        
        -- draw tree with connecting lines
        for i=1, #tree_nodes do
            local n = tree_nodes[i]
            local ltr, nx, ny, pi = n[1], n[2], n[3], n[4]
            
            -- parent position
            local px, py
            if pi == 0 then
                px, py = 64, 18
            else
                px, py = tree_nodes[pi][2]+2, tree_nodes[pi][3]+6
            end
            
            -- connecting line
            line(nx+2, ny-1, px, py, 1)
            
            -- letter color: glow green or dim gray
            local col = 5
            if glow_timers[ltr] then
                col = 11
            end
            print(ltr, nx, ny, col)
        end
        
        -- draw input area
        print("input: "..seq, 10, 68, 12)
        print("'z' clear", 10, 78, 5)
        
        if hold_frames > 0 then
            if hold_frames > dash_threshold then
                rectfill(10, 86, 30, 88, 7)
            else
                circfill(20, 87, 2, 7)
            end
        else
            print("-", 18, 85, 5)
        end

    else
        -- Level indicator header
        print("bunker comms "..current_level.."/"..#story_scenes, 30, 5, 5)
        
        local target_col = won and 11 or 7
        print("target: "..manager.target, 40, 20, target_col)
        print("typed:  ", 40, 30, 11)
        local cx = 40 + 32
        for i=1, #manager.typed do
            local typed_char = sub(manager.typed, i, i)
            local target_char = sub(manager.target, i, i)
            local c_col = 11
            if difficulty == "amateur" and typed_char != target_char then
                c_col = 8
            end
            print(typed_char, cx, 30, c_col)
            cx += 4
        end
        
        local msg_col = won and 11 or 6
        print(manager.message, 40, 40, msg_col)

        if state == "play" then
            print("input: "..seq, 40, 55, 12)
            if difficulty == "amateur" then
                print("press 'z' to reset", 25, 65, 5) 
            end
            
            if current_level == 1 then
                if #manager.typed == 0 then
                    print("press 'x' for a dot", 32, 98, 10)
                elseif #manager.typed == 1 then
                    print("hold 'x' for a dash", 28, 98, 10)
                end
            end
            
            if hold_frames > 0 then
                if hold_frames > dash_threshold then
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000a0700c0700d0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000083700f3701a3702037000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600000727007270072700727000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c000025170221701f1501c1501a150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000244302845024450000002a4302c4502a450000002e4302e4502e4602e4602e46000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 09424344

