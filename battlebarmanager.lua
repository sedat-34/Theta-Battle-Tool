local battlebarmanager = {}

function battlebarmanager:load()
    self.members_to_attack = {}
    self.enemies_to_attack = {}
    self.battlebars = {}
    self.currentmembercount = 1
end

function battlebarmanager:update(dt)
    for i = 1, #self.battlebars do
        if self.battlebars[i] then
            self.battlebars[i]:update(dt)
            if self.battlebars[i].rectanglex < -50 and Controller:getState() == "ATTACKING" then
                self:attack()
            end
        end
    end
end

function battlebarmanager:draw()
    for i = 1, #self.battlebars do
        self.battlebars[i]:draw()
    end
end

function battlebarmanager:attack()
    if self.currentmembercount <= #self.members_to_attack then
        self.battlebars[self.currentmembercount]:attack()
        self.currentmembercount = self.currentmembercount + 1
        if self.currentmembercount > #self.members_to_attack then
            Controller.doneNavigating = true
            StartBULLETS()
            self:load()
        end
    end
end

function battlebarmanager:generateBattlebars(party_members)
    print("self.members_to_attack: "..#self.members_to_attack)

    for i = 1, #self.members_to_attack do
        local baroffsetcoefficient = 1 --Used to position the self.battlebars correctly and get the correct partyMember index.

        for k = i, #party_members do
            if self.battlebars[k] then break end
            if party_members[k] == self.members_to_attack[i] then
                baroffsetcoefficient = k
                print("baroffsetcoefficient: "..baroffsetcoefficient)
                self.battlebars[i] = BattleBar(900+100*baroffsetcoefficient, 738+41*1.5*(baroffsetcoefficient-1), baroffsetcoefficient, self.members_to_attack[i], self.enemies_to_attack[i])
                break
            end
        end

    end
end

battlebarmanager:load()

return battlebarmanager