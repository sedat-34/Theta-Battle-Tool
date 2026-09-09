Object = require "classic"
require "partyMember"
require "background"
require "battleui"
require "battlebar"
require "submenu"
require "battlebox"
flux = require "flux"
tick = require "tick"
json = require "json"
local tlfres = require "tlfres"
require "item"
require "itemmanager"
Controller = require "battlecontroller" --The battle middle-manager. Intentionally global.

if love.filesystem.isFused() then
    local dir = love.filesystem.getSourceBaseDirectory()
    love.filesystem.mount(dir, "", true)
end

--Best for blurless scaling
love.graphics.setDefaultFilter( "nearest", "nearest", 1)

--Place constant values here.

local WIDTH = 1280
local HEIGHT = 960

--The game's fonts.
--These need to be global because too many engine components rely on them.
--They're also present in every Deltarune battle ever
--If you need your own fonts, feel free to load them in your Encounter() and implement custom fonts for your draw() calls!
Battlefont = love.graphics.newFont("fonts/8bitOperatorPlus-Bold.ttf", 30)
Goldenfont = love.graphics.newImageFont("sprites/goldennumeralfont.png", "0123456789+-%/ ")--The mercy increased font
HPfont = love.graphics.newFont("fonts/deltarune-hp-font.otf", 14)

--Basic sound effects.
--Again, only global because these are present in every encounter
--You can load your custom sound effects in your battle!
SND_MENUMOVE = love.audio.newSource("sfx/snd_menumove.wav", "static")
SND_SELECT = love.audio.newSource("sfx/snd_select.wav", "static")
SND_ATTACK = love.audio.newSource("sfx/snd_attack.wav", "static")
SND_HURT = love.audio.newSource("sfx/snd_hurt1.wav", "static")

--Load certain feedback sprites
LOST = love.graphics.newImage("sprites/LOST.png")
RECRUIT = love.graphics.newImage("sprites/RECRUIT.png")

--The very culmination of your being ;)

--Place state-tracking variables here

selected_enemy = nil

--Variables for main menu tracking!
local battling
local errorMountingLastTime

--TODO Move most of these to the Controller object. The Controller is meant to be the middle-manager for the battle, so it should handle most of these variables.
local members_to_attack
local enemies_to_attack
local battlebars

local actname
local actindex

--Arrays used for submenus:
local selected_enemies

--Splashscreen stuff goes here
local SplashScreen = love.graphics.newImage("sprites/ThetaBattleTool-Titlecard.png")
local SplashSong = love.audio.newSource("music/flowery.ogg", "stream")

--used to detect the manually typed out game name.
local typedName = ""
--used to track how long since the last time typedName was truncated.
local typedNameTruncCounter = 0
--the filedata of the encounter
local encounterdata

--check how long esc. was held down for. Returns to title at 3 seconds.
--also used to update the "Quitting" sprite displayed at the top left
local escapeHeldTimer = 0

--The actual sprite and quadrant data for "Quitting...."
local quittingImage = love.graphics.newImage("sprites/quitting.png")
local quittingJsonRaw = love.filesystem.read("sprites/quitting.json")
local quittingQuadrantData = json.decode(quittingJsonRaw)
quittingJsonRaw = nil

local quittingsheetwidth = 435
local quittingsheetheight = 10

local quittingQuadrants = {}
for i = 0, 4 do
    local localQuadData = quittingQuadrantData.frames[tostring(i)].frame
    quittingQuadrants[i] = love.graphics.newQuad(localQuadData.x, localQuadData.y, localQuadData.w, localQuadData.h, quittingsheetwidth, quittingsheetheight)
end

--Technically invalid syntax but equivalent to setting all 3 to nil
quittingsheetheight, quittingsheetwidth, quittingQuadrantData = nil


--Debug variables! Currently there's only one, as FPS is the only "debug" value shown on-scren.
--I don't plan on making these values toggleable in-game
--As for printed debug statements, they won't be toggleable at all as they can't bother someone who doesn't purposefully launch it via lovec from the terminal.
local DisplayFPS = false

