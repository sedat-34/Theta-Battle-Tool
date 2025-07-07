--Please note that although this is named "partyMember.lua", this file is an example player file for KRIS
--The project does not support multiple party members.

PartyMember = Object:extend()

function PartyMember:new(name, xpos, ypos, animations, defaultframe, defaultanim, size, maxhp, ATK, DEF)

    self.name = name
    self.xpos = xpos
    self.ypos = ypos
    self.animations = animations
    self.defaultframe = love.graphics.newImage("sprites/"..defaultframe)
    self.defaultanim = defaultanim
    self.size = size
    self.maxhp = maxhp
    self.hp = maxhp
    self.ATK = ATK
    self.DEF = DEF

    self.currentanimation = defaultanim
    self.currentframe = nil
    self.currentframecount = 1

    self.animationframes = {}

    for i = 0,#self.animations do --Load every frame of every animation, index them by number.

        --Adjust offset to match size
        self.animations[i][5] = self.animations[i][5] * self.size
        self.animations[i][6] = self.animations[i][6] * self.size

        self.animationframes[i] = {}

        for j = 1,animations[i][2] do
            self.animationframes[i][j] = love.graphics.newImage("sprites/"..self.animations[i][1].."/"..self.animations[i][1]..j..".png")
        end

    end

    self.animationsfromstate = { --When a string is passed into set_animation(), these are checked to convert into a numerical value
        ["ATTACKUI"] = 6,
        ["ACTUI"] = 7,
        ["ITEMUI"] = 0,
        ["SPAREUI"] = 8,
        ["DEFEND"] = 5,
        ["ATTACK"] = 1,
        
    }

end

function PartyMember:draw()

    if self.animationframes[self.currentanimation][math.floor(self.currentframecount)] and self.currentframe then

        love.graphics.draw(self.currentframe, self.xpos + self.animations[self.currentanimation][5], self.ypos + self.animations[self.currentanimation][6], 0, self.size, self.size)

    else

        --If a frame somehow doesn't exist, this is displayed.
         love.graphics.draw(self.defaultframe, self.xpos, self.ypos, 0, self.size, self.size)

    end

end

function PartyMember:set_animation(currentanimationindex)
    if type(currentanimationindex) == "number" then
        self.currentanimation = currentanimationindex
    else
        self.currentanimation = self.animationsfromstate[currentanimationindex]
    end
        self.currentframecount = 1
end

function PartyMember:animate(dt)

    if self.animations then
        --PartyMember animations not nil, updating frame to display
        self.currentframecount = self.currentframecount+ dt * self.animations[self.currentanimation][3]

        --This part handles looping and unlooping animations.
        if math.floor(self.currentframecount) > self.animations[self.currentanimation][2] then

            if self.animations[self.currentanimation][4] then -- if the animation loops:

                self.currentframecount = 1

            elseif self.currentanimation == 5 then

                self:set_animation(9)

            else

                self.currentanimation = self.defaultanim --You should manually change this within the next update if the default animation is just a fallback
                self.currentframecount = 1

            end

        end

        self.currentframe = self.animationframes[self.currentanimation][math.floor(self.currentframecount)]

    end

end

function PartyMember:attack(local_enemy)
    love.audio.play(SND_ATTACK)
    print(self.name.." attacked "..local_enemy.name)
    local selectedEnemyIndex

    for i = 1, #enemies do
        if enemies[i] == local_enemy then
            selectedEnemyIndex = i
            break
        end
    end

    if selectedEnemyIndex == nil or local_enemy.hp <= 0 then
        local_enemy = nil
        for i = 1, #enemies do
            print(enemies[i].name.." hp is "..enemies[i].hp)
            if enemies[i].hp > 0 then
                local_enemy = enemies[i]
                selectedEnemyIndex = i
            end
        end
    end
    if local_enemy then
        print("Attacked enemy "..selectedEnemyIndex)
        local_enemy:hurt(self.ATK*3)
        self.currentanimation = 1
        self.currentframecount = 1
    else
        print("No enemies left lmao :)")
        current_state = "BATTLEOVER"
    end
end

function PartyMember:act(local_enemy, actname, ui)
    print(self.name.." acted together with "..local_enemy.name)
    print("Current act: "..actname)
    local_enemy.mercyup = local_enemy.mercytable[actname]
    local_enemy:act(actname, ui) --Lets local_enemy handle the act
end

function PartyMember:spare(local_enemy)
    local_enemy:spared()
end