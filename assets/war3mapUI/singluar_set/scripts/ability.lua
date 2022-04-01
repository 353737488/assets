-- 单位技能
_singluarSetAbility = {
    ---@param stage{tooltips:FrameTooltip}
    onSetup = function(kit, stage)

        kit = kit .. "->ability"

        stage.ability_max = 8

        stage.ability = FrameBackdrop(kit, FrameGameUI)
            .relation(FRAME_ALIGN_BOTTOM, FrameGameUI, FRAME_ALIGN_BOTTOM, 0, 0)
            .show(false)

        stage.ability_bedding = {}
        stage.ability_btn = {}
        stage.ability_btnLvUp = {}

        for i = 1, stage.ability_max do
            stage.ability_bedding[i] = FrameBackdrop(kit .. '->bedding->' .. i, stage.ability).anchor(true).show(false)
        end
        for i = 1, stage.ability_max do
            stage.ability_btn[i] = FrameButton(kit .. '->btn->' .. i, stage.ability)
                .size(0.1, 0.1)
                .relation(FRAME_ALIGN_CENTER, stage.ability_bedding[i], FRAME_ALIGN_CENTER, 0, 0)
                .highlight(true)
                .hotkeyFontSize(9)
                .fontSize(12)
                .mask('btn\\mask')
                .onMouseLeave(function(_) stage.tooltips.show(false, 0) end)
                .onMouseEnter(
                function(evtData)
                    if (evtData.triggerPlayer.cursor().following()) then
                        return
                    end
                    local selection = evtData.triggerPlayer.selection()
                    if (selection == nil) then
                        return
                    end
                    local content = _singluarSetTooltipsBuilder.ability(selection.abilitySlot().storage()[i], 0)
                    if (content ~= nil) then
                        stage.tooltips
                             .relation(FRAME_ALIGN_BOTTOM, stage.ability_btn[i], FRAME_ALIGN_TOP, 0, 0.002)
                             .content(content)
                             .show(true)
                    end
                end)
                .onMouseClick(
                function(evtData)
                    local selection = evtData.triggerPlayer.selection()
                    if (isObject(selection, "Unit") == false or selection.isInterrupt() or selection.owner() ~= evtData.triggerPlayer) then
                        return
                    end
                    local ab = selection.abilitySlot().storage()[i]
                    if (isObject(ab, "Ability")) then
                        sync.send("SINGLUAR_GAME_SYNC", { evtData.triggerPlayer.index(), "ability_quote", ab.id() })
                    end
                end)
                .show(false)

            stage.ability_btnLvUp[i] = FrameButton(kit .. '->upbtn->' .. i, stage.ability_bedding[i])
                .relation(FRAME_ALIGN_BOTTOM, stage.ability_btn[i], FRAME_ALIGN_TOP, 0, 0)
                .texture('icon\\up')
                .highlight(true)
                .show(false)
                .onMouseLeave(function(_) stage.tooltips.show(false, 0) end)
                .onMouseEnter(
                function(evtData)
                    local selection = evtData.triggerPlayer.selection()
                    if (selection == nil) then
                        return
                    end
                    local content = _singluarSetTooltipsBuilder.ability(selection.abilitySlot().storage()[i], 1)
                    if (content ~= nil) then
                        stage.tooltips
                             .relation(FRAME_ALIGN_BOTTOM, stage.ability_btnLvUp[i], FRAME_ALIGN_TOP, 0, 0.002)
                             .content(content)
                             .show(true)
                    end
                end)
                .onMouseClick(
                function(evtData)
                    local selection = evtData.triggerPlayer.selection()
                    if (isObject(selection, 'Unit') and selection.isAlive() and selection.owner() == evtData.triggerPlayer) then
                        Vcm('war3_click1').play()
                        local ab = selection.abilitySlot().storage()[i]
                        if (isObject(ab, "Ability")) then
                            sync.send("SINGLUAR_GAME_SYNC", { evtData.triggerPlayer.index(), "ability_level_up", ab.id() })
                            local content = _singluarSetTooltipsBuilder.ability(ab, 1)
                            if (content ~= nil) then
                                stage.tooltips.content(content)
                            end
                        end
                    end
                end)
        end
        stage.ability_cover = FrameBackdrop(kit .. '->cover', stage.ability).alpha(0)

        --- 注册同步策略
        _singluarSetAbilityOnRight(stage)
    end,
    onRefresh = function(stage, whichPlayer)
        local tmpData = {
            ---@type Unit
            selection = whichPlayer.selection(),
            race = whichPlayer.race(),
            show = false,
            size = nil,
            bedding = {},
            btn = {},
            btnLvUp = {},
        }
        if (isObject(tmpData.selection, 'Unit') and tmpData.selection.isAlive()) then
            tmpData.show = true
            -- 初始化数据
            for i = 1, stage.ability_max do
                tmpData.bedding[i] = {}
                tmpData.btn[i] = {}
                tmpData.btnLvUp[i] = {}
            end
            --
            local tail = tmpData.selection.abilitySlot().tail()
            local margin = 0.003
            local bagRxMax = 0.034
            local bagRx = bagRxMax
            if (tail > 5) then
                bagRx = 0.168 / tail
            end
            local bagRy = bagRx * (8 / 6)
            local bagRl = (0.186 - bagRx * tail - margin * (tail - 1)) / 2
            local storage = tmpData.selection.abilitySlot().storage()
            tmpData.size = { bagRx, bagRy }
            for i = 1, stage.ability_max do
                if (i > tail) then
                    tmpData.bedding[i].show = false
                    tmpData.btn[i].show = false
                    tmpData.btn[i].maskValue = 0
                else
                    local xOffset = 0.334 + bagRl + (i - 1) * (bagRx + margin)
                    local yOffset = 0.058 + 0.002 * math.max(0, tail - 5)
                    if (storage[i] == nil) then
                        tmpData.btn[i].show = false
                        tmpData.btn[i].maskValue = 0
                        tmpData.btnLvUp[i].show = false
                    else
                        local tt = storage[i].targetType()
                        tmpData.btn[i].texture = storage[i].icon()
                        if (storage[i].coolDown() > 0 and storage[i].coolDownRemain() > 0) then
                            tmpData.btn[i].maskValue = math.round(bagRy * storage[i].coolDownRemain() / storage[i].coolDown(), 3) / bagRy
                            tmpData.btn[i].border = 'Singluar\\ui\\nil.tga'
                            tmpData.btn[i].fontSize = math.round(12 * (bagRx / bagRxMax), 2)
                            tmpData.btn[i].text = math.round(storage[i].coolDownRemain(), 1)
                        elseif (storage[i].isProhibiting() == true) then
                            local reason = storage[i].prohibitReason()
                            tmpData.btn[i].maskValue = 1
                            if (reason == nil) then
                                tmpData.btn[i].border = 'btn\\border-ban'
                                tmpData.btn[i].text = ''
                            else
                                tmpData.btn[i].border = 'Singluar\\ui\\nil.tga'
                                tmpData.btn[i].fontSize = math.round(8 * (bagRx / bagRxMax), 2)
                                tmpData.btn[i].text = reason
                            end
                        else
                            tmpData.btn[i].text = ''
                            if (nil == tt or ABILITY_TARGET_TYPE.PAS == tt) then
                                tmpData.btn[i].border = 'Singluar\\ui\\nil.tga'
                            else
                                if (storage[i] == tmpData.selection.owner().cursor().ability()) then
                                    tmpData.btn[i].border = 'btn\\border-gold'
                                else
                                    tmpData.btn[i].border = 'btn\\border-white'
                                end
                            end
                        end
                        if (nil == tt or ABILITY_TARGET_TYPE.PAS == tt) then
                            tmpData.btn[i].hotkey = ''
                        else
                            tmpData.btn[i].hotkey = Game().abilityHotkey(i)
                        end
                        tmpData.btn[i].show = (nil ~= tt)
                        local lv = storage[i].level()
                        -- next
                        tmpData.btnLvUp[i].show = false
                        if (nil ~= tt and tmpData.selection.abilityPoint() > 0) then
                            if (lv < storage[i].levelMax() and storage[i].levelUpNeedPoint() > 0) then
                                if (storage[i].levelUpNeedPoint() <= tmpData.selection.abilityPoint()) then
                                    tmpData.btnLvUp[i].size = { bagRx * 0.3, bagRy * 0.25 }
                                    tmpData.btnLvUp[i].show = true
                                end
                            end
                        end
                    end
                    tmpData.bedding[i].relation = { xOffset, yOffset }
                    tmpData.bedding[i].show = true
                end
            end
        end
        async.call(whichPlayer, function()
            --- 主
            stage.ability.show(tmpData.show)
            if (tmpData.show) then
                for i = 1, stage.ability_max do
                    if (tmpData.size) then
                        stage.ability_btn[i].size(tmpData.size[1], tmpData.size[2])
                    end
                    stage.ability_btn[i].hotkey(tmpData.btn[i].hotkey)
                    stage.ability_btn[i].texture(tmpData.btn[i].texture)
                    stage.ability_btn[i].show(tmpData.btn[i].show)
                    stage.ability_btn[i].border(tmpData.btn[i].border)
                    stage.ability_btn[i].maskValue(tmpData.btn[i].maskValue)
                    stage.ability_btn[i].fontSize(tmpData.btn[i].fontSize)
                    stage.ability_btn[i].text(tmpData.btn[i].text)
                    if (tmpData.btnLvUp[i].size) then
                        stage.ability_btnLvUp[i].size(tmpData.btnLvUp[i].size[1], tmpData.btnLvUp[i].size[2])
                    end
                    stage.ability_btnLvUp[i].show(tmpData.btnLvUp[i].show)
                    stage.ability_bedding[i].texture('ability\\' .. tmpData.race)
                    if (tmpData.bedding[i].relation) then
                        stage.ability_bedding[i].relation(FRAME_ALIGN_LEFT_BOTTOM, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, tmpData.bedding[i].relation[1], tmpData.bedding[i].relation[2])
                    end
                    if (tmpData.size) then
                        stage.ability_bedding[i].size(tmpData.size[1], tmpData.size[2])
                    end
                    stage.ability_bedding[i].show(tmpData.bedding[i].show)
                end
            end
        end)
    end,
}