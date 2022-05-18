-- 右键 - 技能 - 事件管理
_singluarSetAbilityOnRight = function(stage)
    local vcmClick1 = Vcm('war3_click1')
    local frameMax = stage.ability_max
    ---@type FrameBackdrop[]
    local frameBedding = stage.ability_bedding
    ---@type FrameButton[]
    local frameButton = stage.ability_btn

    --- 跟踪停止
    local onFollowStop = function(callbackData)
        local fpi = callbackData.followData
        japi.DzFrameSetAlpha(frameButton[fpi].handle(), frameButton[fpi].alpha())
    end
    --- 跟踪回调
    local onFollowChange = function(callbackData, triggerPlayer, i)
        local fab = callbackData.followObj
        if (isObject(fab, "Ability")) then
            sync.send("SINGLUAR_SET_ABILITY_SYNC", { "ability_push", fab.id(), i, callbackData.followData })
            vcmClick1.play()
        end
    end

    sync.receive("SINGLUAR_SET_ABILITY_SYNC", function(syncData)
        local syncPlayer = syncData.syncPlayer
        local command = syncData.transferData[1]
        if (command == "ability_push") then
            local abId = syncData.transferData[2]
            local i = tonumber(syncData.transferData[3])
            local fpi = tonumber(syncData.transferData[4])
            ---@type Ability
            local ab = i2o(abId)
            if (isObject(ab, "Ability")) then
                syncPlayer.selection().abilitySlot().push(ab, i)
            end
            japi.DzFrameSetAlpha(frameButton[fpi].handle(), frameButton[fpi].alpha())
        end
    end)

    mouse.onRightClick(function(evtData)
        local triggerPlayer = evtData.triggerPlayer
        local following = triggerPlayer.cursor().following()
        local followObject = triggerPlayer.cursor().followObject()
        if (following == true and isObject(followObject, "Ability") == false) then
            return
        end
        local selection = triggerPlayer.selection()
        if (selection ~= nil) then
            local judge = isObject(selection, 'Unit') and selection.isAlive() and selection.owner() == triggerPlayer
            if (judge) then
                local j = 0
                for i = 1, frameMax do
                    local ab = selection.abilitySlot().storage()[i]
                    local bed = frameBedding[i]
                    local anchor = bed.anchor()
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
                                if (table.equal(followObject, ab) == false) then
                                    triggerPlayer.cursor().followStop(function(callbackData)
                                        onFollowChange(callbackData, triggerPlayer, i)
                                    end)
                                else
                                    triggerPlayer.cursor().followStop(onFollowStop)
                                end
                            elseif (isObject(ab, "Ability")) then
                                japi.DzFrameSetAlpha(frameButton[i].handle(), 0)
                                stage.tooltips.show(false, 0)
                                vcmClick1.play()
                                triggerPlayer.cursor().followFrame(ab, frameButton[i].texture(), frameButton[i].size(), i, onFollowStop)
                            end
                            break
                        end
                    end
                    j = i + 1
                end
                if (j > frameMax and following == true) then
                    triggerPlayer.cursor().followStop(onFollowStop)
                end
            end
        end
    end, "singluarSet_onAbilityMouseRightClick")
end