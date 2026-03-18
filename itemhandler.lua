ItemHandler = Object:extend()

function ItemHandler:new(items, itemsSubArray, ItemsSub)
    self.items = items
    self.itemsSubArray = itemsSubArray
    self.itemsSub = ItemsSub
    self.selected_items = {}
end

function ItemHandler:useItem(itemIndex, targetMember)

    targetMember:useItem(self.items[itemIndex])

end

function ItemHandler:removeItem(itemIndex) --Removes from the SubArray (and due to their link, from the Submenu)

    local toRemove = itemIndex
    local lastItem
    if itemIndex ==  #self.items then lastItem = true else lastItem = false end

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

function ItemHandler:trueRemove() --Removes all used items from self.items based on the logged indices.
    if #self.selected_items > 1 then

        table.sort(self.selected_items)

        for i = 1, #self.selected_items do
            self.items[i] = nil
        end

        for i = #self.selected_items, 1, -1 do
            if self.items[i] == nil then table.remove(self.items, i) end
        end

    end
end