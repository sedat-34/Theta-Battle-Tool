ItemHandler = Object:extend()

function ItemHandler:new(items, itemsSubArray)
    self.items = items
    self.itemsSubArray = itemsSubArray
    self.selected_items = {}
end

function ItemHandler:useItem(itemIndex, targetMember)

    targetMember:useItem(self.items[itemIndex])

end

function ItemHandler:removeItem(item)
    
    local toRemove --index of the item to remove from the list
    local lastItem = false

    for i = 1, #self.items do
        if self.items[i] == item then
            toRemove = i
            print(i)
            if toRemove == #self.items then lastItem = true end --if it's the last item the removal is simple.
            print("lastEnemy: "..tostring(lastItem))
        end
    end

    table.remove(self.items, toRemove)

    if lastItem then --The super easy last item removal
        self.itemsSubArray[#self.itemsSubArray] = nil
    else --Removes item from and rebuilds the itemssubarray array as if the removed eitem never existed.
        local neoItemsSubarray = self.itemsSubArray
        for i = toRemove, #self.itemsSubArray-1 do
            neoItemsSubarray[i][1] = self.itemsSubArray[i+1][1]
        end
        self.itemsSubArray = neoItemsSubarray
        self.itemsSubArray[#self.itemsSubArray] = nil
    end

end