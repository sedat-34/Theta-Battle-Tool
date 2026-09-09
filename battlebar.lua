BattleBar = Object:extend()

function BattleBar:new(rectanglex, y, i, target_member, target_enemy)
    -- self.x = 0
    self.rectanglex = rectanglex
    self.y = y
    self.target_member_no = i
    self.target_member = target_member
    self.target_enemy = target_enemy

    self.used = false
    self.target_image = love.graphics.newImage("sprites/battleUI/"..self.target_member.name.."_target.png")
    self.attackrectangle = love.graphics.newImage("sprites/battleUI/attackrectangle.png")
end

function BattleBar:attack()

    local mult = math.floor(math.abs(self.rectanglex - (900+100*self.target_member_no) )/100) --multiplier used in ATK calculation

    if self.rectanglex < -50 then mult = 0 end

    if not self.used then
        self.used = true
        self.target_member:attack(self.target_enemy, mult)
        self.enemies = nil
        Controller:setPartyMember(Controller:getPartyMember() + 1)
    end
end

function BattleBar:draw()
    if not self.used then
        love.graphics.draw(self.target_image, 0, self.y, 0, 1.5, 1.5)
        love.graphics.draw(self.attackrectangle, self.rectanglex, self.y, 0, 1.5, 1.5)
    end
end

function BattleBar:update(dt)
    if not self.used then
        self.rectanglex = self.rectanglex - 750*dt
        if self.rectanglex < -50 then
            self:attack()
        end
    end
end