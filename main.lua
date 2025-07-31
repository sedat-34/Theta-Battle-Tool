---@diagnostic disable: undefined-field
Object = require "classic"
require "partyMember"
require "background"
require "battleui"
require "battlebar"
require "soul"
require "submenu"
require "mizzle"
require "battlebox"
require "animate"

--Best for pixel-precise scaling (no blur)
love.graphics.setDefaultFilter( "nearest", "nearest", 1)


--Place constant values here. There's no constants in lua, but keeping them separated will help you stay organised.

--Honestly I don't think I used either of these anywhere but maybe someone will need them.
WIDTH = love.graphics.getWidth()
HEIGHT = love.graphics.getHeight()

ARR_STATES = { --UI Buttons to states as used in current_state
               --MAGIC will also be used in ACTUI
               --It still has a graphical difference (magic button over act button) but no functional one.
    "ATTACKUI",
    "ACTUI",
    "ITEMUI",
    "SPAREUI",
    "DEFEND",
}

--Place state-tracking variables here

current_state = nil --Used to keep track of what's currently going on. Example: "ATTACKING"
selected_enemy = nil

party_members = {}
members_to_attack = {}
enemies_to_attack = {}
battlebars = {}

local actname = {}
local actindex = {}

--Rule of thumb for local variables:
--If they need to be reused; define here so the scope is the whole script, then modify in love.load() if necessary
--If they're only needed once, define in love.load()

--Arrays used for submenus:
enemies = {}
local selected_enemies = {}
local act_sub_subs = {}

local Commands = {}

local kris_1
local kris_2

local mizzle_1
local mizzle_2
local mizzle_3

local Bg
local Box

