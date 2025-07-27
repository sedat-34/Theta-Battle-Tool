Battlebox = Object:extend()

function Battlebox:new()
   self.animations = {}

   self.animations["opening"] = {}

       for i = 1, 17 do
            self.animations["opening"][i] = love.graphics.newImage("sprites/battlebox/BBS_00"..i..".png")
       end

    self.animations["still"] = {
        [1] = love.graphics.newImage("sprites/battlebox/BBS_0017.png")
    }

    self.currentanimation = "opening"
    self.currentframecount = 1

    self.currentframe = love.graphics.newImage("sprtes/battlebox/BBS_0001.png")
end

function Battlebox:draw()
    love.graphics.draw(self.currentframe, 0, 0)
end

function Battlebox:setAnimation()
    
end

function Battlebox:animate(dt)
    self.currentframecount = self.currentframecount + dt*15
    local floo
end