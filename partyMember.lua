--The project now supports multiple party members!
--TODO: ADD SUPPORT FOR S-ACT and R-ACT

PartyMember = Object:extend()

function PartyMember:new(name, xpos, ypos, animations, defaultframe, defaultanim, animationSpecialLoops, size, maxhp, ATK, DEF)

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
    self.animationSpecialLoops = animationSpecialLoops

    self.currentanimation = defaultanim
    self.currentframe = nil
    self.currentframecount = 1

    self.animationframes = {}

    for i in ipairs(animations) do --Load every frame of every animation, index them by numbers

        --Adjust offset to match size
        self.animations[i][5] = self.animations[i][5] * self.size
        self.animations[i][6] = self.animations[i][6] * self.size

        self.animationframes[i] = {}

        for j = 1,animations[i][2] do
            self.animationframes[i][j] = love.graphics.newImage("sprites/"..self.animations[i][1].."/"..self.animations[i][1]..j..".png")
        end

    end

    self.isdefending = false

    self.animationsfromstate = { --When a string is passed into set_animation(), these are checked to convert into a numerical value
        ["ATTACKUI"] = 6,
        ["ACTUI"] = 7,
        ["ITEMUI"] = 0,
        ["SPAREUI"] = 8,
        ["DEFEND"] = 5,
        ["ATTACK"] = 1,
        
    }

    for k, v in pairs(self.animationSpecialLoops) do
        print (self.name.." special loop "..k.." : "..v)
    end

end

function PartyMember:draw()

    if self.animationframes[self.currentanimation]and self.currentframe then

        love.graphics.draw(self.currentframe, self.xpos + self.animations[self.currentanimation][5], self.ypos + self.animations[self.currentanimation][6], 0, self.size, self.size)

    else

        --If a frame somehow doesn't exist, this is displayed.
         love.graphics.draw(self.defaultframe, self.xpos, self.ypos, 0, self.size, self.size)

    end

end

function PartyMember:set_animation(animation)
    if type(animation) == "number" then
        self.currentanimation = animation
    else
        self.currentanimation = self.animationsfromstate[animation]

        if self.currentanimation == nil then
            self.currentanimation = self.defaultanim
        end

    end
        self.currentframecount = 1
end

function PartyMember:attack(local_enemy, mult)

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
                break
            end
        end
    end

    if local_enemy then
        print(self.name.." attacked enemy "..selectedEnemyIndex)
        local_enemy:hurt(self.ATK*mult)
        self.currentanimation = 1
        self.currentframecount = 1
    else
        print("No enemies left :)")
        current_state = "BATTLEOVER"
    end
end

function PartyMember:update(dt)
    if current_state == "BATTLEUI" and self.isdefending then
        self.isdefending = false
        self:set_animation(0)
    end
    Animate(self, dt, self.animationSpecialLoops)
end

function PartyMember:act(local_enemy, actname, ui)
    print(self.name.." acted together with "..local_enemy.name)
    print("Current act: "..actname)
    self:set_animation(2)
    local_enemy.mercyup = local_enemy.mercytable[actname]
    local_enemy:act(actname, ui) --Lets local_enemy handle the act
end

function PartyMember:useItem(item)
    self.hp = self.hp + item.hp
    self.hpUP = item.hp
    if self.hp > self.maxhp then
        self.hp = self.maxhp
        self.hpUP = "MAX"
    end
    --PLAY HEAL SOUND
    --SHOW HP INCREASE (like the mercyup)
end

function PartyMember:spare(local_enemy)
    local_enemy:spared()
end