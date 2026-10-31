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
rpc = {}
rpc.discordRPC = require "discordRPC"

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

--Place state-tracking variables here

selected_enemy = nil

--Variables for main menu tracking!
local battling
local errorMountingLastTime



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

--This object exists purely to let tick know how to cancel the BULLETSCleanup delay
--This is necessary as without it, BULLETSCleanup gets called at the start of the next battle.
--This is also the sole reason main has a StartBULLETS function at all.

local tickObjectForBULLETSCleanup

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

--Added to support rendering properly in LÖVE 12.0 onwards.
local dpi = love.graphics.getDPIScale()

--Debug variables! Currently there's only one, as FPS is the only "debug" value shown on-scren.
--I don't plan on making these values toggleable in-game
--As for printed debug statements, they won't be toggleable at all as they can't bother someone who doesn't purposefully launch it via lovec from the terminal.
local DisplayFPS = false

--[[
    Although you can, I'd advise against placing anything battle-specific here.
    That kind of defeats the point of having made an engine instead of a messily-coded fangame.
]]

function love.load()


    rpc.discordRPC.initialize("1565815665007530129", true) --Application IDs should normally not be shared, but not much can be done with a Discord Application ID.
                                                           --"Oh no! Someone advertised my engine for free!" is not a real problem.
    local now = os.time(os.date("*t"))
    print(now)
    print(os.time())
    rpc.presence = {
        details = "Choosing a battle",
        startTimestamp = now,
        largeImageKey = "tbt-logo-large",
    }

    rpc.nextPresenceUpdate = 0

    love.keyboard.setTextInput(true)

    battling = false
    errorMountingLastTime = false

end

local function startBattle()

    local path = "encounters/"..typedName..".zip"
    encounterdata = love.filesystem.newFileData(path)

    if encounterdata then
        love.filesystem.mount(encounterdata, typedName..".zip", "", true)
        rpc.presence.details = "Playing "..string.upper(typedName)..".zip"
        SplashSong:stop()
        Controller:load()
        battling = true
        errorMountingLastTime = false
        love.keyboard.setTextInput(false)
    else
        errorMountingLastTime = true
    end

end

local function returnToTitle()
    battling = false
    errorMountingLastTime = false
    if tickObjectForBULLETSCleanup then
        tick.remove(tickObjectForBULLETSCleanup)
        tickObjectForBULLETSCleanup = nil
    end
    Controller.encounter.MUS_Battlemusic:stop()
    Controller.encounter = {}
    Controller:returnToTitle()
    rpc.presence.state = ""
    rpc.presence.details = "Choosing a battle"
    local success = love.filesystem.unmount(typedName..".zip")
    love.keyboard.setTextInput(true)
    print("File unmounted:")
    print(success)
    encounterdata = nil
    typedName = ""
end

function love.update(dt)

    if battling then
        Controller:update(dt)

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

    if rpc.nextPresenceUpdate <= 0 then
        rpc.nextPresenceUpdate = dt
        rpc.discordRPC.updatePresence(rpc.presence)
    else
        rpc.nextPresenceUpdate = rpc.nextPresenceUpdate - dt
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

    selected_enemy = nil
    Controller:BULLETSCleanup()
    collectgarbage("collect")

end

function StartBULLETS()
        --Collect garbage
        collectgarbage("collect")

        Controller:StartBULLETS()
        tickObjectForBULLETSCleanup = tick.delay(function() BULLETSCleanup() tickObjectForBULLETSCleanup = nil end, 5)
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

        Controller:CheckWhetherToRunACommand(key)
        Controller:heartBeat(key)

        if Controller:getState() == "BATTLEOVER" then
            returnToTitle()
        end

        if Controller:getState() ~= "BULLETS" then
            print("Current State: "..Controller:getState())
            print("Party Member:"..Controller:getPartyMember())
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

    love.graphics.push()
    love.graphics.scale(1/dpi, 1/dpi)

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

    love.graphics.pop()

end