function love.load()

    Box = Battlebox()

    local kris_anims = {
        [0] = {"krisIdle", 6, 6, true, 0, 0},
        [1] = {"krisAttack", 8, 15, false, 0, -1},
        [2] = {"krisAct", 11, 11, false, 0, 0},
        [3] = {"krisItem", 8, 12, false, -7, -5},
        [4] = {"krisAct", 11, 11, false, 0, 0}, --I'm fairly confident that Kris uses the same animation for sparing and acting
        [5] = {"krisDefend", 6, 12, false, 0, -0.5},
        [6] = {"krisAttackWait", 1, 1, true, 0, -1},
        [7] = {"krisActWait", 1, 1, true, 0, 0},
        [8] = {"krisActWait", 1, 1, true, 0, 0}, --Again, sparing is visually the same as acting. 
        [9] = {"krisDefendLoop", 1, 1, true, 0, -0.5}, --Unlooping animations set animation to default, so this animation is required to keep their last sprite.
    }

    local kris_buttons = { --Generally FIGHT/ACT/ITEM/SPARE/DEFEND but I used ATTACK for some reason
                           --And because it's written all over the code I can't change it anymore
                           --A monster party member could use MAGIC.
                           --Or a custom member could get custom behaviour and custom submenus. Go wild!
        [1] = {"attack"},
        [2] = {"act"},
        [3] = {"item"},
        [4] = {"spare"},
        [5] = {"defend"},
    }

    local krisSpecialLoops = {
        [5] = 9
    }

    kris_1 = PartyMember("Kris1", 100, 202, kris_anims, "krisplace.png", 0, krisSpecialLoops, 4, 203, 35, 10)
    kris_1:set_animation("ATTACK")

    kris_2 = PartyMember("Kris2", 100, 402, kris_anims, "krisplace.png", 0, krisSpecialLoops, 4, 203, 35, 10)
    kris_2:set_animation("ATTACK")

    party_members = {
        kris_1,
        kris_2,
    }

    barry = BattleBar(1000, 0, 1)

    for i = 1, #party_members do
        Commands[i] = {}
    end

    Kris1UI = BattleUi("Kris1", "kris", "kris", kris_buttons, 308, 630, 1)
    Kris2UI = BattleUi("Kris2", "kris", "kris", kris_buttons, 628, 630, 2)

    UIs = {
        Kris1UI,
        Kris2UI,
    }

    current_party_member = 1

    --Background
    Bg = Background("b", 100, 30)

    --Enemy related data
    local mizzle_anims = {
        [0] = {"mizzleIdle", 5, 5, true, 0, 0},
        [1] = {"mizzleIdlePink", 5, 5, true, 0, -0.3},
        [2] = {"mizzleAlarm", 10, 10, true, 0, 0},
        [3] = {"mizzleAlarmPink", 10, 10, true, 0, -0.3},
        [4] = {"mizzleHurt", 1, 1, true, 0, 0},
        [5] = {"mizzleHurtPink", 1, 1, true, 0, 0}
    }

    mizzle_1 = Mizzle("Mizzr", 980, 102, mizzle_anims, 0, 3, 1000)
    mizzle_2 = Mizzle("Mizzy", 980, 202, mizzle_anims, 0, 3, 1000)
    mizzle_3 = Mizzle("Mizzle", 980, 302, mizzle_anims, 0, 3, 1000)

    enemies[1] = mizzle_1
    enemies[2] = mizzle_2
    enemies[3] = mizzle_3

    --START Submenus and their options
    --These get used to generate the submenus' text and their positions
    --Check out submenu.lua for more info

    Enemysubarray = { --The array used when generating a submenu with the enemies' names
                      --You must define the positions of the enemy names yourself.
        [1] = {"* "..enemies[1].name, 218, 771},
        [2] = {"* "..enemies[2].name, 778, 771},
        [3] = {"* "..enemies[3].name, 218, 851},
    }

    act_sub_subs = { --ACT -> enemies[i] -> These show up
                     --Even if enemies[i] changes, it looks for the original memory adress

        [enemies[1]] = { --Handle these in enemies[1]:act(actname)
            [1] = {"* Alarm", 218, 771, "* Mizzr is awoken!\n* This sounds like a bad idea."},
            [2] = {"* Lullaby", 778, 771, "* Somebody sung a lullaby!\n* Not as good as Ralsei's, but it worked."},
        },
        [enemies[2]] = {
            [1] = {"* Alarm", 218, 771, "* Mizzy is awoken!\n* This sounds like a bad idea."},
            [2] = {"* Lullaby", 778, 771, "* Somebody sung a lullaby!\n* Not as good as Ralsei's, but it worked."},
        },
        [enemies[3]] = {
            [1] = {"* Alarm", 218, 771, "* Mizzle is awoken!\n* This sounds like a bad idea."},
            [2] = {"* Lullaby", 778, 771, "* Somebody sung a lullaby!\n* Not as good as Ralsei's, but it worked."},
        },
    }

    Enemysub = Submenu(Enemysubarray, {"ATTACKUI", "ACTUI", "SPAREUI"}, nil)

    Mizzle1sub = Submenu(act_sub_subs[enemies[1]], {"ACTSUBSUB"}, enemies[1])
    Mizzle2sub = Submenu(act_sub_subs[enemies[2]], {"ACTSUBSUB"}, enemies[2])
    Mizzle3sub = Submenu(act_sub_subs[enemies[3]], {"ACTSUBSUB"}, enemies[3])

    --Load fonts!
    Battlefont = love.graphics.newFont("fonts/8bitOperatorPlus-Bold.ttf", 28)
    Goldenfont = love.graphics.newImageFont("sprites/goldennumeralfont.png", "0123456789+-%/ ")--The mercy increased font

    love.graphics.setFont(Battlefont)

    --Load certain feedback sprites (Recruit, Lost, Frozen etc.)
    LOST = love.graphics.newImage("sprites/LOST.png")
    RECRUIT = love.graphics.newImage("sprites/recruit.png")

    --The very culmination of your being ;)
    Sole = Soul() --It's named "Sole" because the object name cannot be the class name.

    --Music
    --This should allow one to dynamically swap songs
    --Like a jukebox enemy with a certain act can change the song :)
    MUS_Vaporbattle = love.audio.newSource("music/battle_vapor.ogg", "stream")
    MUS_Churchbattle = love.audio.newSource("music/ch4_battle.ogg", "stream")

    MUS_Battlemusic = MUS_Churchbattle

    love.audio.play(MUS_Battlemusic)

    --Sounds
    SND_MENUMOVE = love.audio.newSource("sfx/snd_menumove.wav", "static")
    SND_SELECT = love.audio.newSource("sfx/snd_select.wav", "static")
    SND_ATTACK = love.audio.newSource("sfx/snd_attack.wav", "static")

    --Initialise initial state
    current_state = "BATTLEUI"
    UIs[current_party_member]:subtext("* Cool initial description")

    --These aren't needed after love.load, so they are nullified to save from memory.
    kris_anims = nil
    kris_buttons = nil
    mizzle_anims = nil
end

function love.update(dt)

    for i = 1, #enemies do
        if enemies[i] then
            enemies[i]:update(dt)
        end
    end

    for i = 1, #party_members do
        party_members[i]:update(dt)
    end

    for i = 1, #battlebars do
        if battlebars[i] then
            battlebars[i]:update(dt)
        end
    end

    Bg:update(dt)

    Box:update(dt)

    --print(love.mouse.getX().."  "..love.mouse.getY()) --I use this when checking positions in the UI.

    if not MUS_Battlemusic:isPlaying() then
        love.audio.play(MUS_Battlemusic)
    end

    local battleovercheck = true

    for i = 1, #enemies do
        if enemies[i] then
            if enemies[i].hp > 0 then
                battleovercheck = false
                break
            end
        end
    end

    if battleovercheck then
        current_state = "BATTLEOVER"
    end

    if current_state == "BATTLEOVER" then
    UIs[current_party_member]:subtext("* Battle is over!\n* Press any key to exit")
    Sole:updatePosArray(nil)
    end

