Itemhandler = Object:extend()

function Itemhandler:new(items)
    self.items = items
end

function Itemhandler:useItem(itemIndex, targetMember)

    targetMember:useItem(self.items[itemIndex])

    --Reskinned code from Mizzle... Thanks past me :)

    local lastItem = false
    if itemIndex == #self.items then lastItem = true end --if it's the last item the removal is simple.
    print("lastEnemy: "..tostring(lastItem))

    table.remove(self.items, itemIndex)

    if lastItem then --The super easy last item removal
        self.items[#self.items] = nil
    else --Removes item from and rebuilds the self.items array as if the removed item never existed.
        local neoItems = self.items
        for i = itemIndex, #self.items-1 do
            neoItems[i][1] = Enemysubarray[i+1][1]
        end
        self.items = neoItems
        self.items[#self.items] = nil
    end

end