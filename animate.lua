function Animate(object, dt, specialcase)

    if object.animations then
        --PartyMember animations not nil, updating frame to display
        object.currentframecount = object.currentframecount+ dt * object.animations[object.currentanimation][3]

        --This part handles looping and unlooping animations.
        if math.floor(object.currentframecount) > object.animations[object.currentanimation][2] then

            if object.animations[object.currentanimation][4] then -- if the animation loops:

                object.currentframecount = 1

            else

                local isspecialcase = false

                if specialcase then
                    for k, v in pairs(specialcase) do
                        if k == object.currentanimation then
                            object:set_animation(v)
                            isspecialcase = true
                            break
                        end
                    end
                end

                if not isspecialcase then

                    object.currentanimation = object.defaultanim --You should manually change this within the next update if the default animation is just a fallback
                    object.currentframecount = 1

                end
            
            end

        end

        object.currentframe = object.animationframes[object.currentanimation][math.floor(object.currentframecount)]

    end

end