end

local function ExecuteAttack()

    print("ExecuteAttack()")
    print("current_party_member: "..current_party_member)

    current_state = "ATTACKING"

    if #members_to_attack > 0 and #battlebars == 0 then
        print("members_to_attack: "..#members_to_attack)

        for i = 1, #members_to_attack do
            battlebars[i] = BattleBar(900+100*i, 738+41*1.5*(i-1), i)

        end

    elseif current_party_member <= #battlebars then

        if battlebars[current_party_member] then
            battlebars[current_party_member]:attack()
        end

    end

    if current_party_member > #battlebars then
        current_state = "BATTLEUI"
        members_to_attack = {}
        enemies_to_attack = {}
        battlebars = {}
        current_party_member = 1
        for i = 1, #party_members do
            UIs[i]:subtext("* A wild battle commentary appeared!")
        end
        current_state = "BATTLEUI"
    end


end

local function ExecuteCommands()

    print("ExecuteCommands()")

    local CommandReturned
    current_party_member = current_party_member + 1

    print("current_party_member @ COMMANDS:"..current_party_member)

    if current_party_member <= #party_members then
        if Commands[current_party_member][1] then
            print("Command executed")
            UIs[current_party_member]:subtext(Commands[current_party_member][2])
            CommandReturned = Commands[current_party_member][1]()
            print(CommandReturned)
        end
    end
    if CommandReturned == "DEFCOMMAND" then
        party_members[current_party_member].isdefending = true
        ExecuteCommands()
    elseif CommandReturned == "ATTACKCOMMAND" then
        members_to_attack[#members_to_attack+1] = party_members[current_party_member]
        print("Latest member to attack: "..members_to_attack[#members_to_attack].name)
        ExecuteCommands()
    end

    if current_party_member >= #party_members + 1 then
        if #members_to_attack > 0 then
            current_party_member = 1
            current_state = "ATTACKING"
            for i = 1, #party_members do
                UIs[i]:subtext("")
            end
            ExecuteAttack()
        else
            current_state = "BATTLEUI"
            for i = 1, #party_members do
                UIs[i]:subtext("* A wild battle commentary appeared!")
            end
        end

        current_party_member = 1
        selected_enemies = {}
        actname = {}
        actindex = {}
        for i = 1, #party_members do
            Commands[i] = {}
            UIs[i].buttonmode = 1
        end
    end

end

function love.keypressed(key)

    --This if else statement is the core of ThetaBattleTool
    --It handles the entirity of the UI system
    --Do not edit this unless you're CERTAIN you know what you're doing.

    if current_state == "BATTLEUI" then --The main battle menu. If you see the five buttons, you're in this state.

        if key == "right" then
            UIs[current_party_member]:changeselect(1)
        elseif key == "left" then
            UIs[current_party_member]:changeselect(-1)
        elseif key == "z" then
            UIs[current_party_member]:subtext(nil)
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:menuState(Sole, 631, 471, ARR_STATES[UIs[current_party_member].buttonmode], Enemysubarray)
            party_members[current_party_member]:set_animation(ARR_STATES[UIs[current_party_member].buttonmode])
            if ARR_STATES[UIs[current_party_member].buttonmode] == "DEFEND" then

                --No extra commands neeed for the party member to defend
                Commands[current_party_member][1] = function ()

                    return "DEFCOMMAND"

                end

                Commands[current_party_member][2] = party_members[current_party_member].name.." defended!" --Not displayed, necessary for regular flow of program.

                --Advance to next opponent or move on to executing every command?
                current_party_member = current_party_member + 1
                if current_party_member > #party_members then
                    current_party_member = 0
                    current_state = "COMMANDS"
                    ExecuteCommands()
                else
                    UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                    current_state = "BATTLEUI"
                end
                selected_enemy = nil
                end
        end

    elseif current_state == "ATTACKUI" then --This is when you select which enemy to attack

        if key == "x" then
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI")
            party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = enemies[Sole.currentmenuposition]
            selected_enemy = enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = enemies[Sole.currentmenuposition]

            enemies_to_attack[#enemies_to_attack+1] = selected_enemy
            Commands[current_party_member][1] = function ()
                return "ATTACKCOMMAND"
            end

            Commands[current_party_member][2] = "* "..party_members[current_party_member].name.." attacked "..selected_enemy.name.."!" --Not displayed, necessary for regular flow of program.

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #party_members then
                current_party_member = 0
                current_state = "COMMANDS"
                ExecuteCommands()
            else
                UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                current_state = "BATTLEUI"
            end
                selected_enemy = nil
            Sole:updatePosArray(nil)
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif current_state == "ACTUI" then --This is where you select which enemy to act with
        if key == "x" then
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI")
            party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = enemies[Sole.currentmenuposition]
            UIs[current_party_member]:menuState(Sole, 0, 0, "ACTSUBSUB", act_sub_subs[selected_enemy])
            Sole:updatePosArray(act_sub_subs[selected_enemy])
        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)
        end

    elseif current_state == "ACTSUBSUB" then --The various acts done with an enemy show up in this state
        if key == "x" then
            love.audio.play(SND_SELECT)
            selected_enemy = nil
            UIs[current_party_member]:menuState(Sole, 0, 0, "ACTUI", Enemysubarray)
            party_members[current_party_member]:set_animation(0)

        elseif key == "z" then
            actname[current_party_member] = Sole.positions[Sole.currentmenuposition][1]
            actindex[current_party_member] = Sole.currentmenuposition
            love.audio.play(SND_SELECT)
            print(selected_enemies[current_party_member].name.." added to queue to be acted with.")

            Commands[current_party_member][1] = function()


                party_members[current_party_member]:act(selected_enemies[current_party_member], actname[current_party_member], UIs[current_party_member])

            end

            Commands[current_party_member][2] = act_sub_subs[selected_enemies[current_party_member]][actindex[current_party_member]][4]

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #party_members then
                current_party_member = 0
                current_state = "COMMANDS"
                ExecuteCommands()
            else
                UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                current_state = "BATTLEUI"
            end
            selected_enemy = nil

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)

        end

    elseif current_state == "SPAREUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
            UIs[current_party_member]:menuState(Sole, 0, 0, "BATTLEUI")
            party_members[current_party_member]:set_animation(0)
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = enemies[Sole.currentmenuposition]
            selected_enemies[current_party_member] = enemies[Sole.currentmenuposition]
            print(selected_enemies[current_party_member].name.." added to queue to be spared.")

            Commands[current_party_member][1] = function()

                party_members[current_party_member]:spare(selected_enemies[current_party_member])

                end

            Commands[current_party_member][2] = "* "..party_members[current_party_member].name.." spared "..selected_enemy.name.."!"

            --Go back to the Battle UI or move on to executing every command?
            current_party_member = current_party_member + 1
            if current_party_member > #party_members then
                current_party_member = 0
                current_state = "COMMANDS"
                ExecuteCommands()
            else
                UIs[current_party_member]:subtext("* A wild battle commentary appeared!")
                current_state = "BATTLEUI"
            end
            selected_enemy = nil

        elseif key == "left" then
            Sole:updatePos(-1)
        elseif key == "right" then
            Sole:updatePos(1)

        end

    elseif current_state == "COMMANDS" then

        if current_party_member <= #party_members then
            ExecuteCommands()
        end

    elseif  current_state == "ATTACKING" and key == "z" then
        ExecuteAttack()

    elseif current_state == "BATTLEOVER" then
        love.event.quit()
    end

    if current_party_member <= #party_members then
        print("Button mode: "..ARR_STATES[UIs[current_party_member].buttonmode])
    else
        print("Resetting to BATTLEUI next round")
    end
    print("Current State: "..current_state)
    print("Party Member:"..current_party_member)

end

function love.draw()

    Bg:draw()

    --UI Purple line (top)
    love.graphics.setColor(51/255, 32/255, 51/255)
    love.graphics.rectangle("fill", 0, 684, 1280, 4)

    --UI Background (black)
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",0,687,1280,273)

    --UI Purple line (bottom)
    love.graphics.setColor(51/255, 32/255, 51/255)
    love.graphics.rectangle("fill", 0, 733, 1280, 4)

    love.graphics.setColor(1,1,1,1) --If you don't set to white when drawing images, the image colors get altered.

    for i = 1, #party_members do
        party_members[i]:draw()
    end

    for i = 1, #UIs do
        UIs[i]:draw()
    end
    for i = 1,#enemies do
        if enemies[i] then
            enemies[i]:draw()
        end
    end

    Enemysub:draw()

    Mizzle1sub:draw()
    Mizzle2sub:draw()
    Mizzle3sub:draw()

    for i = 1, #battlebars do
        battlebars[i]:draw()
    end

    Box:draw()

    Sole:draw()

    local FPS = love.timer.getFPS()

    if FPS >= 30 then
        love.graphics.setColor(0,1,0,1)
    elseif 30 >= FPS and FPS > 15 then
        love.graphics.setColor(1,1,0,1)
    elseif FPS < 15 then
        love.graphics.setColor(1,0,0,1)
    end

    love.graphics.setFont(Battlefont)
    love.graphics.print("FPS:"..FPS, 0, 0, 0, 1, 1)

    FPS = nil

end