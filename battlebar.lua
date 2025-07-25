BattleBar = Object:extend()

function BattleBar:new(rectanlex, y, i)
    -- self.x = 0
    self.rectanlex = rectanlex
    self.y = y
    self.target_member_no = i

    self.used = false
    self.target_image = love.graphics.newImage("sprites/battleUI/"..party_members[self.target_member_no].name.."_target.png")
    self.attackrectangle = love.graphics.newImage("sprites/battleUI/attackrectangle.png")
end

function BattleBar:attack()

    local mult = math.floor(math.abs(self.rectanlex - (900+100*self.target_member_no) )/100) --multiplier used in ATK calculation

    if self.rectanlex < -50 then mult = 0 end

    if not self.used then
        self.used = true
        members_to_attack[self.target_member_no]:attack(enemies_to_attack[self.target_member_no], mult)
        current_party_member = current_party_member + 1
    end
end

function BattleBar:draw()
    if not self.used then
        love.graphics.draw(self.target_image, 0, self.y, 0, 1.5, 1.5)
        love.graphics.draw(self.attackrectangle, self.rectanlex, self.y, 0, 1.5, 1.5)
    end
end

function BattleBar:update(dt)
    self.rectanlex = self.rectanlex - 750*dt
    if self.rectanlex < -50 then
        self:attack()
    end
end