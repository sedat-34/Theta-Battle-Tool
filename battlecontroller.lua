local Controller = {}
local BulletManager = require "bulletmanager"
local BattlebarManager = require "battlebarmanager"
local selected_enemies

function Controller:load()
    love.graphics.setFont(Battlefont)
    self.encounter = require "encounter"
    self.encounter.current_state = "BATTLEUI"
    self.encounter.UIs[1]:subtext("* Cool initial description")
    self.current_state = "BATTLEUI"
    self.Commands = {}
    self.doneNavigating = false
    self.current_party_member = 1
    self.Soul = require "soul"

    --Pull data from encounter.lua's schema

    --Anything necessary for an encounter is checked with "assert", anything else is ifs and prints to log behaviour.
    assert(self.encounter.Enemysubarray, "[encounter.lua]: Missing self.Enemysubarray")
    self.Enemysubarray  = self.encounter.Enemysubarray
    self.encounter.Enemysub = Submenu(self.Enemysubarray, {"ATTACKUI", "ACTUI", "SPAREUI", "MAGICSUBSUB"}, "enemylist", nil)
    self.encounter.Enemysubsubs = {}
    for i = 1, #self.encounter.enemies do
        self.encounter.Enemysubsubs[i] = Submenu(self.encounter.act_sub_subs[self.encounter.enemies[i]], {"ACTSUBSUB"}, "enemy", self.encounter.enemies[i])
    end

    if self.encounter.magicSubArrays then
        self.magicSubArrays = self.encounter.magicSubArrays
        self.encounter.magicSubmenus = {}
        local iteratorForMagicSubarrays = 1
        for member, __ in pairs(self.encounter.magicSubArrays) do
            self.encounter.magicSubmenus[iteratorForMagicSubarrays] = Submenu(self.encounter.magicSubArrays[member], {"MAGICUI"}, "partymember", member)
            iteratorForMagicSubarrays = iteratorForMagicSubarrays + 1
        end
    else
        print("[encounter.lua]: Missing self.magicSubArrays, expect weird behaviour for magic members.")
    end

    if self.encounter.items and self.encounter.ItemSubArray then
        self.ItemManager = ItemManager(self.encounter.items, self.encounter.ItemSubArray)
        self.encounter.ItemSub = Submenu(self.encounter.ItemSubArray, {"ITEMUI"}, "other", nil)
        self.encounter.ItemSubArray = {}
        for i = 1, #self.encounter.items do
            self.encounter.ItemSubArray[i] = {name = self.encounter.items[i].name}
        end
    else
        print("[encounter.lua]: Missing self.items, expect weird behaviour")
    end

    self.encounter.Box = Battlebox()

    assert(self.encounter.PartyMemberSubArray, "[encounter.lua]: Missing self.PartyMemberSubArray")
    self.encounter.PartyMemberSub = Submenu(self.encounter.PartyMemberSubArray, {"MEMBERUI"}, "other", nil)

    assert(self.encounter.bulletSheetPath, "[encounter.lua]: Missing self.bulletSheetPath")
    assert(self.encounter.bulletSheetDataPath, "[encounter.lua]: Missing self.bulletSheetDataPath")
    assert(self.encounter.bulletPatterns, "[encounter.lua]: Missing self.bulletPatterns")

    --These two are used to generate the act, magic commands
    self.encounter.actname = {}
    self.encounter.actindex = {}

    --Load local external modules' objects.
    BulletManager:load(self.encounter.bulletSheetPath, self.encounter.bulletSheetDataPath, self.encounter.bulletPatterns)
    BattlebarManager:load()
    selected_enemies = {}
    love.audio.play(self.encounter.MUS_Battlemusic)
    self:BULLETSCleanup()
end

function Controller:returnToTitle()
    for key, __ in pairs(self.encounter) do
        self.encounter[key] = nil
    end
    self.encounter = nil
    package.loaded["encounter"] = nil
    _G["encounter"] = nil
    BulletManager:quitBattle()
end

function Controller:getState() --Return the battle's current state
    return self.current_state
end

function Controller:setState(state) --Set the battle's current state
    self.current_state = state
end

function Controller:getPartyMember() --Return current_party_member index
    return self.current_party_member
