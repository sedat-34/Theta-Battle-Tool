Battlebox = Object:extend()

function Battlebox:new()

    self.name = "BATTLEBOX"

    self.animations = {}

    self.animations = {
        [1] = {"opening", 17, 30, false},
        [2] = {"still", 1, 1, true},
        [3] = {"closing", 28, 30, false},
        [4] = {"invisible", 1, 1, true},
   }

    self.animationframes =  {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
   }

    for i = 1, 17 do
        if i >= 10 then
            self.animationframes[1][i] = love.graphics.newImage("sprites/battlebox/BBS_00"..i..".png")
        else
            self.animationframes[1][i] = love.graphics.newImage("sprites/battlebox/BBS_000"..i..".png")
        end
    end

    self.animationframes[2][1] = love.graphics.newImage("sprites/battlebox/BBS_0017.png")

    for i = 1, 28 do
        self.animationframes[3][i] = love.graphics.newImage("sprites/battlebox/BBS_00"..(i+17)..".png")
    end

    self.animationframes[4][1] = love.graphics.newImage("sprites/battlebox/BBS_0046.png")

    self.currentanimation = 4
    self.currentframecount = 1

    self.animationSpecialLoops = {
        [1] = 2,
        [3] = 4,
    }

    self.top = 200
    self.bottom = 483
    self.left = 500
    self.right = 783

end

function Battlebox:draw()
    love.graphics.draw(self.currentframe, 0, 0)
end

function Battlebox:set_animation(animation)

    self.currentanimation = animation
    self.currentframecount = 1

end

function Battlebox:update(dt)

    Animate(self, dt, self.animationSpecialLoops)

end