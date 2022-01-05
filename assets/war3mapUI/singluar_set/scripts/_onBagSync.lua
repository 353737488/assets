-- 右键 - 背包(物品、仓库) - 事件管理
_singluarSetOnBagSyncInit = false
_singluarSetOnBagSyncFollowIndex = {}
_singluarSetOnBagSync = function(stage)
    if (_singluarSetOnBagSyncInit == false) then
        _singluarSetOnBagSyncInit = true
        local followIndex = _singluarSetOnBagSyncFollowIndex
        local followTimer = {}
        local vcmClick1 = Vcm('war3_click1')
        local itemMax = stage.item_max
        local warehouseMax = stage.warehouse_max
        ---@type FrameButton[]
        local frameItems = stage.item_btn
        ---@type FrameButton[]
        local frameWarehouse = stage.warehouse_btn
        Game().onSync("_singluarSetOnBagSync", function(syncData)
            if (syncData.syncPlayer.index() ~= tonumber(syncData.transferData[1])) then
                return
            end
            local syncPlayer = syncData.syncPlayer
            local pIdx = syncPlayer.index()
            local command = syncData.transferData[2]
            if (isObject(followTimer[pIdx], "Timer")) then
                followTimer[pIdx].destroy()
                followTimer[pIdx] = nil
            end
            local cancel = function()
                local f
                if (followIndex[pIdx] <= itemMax) then
                    f = frameItems[followIndex[pIdx]]
                else
                    f = frameWarehouse[followIndex[pIdx] - itemMax]
                end
                local relation = f.relation()
                local alpha = f.alpha()
                Async.call(syncPlayer, function()
                    japi.DzFrameSetPoint(f.handle(), relation[1], relation[2].handle(), relation[3], relation[4], relation[5])
                    japi.DzFrameSetAlpha(f.handle(), alpha)
                end)
                followIndex[pIdx] = nil
                followTimer[pIdx] = nil
            end
            if (command == "drop") then
                cancel()
            elseif (command == "menu") then
                cancel()
            elseif (command == "change") then
                local idx = tonumber(syncData.transferData[3])
                local selection = syncPlayer.selection()
                ---@type Item
                local it
                if (followIndex[pIdx] <= itemMax) then
                    if (selection == nil or selection.isDead() or selection.owner() ~= syncPlayer) then
                        return
                    end
                    it = selection.itemSlot().storage()[followIndex[pIdx]]
                else
                    it = syncPlayer.warehouseSlot().storage()[followIndex[pIdx] - itemMax]
                end
                if (isObject(it, "Item") == false or isObject(syncPlayer.cursor().ability(), "Ability")) then
                    return
                end
                Async.call(syncPlayer, function()
                    vcmClick1.play()
                end)
                local fpi = followIndex[pIdx]
                cancel()
                if (fpi <= itemMax and idx <= itemMax) then
                    -- 物品 -> 物品
                    selection.itemSlot().push(it, idx)
                elseif (fpi > itemMax and idx > itemMax) then
                    -- 仓库 -> 仓库
                    syncPlayer.warehouseSlot().push(it, idx - itemMax)
                elseif (fpi <= itemMax and idx > itemMax) then
                    -- 物品 -> 仓库
                    local iIdx = it.itemSlotIndex()
                    local wIdx = idx - itemMax
                    local wIt = syncPlayer.warehouseSlot().storage()[wIdx]
                    selection.itemSlot().remove(iIdx)
                    if (isObject(wIt, "Item")) then
                        selection.itemSlot().push(wIt, iIdx)
                    end
                    syncPlayer.warehouseSlot().push(it, wIdx)
                elseif (fpi > itemMax and idx <= itemMax) then
                    -- 仓库 -> 物品
                    local wIdx = it.warehouseSlotIndex()
                    local iIt = selection.itemSlot().storage()[idx]
                    syncPlayer.warehouseSlot().remove(wIdx)
                    if (isObject(iIt, "Item")) then
                        syncPlayer.warehouseSlot().push(iIt, wIdx)
                    end
                    selection.itemSlot().push(it, idx)
                end
            elseif (command == "follow") then
                local idx = tonumber(syncData.transferData[3])
                followIndex[pIdx] = idx
                local frame
                if (followIndex[pIdx] <= itemMax) then
                    frame = frameItems[idx]
                else
                    frame = frameWarehouse[idx - itemMax]
                end
                japi.DzFrameSetAlpha(frame.handle(), 0.6 * (frame.alpha() or 255))
                Async.call(syncPlayer, function()
                    stage.tooltips.show(false, 0)
                    vcmClick1.play()
                end)
                followTimer[pIdx] = time.setInterval(0.05, function(curTimer)
                    local selection = syncPlayer.selection()
                    local it
                    local isDrop = false
                    if (followIndex[pIdx] <= itemMax) then
                        it = selection.itemSlot().storage()[followIndex[pIdx]]
                        if (selection == nil or selection.isDead() or selection.owner() ~= syncPlayer or isObject(it, "Item") == false) then
                            isDrop = true
                        end
                    else
                        it = syncPlayer.warehouseSlot().storage()[followIndex[pIdx]]
                    end
                    if (isObject(syncPlayer.cursor().ability(), "Ability")) then
                        isDrop = true
                    end
                    if (isDrop == true) then
                        curTimer.destroy()
                        cancel()
                        return
                    end
                    Async.call(syncPlayer, function()
                        local _se = frame.size()
                        local mx = japi.MouseRX()
                        local my = japi.MouseRY()
                        if (_se ~= nil) then
                            local hw = _se[1] / 2
                            local hh = _se[2] / 2
                            if (mx - hw < 0) then mx = hw end
                            if (mx + hw > 0.8) then mx = 0.8 - hw end
                            if (my - hh < 0) then my = hh end
                            if (my + hh > 0.6) then my = 0.6 - hh end
                        end
                        japi.DzFrameSetPoint(frame.handle(), FRAME_ALIGN_CENTER, FrameGameUI.handle(), FRAME_ALIGN_LEFT_BOTTOM, mx, my)
                    end)
                end)
            elseif (command == "dropItem") then
                local mx = tonumber(syncData.transferData[3])
                local my = tonumber(syncData.transferData[4])
                local fpi = followIndex[pIdx]
                cancel()
                ---@type Item
                local it
                if (fpi <= itemMax) then
                    local selection = syncPlayer.selection()
                    if (selection == nil or selection.isDead() or selection.owner() ~= syncPlayer) then
                        return
                    end
                    it = selection.itemSlot().storage()[fpi]
                else
                    it = syncPlayer.warehouseSlot().storage()[fpi - itemMax]
                end
                local eff
                if (syncPlayer.handle() == JassCommon["GetLocalPlayer"]()) then
                    eff = 'UI\\Feedback\\Confirmation\\Confirmation.mdl'
                else
                    eff = ''
                end
                effect.xy(eff, mx, my, 2 + japi.GetZ(mx, my))
                if (isObject(it, "Item")) then
                    it.drop(mx, my)
                end
            end
        end)
        Game().onMouseRightClick(function(evtData)
            local triggerPlayer = evtData.triggerPlayer
            local pIdx = triggerPlayer.index()
            local selection = triggerPlayer.selection()
            local iCheck = false
            local wCheck = false
            if (selection ~= nil and selection.isAlive()) then
                if (isObject(selection, 'Unit') and selection.owner() == triggerPlayer) then
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
                                if (followIndex[pIdx] ~= nil) then
                                    if (followIndex[pIdx] ~= i) then
                                        Game().sync("_singluarSetOnBagSync", { triggerPlayer.index(), "change", i })
                                    else
                                        Game().sync("_singluarSetOnBagSync", { triggerPlayer.index(), "drop" })
                                    end
                                elseif (isObject(it, "Item")) then
                                    Game().sync("_singluarSetOnBagSync", { triggerPlayer.index(), "follow", i })
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
                        if (followIndex[pIdx] ~= nil) then
                            if ((followIndex[pIdx] - itemMax) ~= i) then
                                Game().sync("_singluarSetOnBagSync", { triggerPlayer.index(), "change", i + itemMax })
                            else
                                Game().sync("_singluarSetOnBagSync", { triggerPlayer.index(), "drop" })
                            end
                        elseif (isObject(it, "Item")) then
                            Game().sync("_singluarSetOnBagSync", { triggerPlayer.index(), "follow", i + itemMax })
                        end
                        wCheck = true
                        break
                    end
                end
            end
            if (followIndex[pIdx] ~= nil and iCheck == false and wCheck == false) then
                Game().sync("_singluarSetOnBagSync", { triggerPlayer.index(), "drop" })
            end
        end, "singluarSet_onBagSync")
    end
end