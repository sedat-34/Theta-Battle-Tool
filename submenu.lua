--Here you can find all the submenus of the game
--It's actually really simple, and most of the logic related to selection is handled externally (the soul's position and the main game loop)
--This class only generates the graphics of any submenu

Submenu = Object:extend()

function Submenu:new(list, targetstatearr, submenutype, targetobject)

    --These are absolutely REQUIRED. No exceptions.
    self.list = list --List of indexed strings
    self.targetstatearr = targetstatearr --Array of encounter states where the submenu is displayed

    --"enemy", "enemylist", "partymember" or "other"
    self.submenutype = submenutype

    --if submenu type is "other", set to nil. otherwise set to the OBJECT (not index!) of the targeted member or enemy.
    self.targetobject = targetobject

    --Move user-defined item positions  to standardised x, y positions.
    --Currently, only 4 items per submenu is supported.
    --This is because I don't want to implement scrolling among items!
    self.indexpositions = {
        [1] = {x = 218, y = 771},
        [2] = {x = 778, y = 771},
        [3] = {x = 218, y = 851},
        [4] = {x = 778, y = 851},
    }

end

function Submenu:draw(localcurrentstate, enemies)
    local targetstate = false

    for i = 1, #self.targetstatearr do
        if self.targetstatearr[i] == localcurrentstate then
            targetstate = true break
        end
    end

    local objectmatches = false
    if self.submenutype == "other" or self.submenutype == "enemylist" then objectmatches = true end
    if self.submenutype == "enemy" and selected_enemy == self.targetobject then objectmatches = true end
    if self.submenutype == "partymember" and Controller.encounter.party_members[Controller:getPartyMember()] == self.targetobject then objectmatches = true end
    if targetstate and objectmatches then
        for i = 1, #self.list do

            love.graphics.setFont(Battlefont)
            love.graphics.setColor(1, 1, 1, 1)

            if self.submenutype == "enemylist" and enemies[i].sparable then--Sparable enemies show up as Yellow on all enemy submenus
                love.graphics.setColor(1, 0.85, 0.3, 1)
            end

            love.graphics.print("* "..self.list[i].name, self.indexpositions[i].x, self.indexpositions[i].y)

        end
    end
end