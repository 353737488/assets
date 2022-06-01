-- 右键 - 背包(物品、仓库) - 事件管理
_singluarSetItemOnRight = function(stage)
    local vcmClick1 = Vcm('war3_click1')
    local itemMax = stage.item_max
    local warehouseMax = stage.warehouse_max
    ---@type FrameButton[]
    local frameItems = stage.item_btn
    ---@type FrameButton[]
    local frameWarehouse = stage.warehouse_btn

    --- 跟踪停止
    local onFollowStop = function(callbackData)
        local fpi = callbackData.followData
        if (fpi <= itemMax) then
            japi.DzFrameSetAlpha(frameItems[fpi].handle(), frameItems[fpi].alpha())
        else
            japi.DzFrameSetAlpha(frameWarehouse[fpi - itemMax].handle(), frameWarehouse[fpi - itemMax].alpha())
        end
    end
    --- 跟踪回调
    local onFollowChange = function(callbackData, triggerPlayer, i)
        local fpi = callbackData.followData
        local fit = callbackData.followObj
        if (fpi <= itemMax and i <= itemMax) then
            -- 物品 -> 物品
            sync.send("SINGLUAR_SET_ITEM_SYNC", { "item_push", fit.id(), i, fpi })
            vcmClick1.play()
        elseif (fpi > itemMax and i > itemMax) then
            -- 仓库 -> 仓库
            sync.send("SINGLUAR_SET_ITEM_SYNC", { "warehouse_push", fit.id(), i - itemMax, fpi - itemMax })
            vcmClick1.play()
        elseif (fpi <= itemMax and i > itemMax) then
            -- 物品 -> 仓库
            sync.send("SINGLUAR_SET_ITEM_SYNC", { "item_to_warehouse", fit.id(), i - itemMax, fpi })
            vcmClick1.play()
        elseif (fpi > itemMax and i <= itemMax) then
            -- 仓库 -> 物品
            sync.send("SINGLUAR_SET_ITEM_SYNC", { "warehouse_to_item", fit.id(), i, fpi - itemMax })
            vcmClick1.play()
        end
    end

    sync.receive("SINGLUAR_SET_ITEM_SYNC", function(syncData)
        local syncPlayer = syncData.syncPlayer
        local command = syncData.transferData[1]
        if (command == "item_push") then
            local itId = syncData.transferData[2]
            local i = tonumber(syncData.transferData[3])
            local fpi = tonumber(syncData.transferData[4])
            ---@type Item
            local it = i2o(itId)
            if (isObject(it, "Item")) then
                syncPlayer.selection().itemSlot().push(it, i)
            end
            japi.DzFrameSetAlpha(frameItems[fpi].handle(), frameItems[fpi].alpha())
        elseif (command == "warehouse_push") then
            local itId = syncData.transferData[2]
            local i = tonumber(syncData.transferData[3])
            local fpi = tonumber(syncData.transferData[4])
            ---@type Item
            local it = i2o(itId)
            if (isObject(it, "Item")) then
                syncPlayer.warehouseSlot().push(it, i)
            end
            japi.DzFrameSetAlpha(frameWarehouse[fpi].handle(), frameWarehouse[fpi].alpha())
        elseif (command == "item_to_warehouse") then
            local itId = syncData.transferData[2]
            local wIdx = tonumber(syncData.transferData[3])
            local fpi = tonumber(syncData.transferData[4])
            ---@type Item
            local it = i2o(itId)
            if (isObject(it, "Item")) then
                local itIdx = it.itemSlotIndex()
                syncPlayer.selection().itemSlot().remove(itIdx)
                local wIt = syncPlayer.warehouseSlot().storage()[wIdx]
                if (isObject(wIt, "Item")) then
                    syncPlayer.warehouseSlot().remove(wIdx)
                    syncPlayer.selection().itemSlot().push(wIt, itIdx)
                end
                syncPlayer.warehouseSlot().push(it, wIdx)
            end
            japi.DzFrameSetAlpha(frameItems[fpi].handle(), frameItems[fpi].alpha())
        elseif (command == "warehouse_to_item") then
            local wItId = syncData.transferData[2]
            local itIdx = tonumber(syncData.transferData[3])
            local fpi = tonumber(syncData.transferData[4])
            ---@type Item
            local wIt = i2o(wItId)
            if (isObject(wIt, "Item")) then
                local wIdx = wIt.warehouseSlotIndex()
                syncPlayer.warehouseSlot().remove(wIdx)
                local it = syncPlayer.selection().itemSlot().storage()[itIdx]
                if (isObject(it, "Item")) then
                    syncPlayer.selection().itemSlot().remove(it, itIdx)
                    syncPlayer.warehouseSlot().push(it, wIdx)
                end
                syncPlayer.selection().itemSlot().push(wIt, itIdx)
            end
            japi.DzFrameSetAlpha(frameWarehouse[fpi].handle(), frameWarehouse[fpi].alpha())
        end
    end)

    mouse.onRightClick("singluarSet_onItemMouseRightClick", function(evtData)
        local triggerPlayer = evtData.triggerPlayer
        local following = Cursor().following()
        local followObj = Cursor().followObj()
        if (following == true and isObject(followObj, "Item") == false) then
            return
        end
        local selection = triggerPlayer.selection()
        local iCheck = false
        local wCheck = false
        if (selection ~= nil) then
            if (isObject(selection, 'Unit') and selection.isAlive() and selection.owner() == triggerPlayer) then
                for i = 1, itemMax do
                    local it = selection.itemSlot().storage()[i]
                    local btn = frameItems[i]
                    local anchor = btn.anchor()
                    if (anchor ~= nil) then
                        local x = anchor[1]
                        local y = anchor[2]
                        local w = anchor[3]
                        local h = anchor[4]
                        local xMin = x - w / 2
                        local xMax = x + w / 2
                        local yMin = y - h / 2
                        local yMax = y + h / 2
                        local rx = japi.MouseRX()
                        local ry = japi.MouseRY()
                        if (rx < xMax and rx > xMin and ry < yMax and ry > yMin) then
                            if (following == true) then
                                if (table.equal(followObj, it) == false) then
                                    Cursor().followStop(function(callbackData)
                                        onFollowChange(callbackData, triggerPlayer, i)
                                    end)
                                else
                                    Cursor().followStop(onFollowStop)
                                end
                            elseif (isObject(it, "Item")) then
                                japi.DzFrameSetAlpha(btn.handle(), 0)
                                stage.tooltips.show(false, 0)
                                vcmClick1.play()
                                Cursor().followCall(it, btn.texture(), btn.size(), i, onFollowStop)
                            end
                            iCheck = true
                            break
                        end
                    end
                end
            end
        end
        for i = 1, warehouseMax do
            local it = triggerPlayer.warehouseSlot().storage()[i]
            local btn = frameWarehouse[i]
            local anchor = btn.anchor()
            if (anchor ~= nil) then
                local x = anchor[1]
                local y = anchor[2]
                local w = anchor[3]
                local h = anchor[4]
                local xMin = x - w / 2
                local xMax = x + w / 2
                local yMin = y - h / 2
                local yMax = y + h / 2
                local rx = japi.MouseRX()
                local ry = japi.MouseRY()
                if (rx < xMax and rx > xMin and ry < yMax and ry > yMin) then
                    if (following == true) then
                        if (table.equal(followObj, it) == false) then
                            Cursor().followStop(function(callbackData)
                                onFollowChange(callbackData, triggerPlayer, itemMax + i)
                            end)
                        else
                            Cursor().followStop(onFollowStop)
                        end
                    elseif (isObject(it, "Item")) then
                        japi.DzFrameSetAlpha(btn.handle(), 0)
                        stage.tooltips.show(false, 0)
                        vcmClick1.play()
                        Cursor().followCall(it, btn.texture(), btn.size(), itemMax + i, onFollowStop)
                    end
                    wCheck = true
                    break
                end
            end
        end
        if (iCheck == false and wCheck == false and following == true) then
            Cursor().followStop(onFollowStop)
        end
    end)

end