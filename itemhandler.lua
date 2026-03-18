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
        local neoItemsSubarray =  {}
        
        for k,v in self.itemsSubArray do
            neoItemsSubarray[k] = v
        end
        
        for i = toRemove, #self.itemsSubArray-1 do
            neoItemsSubarray[i][1] = self.itemsSubArray[i+1][1]
        end
        
        for k,v in pairs(neoItemsSubarray) do
            self.itemsSubArray[k] = v
        end

    end

end

function ItemHandler:trueRemove() --Removes all used items from self.items based on the logged indices.
    if #self.selected_items > 1 then

        local selectedItemIndices = {}

        for i = 1, #self.selected_items do
            for j = 1, #self.items do
                if self.items[j] == self.selected_items[i] then
                    selectedItemIndices[i] = j
                    break
                end
            end
        end

        table.sort(selectedItemIndices, function (a, b)
            return a > b
        end)

        for i = 1, #selectedItemIndices do
            self.items[selectedItemIndices[i]] = nil
        end

    end
end