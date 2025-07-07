Soul = Object:extend()

function Soul:new()
    self.image = love.graphics.newImage("sprites/soul.png")
    self.x = 10000
    self.y = 10000
    self.size = 1.5
    
    self.currentmenuposition = 0
end

function Soul:updatePos(delta)
    love.audio.play(SND_MENUMOVE)
    local specialcase = false
    if delta == 1 then
        if self.currentmenuposition + delta > #self.positions then
            self.currentmenuposition = 1
            specialcase = true
        end
    elseif delta == -1 then
        if self.currentmenuposition + delta < 1 then
            self.currentmenuposition = #self.positions
            specialcase = true
        end
    end
    if not specialcase then
        self.currentmenuposition = self.currentmenuposition + delta
    end
end


function Soul:updatePosArray(posarray)
        self.positions = posarray
        self.currentmenuposition = 1
end

function Soul:draw()
    if self.positions and (current_state == "ATTACKUI" or current_state == "ACTUI" or current_state == "ACTSUBSUB" or current_state == "SPAREUI") then
        self.x = self.positions[self.currentmenuposition][2]
        self.y = self.positions[self.currentmenuposition][3]+8
        love.graphics.draw(self.image, self.x, self.y, 0, self.size, self.size)
    end
    if current_state == "BULLETS" then
        love.graphics.draw(self.image, self.x, self.y, 0, self.size, self.size)
    end
end