--[[
    Although you can, I'd advise against placing anything battle-specific here.
    That kind of defeats the point of having made an engine instead of a messily-coded fangame.
    (Also in the far future there's a chance support is added for an exchangable battle loader)
]]

function love.load()

    battling = false
    errorMountingLastTime = false

end

local function startBattle()

    members_to_attack = {}
    enemies_to_attack = {}
    battlebars = {}
    actindex = {}
    selected_enemies = {}

    local path = "encounters/"..typedName..".zip"
    encounterdata = love.filesystem.newFileData(path)

    if encounterdata then
        love.filesystem.mount(encounterdata, typedName..".zip", "", true)
        SplashSong:stop()
        Controller:load()
        battling = true
        errorMountingLastTime = false
    else
        errorMountingLastTime = true
    end

end

local function returnToTitle()
    battling = false
    errorMountingLastTime = false
    Controller.encounter.MUS_Battlemusic:stop()
    Controller.encounter = {}
    Controller:returnToTitle()
    local success = love.filesystem.unmount(typedName..".zip")
    print("File unmounted:")
    print(success)
    encounterdata = nil
    typedName = ""
end

function love.update(dt)

    if battling then
        Controller:update(dt)

        for i = 1, #battlebars do
            if battlebars[i] then
                battlebars[i]:update(dt)
            end
        end

        tick.update(dt)

        flux.update(dt)

        local allenemiesdead = true

        if #Controller.encounter.Enemysubarray > 0 then
            allenemiesdead = false
        end

        local allmembersdead = true

        for i = 1, #Controller.encounter.party_members do
            if Controller.encounter.party_members[i].hp > 0 then
                allmembersdead = false
            end
        end

        if allenemiesdead or allmembersdead then
            Controller:setState("BATTLEOVER")
            Controller:BATTLEOVER()
        end
        if love.keyboard.isDown("escape") then
            escapeHeldTimer = escapeHeldTimer + dt
            if escapeHeldTimer >= 3 then
                print("ESC held for 3 secs or more, returning to title screen.")
                escapeHeldTimer = 0
                returnToTitle()
            end
        else
            escapeHeldTimer = 0
        end
    else
        if not SplashSong:isPlaying() then
            SplashSong:play()
        end
        if love.keyboard.isDown("backspace") and typedName:len() > 0 then
            if typedNameTruncCounter > 0.07 then
                typedName = typedName:sub(1, -2)
                typedNameTruncCounter = 0
            else
                typedNameTruncCounter = typedNameTruncCounter + dt
            end
        end
    end

end

local function BULLETSCleanup()

    Controller.encounter.Box:set_animation("closing")

    --Collect garbage and reset to first non-downed party member. If all are downed, set to 1 and trigger BATTLEOVER with a "You Lost" subtext.
    local noOneLeft = true
    for i = 1, #Controller.encounter.party_members do
        if Controller.encounter.party_members[i].hp > 0 then
            Controller:setPartyMember(i)
            noOneLeft = false
            break
        end
    end

    for i = 1, #Controller.encounter.party_members do
        if Controller.encounter.party_members[i].hp > 0 then
            Controller.encounter.party_members[i].isdefending = false
            Controller.encounter.party_members[i]:set_animation("idle")
        end
    end

    if noOneLeft then
        Controller:BATTLEOVER()
        Controller:setState("BATTLEOVER")
    end

    selected_enemies = {}
    selected_enemy = nil
    actname = {}
    actindex = {}
    Controller:BULLETSCleanup()
    collectgarbage("collect")

end

local function StartBULLETS()
        --Collect garbage
        members_to_attack = {}
        enemies_to_attack = {}
        battlebars = {}
        collectgarbage("collect")

        Controller:StartBULLETS()
        tick.delay(function() BULLETSCleanup() end, 5)
        Controller:setState("BULLETS")
end

local function ExecuteAttack(enemies)

    print("ExecuteAttack()")
    print("Controller:getPartyMember(): "..Controller:getPartyMember())

    Controller:setState("ATTACKING")

    if #members_to_attack > 0 and #battlebars == 0 then
        print("members_to_attack: "..#members_to_attack)

        for i = 1, #members_to_attack do
            local k = 1
            local baroffsetcoefficient = 1 --Used to position the battlebars correctly and get the correct partyMember index.

            while k < #Controller.encounter.party_members + 1 do
                if Controller.encounter.party_members[k] == members_to_attack[i] then
                    baroffsetcoefficient = k
                    print("baroffsetcoefficient: "..baroffsetcoefficient)
                end
                k = k+1
            end

            battlebars[i] = BattleBar(900+100*baroffsetcoefficient, 738+41*1.5*(baroffsetcoefficient-1), baroffsetcoefficient, members_to_attack[i], enemies_to_attack[i])

        end

    elseif Controller:getPartyMember() <= #battlebars then

        if battlebars[Controller:getPartyMember()] then
            battlebars[Controller:getPartyMember()]:attack()
        end

    end

    if Controller:getPartyMember() > #battlebars then

        Controller.doneNavigating = true

        StartBULLETS()

    end


end

--Don't touch this unless you are CERTAIN you know what you are doing.
--This function handles every command passed through the UI.
--That means all of FIGHT/ACT...MERCY is handled here.

local function ExecuteCommands()

    local CommandReturned = nil

    Controller:setState("COMMANDS")

    print("ExecuteCommands()")

    Controller:setPartyMember(Controller:getPartyMember() + 1)

    local isMemberDowned
    if Controller.encounter.party_members[Controller:getPartyMember()] then
        isMemberDowned = Controller.encounter.party_members[Controller:getPartyMember()].hp <= 0
    end

    if isMemberDowned then
        if Controller:getPartyMember() == #Controller.encounter.party_members then
            if #members_to_attack > 0 then

            Controller:setPartyMember(1)

            for i = 1, #Controller.encounter.party_members do
                Controller.encounter.UIs[i]:subtext("")
            end
            Controller:setState("ATTACKING")
            ExecuteAttack()
            return
        else
            Controller.doneNavigating = true
            StartBULLETS()
            return
        end
        end
    end

    print("Controller:getPartyMember() @ COMMANDS: "..Controller:getPartyMember())

    if Controller:getPartyMember() <= #Controller.encounter.party_members then
        if Controller:getCommand(Controller:getPartyMember(), 1) then --TODO Ensure that the Command for a downed partyMember is empty.
            Controller.encounter.UIs[Controller:getPartyMember()]:subtext(Controller:getCommand(Controller:getPartyMember(),2))
            CommandReturned = Controller:runCommand(Controller:getPartyMember(), 1)
            if CommandReturned then
                print("Command executed: "..CommandReturned.." by: "..Controller.encounter.party_members[Controller:getPartyMember()].name)
            end
        end
        if CommandReturned == "DEFCOMMAND" then
            Controller.encounter.party_members[Controller:getPartyMember()].isdefending = true
            Controller.encounter.party_members[Controller:getPartyMember()]:set_animation("DEFEND")
            print("Member defended! Now running Executecommands()")
            ExecuteCommands()
            return
        elseif CommandReturned == "ATTACKCOMMAND" then
            members_to_attack[#members_to_attack+1] = Controller.encounter.party_members[Controller:getPartyMember()]
            print("Latest member to attack: "..members_to_attack[#members_to_attack].name)
            ExecuteCommands()
            return
        end
    end

    if Controller:getPartyMember() >= #Controller.encounter.party_members + 1 then

        Controller:BULLETSCleanup()

        for i = 1, #Controller.encounter.party_members do
            Controller.encounter.party_members[i].hpup = nil
        end

        if #members_to_attack > 0 then

            Controller:setPartyMember(1)

            for i = 1, #Controller.encounter.party_members do
                Controller.encounter.UIs[i]:subtext("")
            end
            Controller:setState("ATTACKING")
            ExecuteAttack()
            return
        else
            Controller.doneNavigating = true
            StartBULLETS()
            return
        end

    end

end

function love.mousepressed(x, y, button)

    if button == 1 then
        print(x..", "..y)
    end

end

function love.textinput(text)
    if not battling and (text ~= "enter" and text ~= "kpenter") then
        typedName = typedName..text
        if errorMountingLastTime then errorMountingLastTime = false end
    end
end

function love.keypressed(key)

    if battling and (#Controller.encounter.party_members == 0 or #Controller.encounter.enemies == 0) then
        returnToTitle()
        return
    end

    if battling then

        print("Controller's state = "..Controller:getState())

        if Controller:getState() == "COMMANDS" then

            if Controller:getPartyMember() <= #Controller.encounter.party_members then
                ExecuteCommands()
            end

        elseif Controller:getState() == "ATTACKING" and key == "z" then

            ExecuteAttack(Controller.encounter.enemies)

        elseif Controller:getState() == "BATTLEOVER" then
            returnToTitle()
        end

        if Controller:getState() ~= "BULLETS" then
            print("Current State: "..Controller:getState())
            print("Party Member:"..Controller:getPartyMember())
        end

        --This has to run after the above to prevent misfires.
        local remainingDowned --bool. if all remaining party_members are downed, true.

        selected_enemies, enemies_to_attack, actname, actindex, remainingDowned = Controller:heartBeat(key, selected_enemies, enemies_to_attack, actname, actindex)

        --Go back to the Battle UI or move on to executing every command?
        if (Controller.doneNavigating and Controller:getPartyMember() > #Controller.encounter.party_members) or remainingDowned then
            Controller:setPartyMember(0)
            Controller:setState("COMMANDS")
            ExecuteCommands()
            Controller.Soul:updatePosArray(nil)
        elseif Controller.doneNavigating and Controller:getState() ~= "BULLETS" and Controller:getState() ~= "COMMANDS" and Controller:getState() ~= "ATTACKING" then
            Controller.encounter.UIs[Controller:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            Controller.encounter.UIs[Controller:getPartyMember()]:menuState(Controller.Soul, 0, 0, "BATTLEUI", {})
            Controller:setState("BATTLEUI")
            Controller.doneNavigating = false
            selected_enemy = nil
        end
    else

        if key == "return" or key == "kpenter" then
            startBattle()
        elseif key == "backspace" and typedName:len() > 0 then
            typedName = string.sub(typedName, 1, -2)
            if errorMountingLastTime then errorMountingLastTime = false end
        end

    end
end

function love.draw()

    tlfres.beginRendering(WIDTH, HEIGHT)

    if battling then

        love.graphics.setPointSize(tlfres.getScale())

        Controller:drawBackground()

        --UI Purple line (top)
        love.graphics.setColor(51/255, 32/255, 51/255)
        love.graphics.rectangle("fill", 0, 684, 1280, 4)

        --UI Background (black)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",0,687,1280,273)

        --UI Purple line (bottom)
        love.graphics.setColor(51/255, 32/255, 51/255)
        love.graphics.rectangle("fill", 0, 733, 1280, 4)

        love.graphics.setColor(1,1,1,1) --If you don't set to white when drawing images, the image colors may get altered.

        Controller:drawForeground()

        for i = 1, #Controller.encounter.UIs do
            Controller.encounter.UIs[i]:draw(Controller:getState(), Controller.encounter.party_members)
        end

        for i = 1, #battlebars do
            battlebars[i]:draw()
        end

        if escapeHeldTimer > 0 then
            local index = math.floor(escapeHeldTimer*5/3)
            love.graphics.setColor(1, 1, 1)
            local yposition
            if DisplayFPS then
                yposition = 50
            else
                yposition = 0
            end

            if quittingQuadrants[index] then
                love.graphics.draw(quittingImage, quittingQuadrants[index], 0, yposition, 0, 3, 3)
            end
        end

    else
        --A primitive title screen. This is just a placeholder 'till I make a better one.

        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(SplashScreen, 0, 0)
        love.graphics.setFont(Battlefont)
        love.graphics.print(typedName..".zip", 256, 600)

        if errorMountingLastTime then
            love.graphics.setColor(1, 0, 0)
            love.graphics.print("Couldn't load your encounter :(\nCheck for typos in the .zip name.", 256, 700)
        end

    end

    if DisplayFPS then

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

    tlfres.endRendering()

end