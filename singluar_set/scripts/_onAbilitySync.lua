-- 右键 - 技能 - 事件管理
_singluarSetOnAbilitySyncInit = false
_singluarSetOnAbilitySyncFollowIndex = {}
_singluarSetOnAbilitySync = function(stage)
    if (_singluarSetOnAbilitySyncInit == false) then
        _singluarSetOnAbilitySyncInit = true
        local followIndex = _singluarSetOnAbilitySyncFollowIndex
        local followTimer = {}
        local vcmClick1 = Vcm('war3_click1')
        local frameMax = stage.ability_max
        ---@type FrameBackdrop[]
        local frameBedding = stage.ability_bedding
        ---@type FrameButton[]
        local frameButton = stage.ability_btn
        Game().onSync("_singluarSetOnAbilitySync", function(syncData)
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
            if (command == "drop") then
                local f = frameButton[followIndex[pIdx]]
                local alpha = f.alpha()
                Async.call(syncPlayer, function()
                    japi.DzFrameSetPoint(f.frameId(), FRAME_ALIGN_CENTER, frameBedding[followIndex[pIdx]].frameId(), FRAME_ALIGN_CENTER, 0, 0)
                    japi.DzFrameSetAlpha(f.frameId(), alpha)
                end)
                followIndex[pIdx] = nil
            elseif (command == "change") then
                local idx = tonumber(syncData.transferData[3])
                local selection = syncPlayer.selection()
                local ab = selection.abilitySlot().storage()[followIndex[pIdx]]
                if (selection == nil or selection.isDead()
                    or selection.owner() ~= syncPlayer
                    or isObject(ab, "Ability") == false
                    or isObject(syncPlayer.cursor().ability(), "Ability")) then
                    return
                end
                Async.call(syncPlayer, function()
                    vcmClick1.play()
                end)
                local f = frameButton[followIndex[pIdx]]
                local alpha = f.alpha()
                Async.call(syncPlayer, function()
                    japi.DzFrameSetPoint(f.frameId(), FRAME_ALIGN_CENTER, frameBedding[followIndex[pIdx]].frameId(), FRAME_ALIGN_CENTER, 0, 0)
                    japi.DzFrameSetAlpha(f.frameId(), alpha)
                end)
                followTimer[pIdx] = nil
                followIndex[pIdx] = nil
                selection.abilitySlot().push(ab, idx)
            elseif (command == "follow") then
                local idx = tonumber(syncData.transferData[3])
                local frame = frameButton[idx]
                japi.DzFrameSetAlpha(frame.frameId(), 0.6 * (frame.alpha() or 255))
                followIndex[pIdx] = idx
                Async.call(syncPlayer, function()
                    stage.tooltips.show(false, 0)
                    vcmClick1.play()
                end)
                followTimer[pIdx] = time.setInterval(0.05, function(curTimer)
                    local selection = syncPlayer.selection()
                    local ab = selection.abilitySlot().storage()[followIndex[pIdx]]
                    if (selection == nil or selection.isDead() or selection.owner() ~= syncPlayer or isObject(ab, "Ability") == false or isObject(syncPlayer.cursor().ability(), "Ability")) then
                        curTimer.destroy()
                        local f = frameButton[followIndex[pIdx]]
                        local alpha = f.alpha()
                        followTimer[pIdx] = nil
                        Async.call(syncPlayer, function()
                            japi.DzFrameSetPoint(f.frameId(), FRAME_ALIGN_CENTER, frameBedding[followIndex[pIdx]].frameId(), FRAME_ALIGN_CENTER, 0, 0)
                            japi.DzFrameSetAlpha(f.frameId(), alpha)
                        end)
                        followIndex[pIdx] = nil
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
                        japi.DzFrameSetPoint(frame.frameId(), FRAME_ALIGN_CENTER, FrameGameUI.frameId(), FRAME_ALIGN_LEFT_BOTTOM, mx, my)
                    end)
                end)
            end
        end)
        Game().onMouseRightClick(function(evtData)
            local triggerPlayer = evtData.triggerPlayer
            local pIdx = triggerPlayer.index()
            local selection = triggerPlayer.selection()
            if (selection ~= nil and selection.isAlive()) then
                local judge = isObject(selection, 'Unit') and selection.owner() == triggerPlayer
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
                                if (followIndex[pIdx] ~= nil) then
                                    if (followIndex[pIdx] ~= i) then
                                        Game().sync("_singluarSetOnAbilitySync", { triggerPlayer.index(), "change", i })
                                    else
                                        Game().sync("_singluarSetOnAbilitySync", { triggerPlayer.index(), "drop" })
                                    end
                                elseif (isObject(ab, "Ability")) then
                                    Game().sync("_singluarSetOnAbilitySync", { triggerPlayer.index(), "follow", i })
                                end
                                break
                            end
                        end
                        j = i + 1
                    end
                    if (followIndex[pIdx] ~= nil and j > frameMax) then
                        Game().sync("_singluarSetOnAbilitySync", { triggerPlayer.index(), "drop" })
                    end
                end
            end
        end, "singluarSet_onAbilitySync")
    end
end