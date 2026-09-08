ItemManager = Object:extend()

function ItemManager:new(items, itemssubarray)
    self.items = items
    self.tempitem = nil
    self.itemsSubArray = itemssubarray
    self.toUse = {}
    self.tempitemsarray = {} --structure = {item, itemIndex, subArrayLastX, subArrayLastY}
    --tempitemsarray is a stack with the item that had its mid-turn removal most recently at top
end

function ItemManager:addItem(target_member_no, current_party_member)
    self.toUse[#self.toUse+1] = {self.tempitem, target_member_no, current_party_member}
    for i = 1,3 do
        print(self.toUse[#self.toUse][i])
    end

    local itemIndex

    --Find the used item's index
    for i = 1, #self.items do
        if self.items[i] == self.tempitem then itemIndex = i break end
    end

    local tempitemindex = {self.items[itemIndex], itemIndex}
    if self.tempitemsarray[1] then --If the tempitemsarray has any element at all
        table.insert(self.tempitemsarray, 1, tempitemindex)
    else
        self.tempitemsarray[1] = tempitemindex
    end

--Recreate the SubArray and items array as if the removed item (index itemIndex) never existed.
    
    table.remove(self.itemsSubArray, itemIndex)
    table.remove(self.items, itemIndex)
end

function ItemManager:undoAddition()

    local index = table.remove(self.tempitemsarray, 1)

    self.itemsSubArray[#self.itemsSubArray+1] = {}

    for i = #self.itemsSubArray-1, index[2], -1 do
        self.itemsSubArray[i+1][1] = self.itemsSubArray[i][1]
    end
    self.itemsSubArray[index[2]].name = index[1].name

    table.insert(self.items, index[2], index[1])

end

function ItemManager:generateItemText(target_member_no, user_member_no, party_members)
    print("target_member_no"..target_member_no)
    print("user_member_no"..user_member_no)
    if target_member_no == user_member_no then
        return party_members[user_member_no].name.." used "..self.tempitem.name.."!"
    else
        return party_members[user_member_no].name.." used "..self.tempitem.name.." on "..party_members[target_member_no].name.."!"
    end

end

function ItemManager:useItem(battle)
    --Grab item, user and recipient data from self.toUse[1]
    local itemToUse =  self.toUse[1][1]
    local memberToReceive = battle.party_members[self.toUse[1][2]]
    local memberToUse = battle.party_members[self.toUse[1][3]]

    if itemToUse then

        --Animate user to the item use animation
        memberToUse:set_animation("item")

        --Give recipient the appropiate amount of HP
        memberToReceive:hpUp(itemToUse.hp)

    end

    --Remove the used toUse index.
    table.remove(self.toUse, 1)
end