end

function Controller:setPartyMember(current_party_member)
    self.current_party_member = current_party_member
end

function Controller:ProcessAttackCommand()
    BattlebarManager.members_to_attack[#BattlebarManager.members_to_attack+1] = Controller.encounter.party_members[Controller:getPartyMember()]
    print("Latest member to attack: "..BattlebarManager.members_to_attack[#BattlebarManager.members_to_attack].name)
end

function Controller:Attack()
    if #BattlebarManager.members_to_attack > 0 and #BattlebarManager.battlebars == 0 then
        print("BattlebarManager.members_to_attack: "..#BattlebarManager.members_to_attack)

        for i = 1, #BattlebarManager.members_to_attack do
            local k = 1
            local baroffsetcoefficient = 1 --Used to position the BattlebarManager.battlebars correctly and get the correct partyMember index.

            while k < #Controller.encounter.party_members + 1 do
                if Controller.encounter.party_members[k] == BattlebarManager.members_to_attack[i] then
                    baroffsetcoefficient = k
                    print("baroffsetcoefficient: "..baroffsetcoefficient)
                end
                k = k+1
            end

            BattlebarManager.battlebars[i] = BattleBar(900+100*baroffsetcoefficient, 738+41*1.5*(baroffsetcoefficient-1), baroffsetcoefficient, BattlebarManager.members_to_attack[i], BattlebarManager.enemies_to_attack[i])

        end

    elseif Controller:getPartyMember() <= #BattlebarManager.battlebars then

        if BattlebarManager.battlebars[Controller:getPartyMember()] then
            BattlebarManager.battlebars[Controller:getPartyMember()]:attack()
        end

    end
    return Controller:getPartyMember() > #BattlebarManager.battlebars
end

function Controller:drawBackground()
    self.encounter.Bg:draw()
end

function Controller:drawForeground()

    for i = 1, #self.encounter.party_members do
        self.encounter.party_members[i]:draw()
    end

    for i = 1,#self.encounter.enemies do
        if self.encounter.enemies[i] then
            self.encounter.enemies[i]:draw()
        end
    end

    self.encounter.Enemysub:draw(self:getState(), self.encounter.enemies)
    for __, sub in pairs(self.encounter.Enemysubsubs) do
        sub:draw(self:getState(), self.encounter.enemies)
    end
    self.encounter.PartyMemberSub:draw(self:getState(), self.encounter.enemies)
    self.encounter.ItemSub:draw(self:getState(), self.encounter.enemies)
    if self.encounter.magicSubmenus then
        for __, sub in pairs(self.encounter.magicSubmenus) do
            sub:draw(self:getState(), self.encounter.enemies)
        end
    end

    self.encounter.Box:draw()

    self.Soul:draw(self:getState())

    BattlebarManager:draw()

    BulletManager:draw(self:getState())

end

function Controller:StartBULLETS()
    Controller:setState("BULLETS")
    Controller:setPartyMember(1)
    for i = 1, #Controller.encounter.party_members do
        Controller.encounter.UIs[i]:subtext("")
    end
    Controller.encounter.Box:set_animation("opening")
    self.Soul:updateLimits(Controller.encounter.Box)
    self.Soul:centerInBox()
end

function Controller:update(dt)
        for i = 1, #self.encounter.enemies do
        if self.encounter.enemies[i] then
            self.encounter.enemies[i]:update(dt, self:getState(), self.encounter.enemies)
        end
    end

    for i = 1, #self.encounter.party_members do
        self.encounter.party_members[i]:update(dt)
    end

    self.encounter.Bg:update(dt)

    self.Soul:update(dt, self:getState())

    self.encounter.Box:update(dt)

    BulletManager:update(dt, self:getState())

    BattlebarManager:update(dt)

    --print(love.mouse.getX().." , "..love.mouse.getY()) --I use this when checking positions in the UI.

    if not self.encounter.MUS_Battlemusic:isPlaying() then
        love.audio.play(self.encounter.MUS_Battlemusic)
    end
end

function Controller:BULLETSCleanup() --Self-explanotory.
    for i = 1, #self.encounter.party_members do
        self.Commands[i] = {}
        self.encounter.UIs[i]:subtext("* A wild battle commentary appeared!")
        self.encounter.UIs[i].buttonmode = 1
        self:setCommand(i, 1, nil)
        self:setCommand(i, 2, nil)
    end
    self.encounter.actindex = {}
    self.encounter.actname = {}
    self.doneNavigating = false
    self:setState("BATTLEUI")
end

function Controller:BATTLEOVER()
    local noOneLeft = true

    for __, member in pairs(self.encounter.party_members) do
        if member.hp > 0 then
            noOneLeft = false
            break
        end
    end

    if noOneLeft then
        for __, UI in pairs(self.encounter.UIs) do
            UI:subtext("* Battle is over, you lost!\n* Press any key to exit.")
        end
    else
        for __, member in pairs(self.encounter.party_members) do
            if member.hp <= 0 then member.hp = 1 end
            member:set_animation("end")
        end
        for __, UI in pairs(self.encounter.UIs) do
            UI:subtext("* Battle is over, you win!\n* Press any key to exit.")
        end
    end
    self.Soul:updatePosArray(0)
end

function Controller:setCommand(partymemberindex, n, misc)
    --n = 1 -> The actual command
    --n = 2 -> Text given to the UIs wrapped in a function
    self.Commands[partymemberindex][n] = misc
end

function Controller:runCommand(partymemberindex, n) --For ExecuteCommands()!
    return self.Commands[partymemberindex][n]()
end

function Controller:getCommand(partymemberindex, n) --Check the command type or get the UI subtext
    return self.Commands[partymemberindex][n]
end

function Controller:handleDowned()
    local remainingDowned = false
    if (not self.encounter.party_members[self:getPartyMember()]) or self:getPartyMember() > #self.encounter.party_members then return end
    if self.encounter.party_members[self:getPartyMember()].hp <= 0 then
        while self.encounter.party_members[self:getPartyMember()].hp <= 0 and self:getPartyMember() < #self.encounter.party_members + 1 do
            self:setCommand(self:getPartyMember(), 1, nil)
            self:setCommand(self:getPartyMember(), 2, nil)
            self:setPartyMember(self:getPartyMember() + 1)
            if (not self.encounter.party_members[self:getPartyMember()]) or self:getPartyMember() > #self.encounter.party_members then remainingDowned = true break end
        end
    end
    return remainingDowned --Are all remaining party_members Downed?
end

local function ExecuteAttack()

    print("ExecuteAttack()")
    print("Controller:getPartyMember(): "..Controller:getPartyMember())

    Controller:setState("ATTACKING")
    local doneAttacking = Controller:Attack()

    if doneAttacking then

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
            if #BattlebarManager.members_to_attack > 0 then

                Controller:setPartyMember(1)

                for i = 1, #Controller.encounter.party_members do
                    Controller.encounter.UIs[i]:subtext("")
                end
                Controller:setState("ATTACKING")
                BattlebarManager.ExecuteAttack()
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
        if Controller:getCommand(Controller:getPartyMember(), 1) then
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
            Controller:ProcessAttackCommand() --ATTACKCOMMAND handling requires variables local to Controller().
            ExecuteCommands()
            return
        end
    end

    if Controller:getPartyMember() >= #Controller.encounter.party_members + 1 then

        Controller:BULLETSCleanup()

        for i = 1, #Controller.encounter.party_members do
            Controller.encounter.party_members[i].hpup = nil
        end

        if #BattlebarManager.members_to_attack > 0 then

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

function Controller:CheckWhetherToRunACommand(key)

    print("Controller's state = "..Controller:getState())

    if Controller:getState() == "COMMANDS" then

        if Controller:getPartyMember() <= #Controller.encounter.party_members then
            ExecuteCommands()
        end

    elseif Controller:getState() == "ATTACKING" and key == "z" then

        ExecuteAttack()

    end
 
end

--This if else statement is one of the cores of Theta Battle Tool
--It handles a majority of the UI logic and every single UI-related state change
--Do not edit this unless you're CERTAIN you know what you're doing.
--(Or have a backup, like the official one over at https://github.com/sedat-34/Theta-Battle-Tool)

function Controller:heartBeat(key)

    local ARR_STATES = self.encounter.party_members[self:getPartyMember()].ARR_BUTTON_STATES

    if self:getState() == "BATTLEUI" then --The main battle menu. If you see the five buttons, you're in this state.

        if key == "right" then
            self.encounter.UIs[self:getPartyMember()]:changeselect(1)
        elseif key == "left" then
            self.encounter.UIs[self:getPartyMember()]:changeselect(-1)
        elseif key == "x" and self:getPartyMember() ~= 1 then

            if self.encounter.party_members[self:getPartyMember()-1].hp <= 0 then --Block switching back to a downed party member.
                local cantDecrease = true
                local viableID = nil
                for i = self:getPartyMember(), 1, -1 do
                    if self.encounter.party_members[i].hp > 0 then
                        cantDecrease = false
                        viableID = i
                        break
                    end
                end


                if cantDecrease then
                    return nil
                else
                    if self:runCommand(viableID, 1) == "ITEMCOMMAND" then --Check whether to 
                        self.ItemManager:undoAddition()
                    end
                    self:setCommand(self:getPartyMember(), 1, nil)
                    self:setCommand(self:getPartyMember(), 2, nil)
                    self.encounter.UIs[viableID]:subtext("* A wild battle commentary appeared!")
                    self.encounter.UIs[viableID]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
                    self.encounter.party_members[viableID]:set_animation("idle")
                    love.audio.play(SND_SELECT)
                    self:setPartyMember(viableID)
                    return nil
                end

            end

            if self:runCommand(self:getPartyMember()-1, 1) == "ITEMCOMMAND" then
                self.ItemManager:undoAddition()
            end
            self:setState("BATTLEUI")
            self:setCommand(self:getPartyMember(), 1, nil)
            self:setCommand(self:getPartyMember(), 2, nil)
            self.encounter.UIs[self:getPartyMember() - 1]:subtext("* A wild battle commentary appeared!")
            self.encounter.UIs[self:getPartyMember() - 1]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
            self.encounter.party_members[self:getPartyMember() - 1]:set_animation("idle")
            love.audio.play(SND_SELECT)
            self:setPartyMember(self:getPartyMember() - 1)
        elseif key == "z" then
            self.encounter.UIs[self:getPartyMember()]:subtext(nil)
            love.audio.play(SND_SELECT)

            --Quick exception for selecting items or magic versus any submenus with the enemy list
            print(ARR_STATES[self.encounter.UIs[self:getPartyMember()].buttonmode])
            if ARR_STATES[self.encounter.UIs[self:getPartyMember()].buttonmode] == "ITEMUI" then
                if self.ItemManager then --Add failsafe conditional for itemless encounters
                    if #self.ItemManager.itemsSubArray > 0 then
                        self.Soul:updatePosArray(#self.ItemManager.itemsSubArray)
                        self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 631, 471, "ITEMUI", self.ItemManager.itemsSubArray)
                    end
                end
            elseif ARR_STATES[self.encounter.UIs[self:getPartyMember()].buttonmode] == "MAGICUI" then
                self.Soul:updatePosArray(#self.magicSubArrays[self.encounter.party_members[self:getPartyMember()]])
                self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 631, 471, "MAGICUI", self.magicSubArrays[self.encounter.party_members[self:getPartyMember()]])
            else
                self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 631, 471, ARR_STATES[self.encounter.UIs[self:getPartyMember()].buttonmode], self.Enemysubarray)
            end

            if self:getState() ~= "BATTLEUI" and ARR_STATES[self.encounter.UIs[self:getPartyMember()].buttonmode] ~= "DEFEND" then
                self.encounter.party_members[self:getPartyMember()]:set_animation(ARR_STATES[self.encounter.UIs[self:getPartyMember()].buttonmode])
            end

            if ARR_STATES[self.encounter.UIs[self:getPartyMember()].buttonmode] == "DEFEND" then

                --No extra commands needed for the party member to defend
                self:setCommand(self:getPartyMember(), 1,
                    function ()
                        return "DEFCOMMAND"
                    end)

                self:setCommand(self:getPartyMember(), 2, self.encounter.party_members[self:getPartyMember()].name.." defended!") --Not displayed, necessary for regular flow of program.
                self.doneNavigating = true
                self:setPartyMember(self:getPartyMember() + 1)

            end

        end

    elseif self:getState() == "ATTACKUI" then --This is when you select which enemy to attack

        if key == "x" then
            love.audio.play(SND_SELECT)
            self.encounter.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
            self.encounter.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = self.encounter.enemies[self.Soul.currentmenuposition]
            selected_enemies[self:getPartyMember()] = selected_enemy

            BattlebarManager.enemies_to_attack[#BattlebarManager.enemies_to_attack+1] = selected_enemy
            self:setCommand(self:getPartyMember(), 1,

            function ()
                return "ATTACKCOMMAND"
            end)

            self:setCommand(self:getPartyMember(), 2, "* "..self.encounter.party_members[self:getPartyMember()].name.." attacked "..selected_enemy.name.."!") --Not displayed, necessary for regular flow of program.
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end

    elseif self:getState() == "ACTUI" then --This is where you select which enemy to act with
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.encounter.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
            self.encounter.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = self.encounter.enemies[self.Soul.currentmenuposition]
            selected_enemies[self:getPartyMember()] = selected_enemy
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "ACTSUBSUB", self.encounter.act_sub_subs[selected_enemy])
            self.Soul:updatePosArray(#self.encounter.act_sub_subs[selected_enemy])
        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end

    elseif self:getState() == "ACTSUBSUB" then --The various acts done with an enemy show up in this state
        if key == "x" then
            love.audio.play(SND_SELECT)
            selected_enemy = nil
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "ACTUI", self.Enemysubarray)
            self.encounter.party_members[self:getPartyMember()]:set_animation("idle")

        elseif key == "z" then
            if not self.encounter.actname then self.encounter.actname = {} end
            self.encounter.actname[self:getPartyMember()] = self.encounter.act_sub_subs[selected_enemy][self.Soul.currentmenuposition].name
            self.encounter.actindex[self:getPartyMember()] = self.Soul.currentmenuposition
            love.audio.play(SND_SELECT)
            print(selected_enemies[self:getPartyMember()].name.." added to queue to be acted with.")

            self:setCommand(self:getPartyMember(), 1,

            function()

                if self:getState() == "COMMANDS" then self.encounter.party_members[self:getPartyMember()]:act(selected_enemies[self:getPartyMember()], self.encounter.actname[self:getPartyMember()], self.encounter.UIs[self:getPartyMember()]) end

                return "ACTCOMMAND"

            end)

            self:setCommand(self:getPartyMember(), 2, self.encounter.act_sub_subs[selected_enemies[self:getPartyMember()]][self.encounter.actindex[self:getPartyMember()]].subtext(self.encounter.party_members[self:getPartyMember()]))
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end

    elseif self:getState() == "MAGICUI" then

        --Clone of ACTUI behaviour, but with reverse order of actions.
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.encounter.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
            self.encounter.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            self.encounter.actindex[self:getPartyMember()] = self.Soul.currentmenuposition
            if self.encounter.magicSubArrays[self.encounter.party_members[self:getPartyMember()]][self.Soul.currentmenuposition].targetType == "member" then
                --Currently not supported.
            else
                self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "MAGICSUBSUB", self.encounter.magicSubArrays[self.encounter.party_members[self:getPartyMember()]])
            end
        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end

    elseif self:getState() == "MAGICSUBSUB" then

        if key == "x" then
            love.audio.play(SND_SELECT)
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "MAGICUI", self.magicSubArrays[self.encounter.party_members[self:getPartyMember()]])
        elseif key == "z" then
            selected_enemies[self:getPartyMember()] = self.encounter.enemies[self.Soul.currentmenuposition]
            self:setCommand(self:getPartyMember(), 1, function ()

                    if self:getState() == "COMMANDS" then self.encounter.magicSubArrays[self.encounter.party_members[self:getPartyMember()]][self.encounter.actindex[self:getPartyMember()]].magicFunction(selected_enemies[self:getPartyMember()]) end

                    return "MAGICCOMMAND"

                end)
            local currentactname = self.encounter.magicSubArrays[self.encounter.party_members[self:getPartyMember()]][self.encounter.actindex[self:getPartyMember()]].name
            local truncatedSpellName = string.sub(currentactname, string.len(currentactname) - 3, string.len(currentactname))
            print(truncatedSpellName.. " is the truncatedSpellName")
            if truncatedSpellName ~= "-ACT" then
                self:setCommand(self:getPartyMember(), 2, self.encounter.magicSubArrays[self.encounter.party_members[self:getPartyMember()]][self.encounter.actindex[self:getPartyMember()]].subtext)
            else
                if not self.encounter.actname then self.encounter.actname = {} end
                self.encounter.actname[self:getPartyMember()] = self.encounter.magicSubArrays[self.encounter.party_members[self:getPartyMember()]][self.encounter.actindex[self:getPartyMember()]].name
                print()
                print("self.encounter.actindex is"..self.encounter.actindex[self:getPartyMember()])
                self:setCommand(self:getPartyMember(), 2, selected_enemies[self:getPartyMember()]:subtext(self.encounter.actname[self:getPartyMember()]))
            end
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)
        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end

    elseif self:getState() == "ITEMUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.encounter.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
            self.encounter.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            self.ItemManager.tempitem = self.encounter.items[self.Soul.currentmenuposition]
            print(self.ItemManager.tempitem.name)
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "MEMBERUI", self.encounter.PartyMemberSubArray)
        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end

    elseif self:getState() == "MEMBERUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "ITEMUI", self.encounter.ItemSubArray)
            self.encounter.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)

            local itemtext = self.ItemManager:generateItemText(self.Soul.currentmenuposition, self:getPartyMember(), self.encounter.party_members)
            self.ItemManager:addItem(self.Soul.currentmenuposition, self:getPartyMember())

            self:setCommand(self:getPartyMember(), 1,

                function()

                    if self:getState() == "COMMANDS" then self.ItemManager:useItem(self.encounter) end
                    return "ITEMCOMMAND" --Functionally the same as an ACTCOMMAND, but labelled seperately for debugging purposes and code cleanliness.

                end)

            self:setCommand(self:getPartyMember(), 2, itemtext)
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end

    elseif self:getState() == "SPAREUI" then
        if key == "x" then
            love.audio.play(SND_SELECT)
            self.encounter.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
            self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
            self.encounter.party_members[self:getPartyMember()]:set_animation("idle")
        elseif key == "z" then
            love.audio.play(SND_SELECT)
            selected_enemy = self.encounter.enemies[self.Soul.currentmenuposition]
            selected_enemies[self:getPartyMember()] = selected_enemy
            print(selected_enemies[self:getPartyMember()].name.." added to queue to be spared.")

            self:setCommand(self:getPartyMember(), 1,

                function()

                    if self:getState() == "COMMANDS" then
                        self.encounter.party_members[self:getPartyMember()]:spare(selected_enemies[self:getPartyMember()])
                        self.encounter.party_members[self:getPartyMember()]:set_animation("spare")
                    end

                    return "SPARECOMMAND"

                end)

            self:setCommand(self:getPartyMember(), 2, "* "..self.encounter.party_members[self:getPartyMember()].name.." spared "..selected_enemy.name.."!")
            self.doneNavigating = true
            self:setPartyMember(self:getPartyMember() + 1)

        elseif key == "left" then
            self.Soul:updatePos(-1)
        elseif key == "right" then
            self.Soul:updatePos(1)
        end
    end

    local remainingDowned = self:handleDowned() --bool. if all remaining party_members are downed, true.

    --Go back to the Battle UI or move on to executing every command?
    if (self.doneNavigating and self:getPartyMember() > #self.encounter.party_members) or remainingDowned then
        self:setPartyMember(0)
        self:setState("COMMANDS")
        ExecuteCommands()
        self.Soul:updatePosArray(nil)
    elseif self.doneNavigating and self:getState() ~= "BULLETS" and self:getState() ~= "COMMANDS" and self:getState() ~= "ATTACKING" then
        self.encounter.UIs[self:getPartyMember()]:subtext("* A wild battle commentary appeared!")
        self.encounter.UIs[self:getPartyMember()]:menuState(self.Soul, 0, 0, "BATTLEUI", {})
        self:setState("BATTLEUI")
        self.doneNavigating = false
        selected_enemy = nil
    end
end

return Controller