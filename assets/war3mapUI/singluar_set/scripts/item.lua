-- 单位物品
_singluarSetItem = {
    ---@param stage{tooltips:FrameTooltip}
    onSetup = function(kit, stage)

        kit = kit .. '->item'

        stage.item_max = 6

        stage.item = FrameBackdrop(kit, FrameGameUI)
            .relation(FRAME_ALIGN_LEFT_BOTTOM, FrameGameUI, FRAME_ALIGN_BOTTOM, 0.1358, 0)
            .size(0.059, 0.134)

        stage.item_weight = FrameText(kit .. '->weight', stage.item)
            .relation(FRAME_ALIGN_TOP, stage.item, FRAME_ALIGN_TOP, 0, -0.004)
            .textAlign(TEXT_ALIGN_LEFT)
            .fontSize(9)

        stage.item_itWidth = 0.025
        stage.item_itHeight = stage.item_itWidth * 8 / 6
        local itMargin = 0.0022

        stage.item_btn = {}
        stage.item_charges = {}

        local raw = 2
        for i = 1, stage.item_max do
            local xo = 0.003 + (i - 1) % raw * (stage.item_itWidth + itMargin)
            local yo = -0.025 - (math.ceil(i / raw) - 1) * (itMargin + stage.item_itHeight)
            stage.item_btn[i] = FrameButton(kit .. '->btn->' .. i, stage.item)
                .anchor(true)
                .relation(FRAME_ALIGN_LEFT_TOP, stage.item, FRAME_ALIGN_LEFT_TOP, xo, yo)
                .size(stage.item_itWidth, stage.item_itHeight)
                .highlight(true)
                .fontSize(7.5)
                .mask('btn\\mask')
                .show(false)
                .onMouseLeave(function(_) stage.tooltips.show(false, 0.4) end)
                .onMouseEnter(
                function(evtData)
                    if (_singluarSetOnBagSyncFollowIndex[evtData.triggerPlayer.index()] ~= nil) then
                        return
                    end
                    local sel = evtData.triggerPlayer.selection()
                    if (false == isObject(sel, "Unit") or sel.isDestroy()) then
                        return nil
                    end
                    local content = _singluarSetTooltipsBuilder.item(sel.itemSlot().storage()[i], evtData.triggerPlayer)
                    if (content ~= nil) then
                        stage.tooltips
                             .relation(FRAME_ALIGN_BOTTOM, stage.item_btn[i], FRAME_ALIGN_TOP, 0, 0.002)
                             .content(content)
                             .show(true)
                             .onMouseClick(
                            function(ed)
                                stage.tooltips.show(false, 0)
                                local selection = ed.triggerPlayer.selection()
                                if (isObject(selection, "Unit")) then
                                    local it = selection.itemSlot().storage()[i]
                                    if (isObject(it, "Item")) then
                                        if (ed.key == "warehouse") then
                                            selection.itemSlot().remove(it.itemSlotIndex())
                                            ed.triggerPlayer.warehouseSlot().push(it)
                                            local v = Vcm("war3_dropItem")
                                            async.call(ed.triggerPlayer, function()
                                                v.play()
                                            end)
                                        elseif (ed.key == "drop") then
                                            it.drop()
                                        elseif (ed.key == "pawn") then
                                            it.pawn()
                                        elseif (ed.key == "separate") then

                                        end
                                    end
                                end
                            end)
                    end
                end)
                .onMouseClick(
                function(evtData)
                    local selection = evtData.triggerPlayer.selection()
                    if (isObject(selection, "Unit") == false or selection.owner() ~= evtData.triggerPlayer) then
                        return
                    end
                    local pIdx = evtData.triggerPlayer.index()
                    if (_singluarSetOnBagSyncFollowIndex[pIdx] == nil) then
                        -- 引用
                        local it = selection.itemSlot().storage()[i]
                        if (isObject(it, "Item")) then
                            sync.send("SINGLUAR_GAME_SYNC", { pIdx, "item_quote", it.id() })
                        end
                    else
                        -- 丢弃物品在鼠标坐标
                        local mx = japi.MouseRX()
                        local my = japi.MouseRY()
                        if (mx > 0.01 and mx < 0.79 and my > 0.155 and my < 0.56) then
                            sync.send("_singluarSetOnBagSync", { pIdx, "dropItem", japi.DzGetMouseTerrainX(), japi.DzGetMouseTerrainY() })
                        end
                    end
                end)

            -- 物品使用次数
            stage.item_charges[i] = FrameButton(kit .. '->charges->' .. i, stage.item_btn[i].childBorder())
                .relation(FRAME_ALIGN_RIGHT_BOTTOM, stage.item_btn[i], FRAME_ALIGN_RIGHT_BOTTOM, -0.0013, 0.0018)
                .texture('bg\\shadowBlock')
                .fontSize(7)

        end

        --- 注册同步策略
        _singluarSetOnBagSync(stage)

    end,
    onRefresh = function(stage, whichPlayer)
        local tmpData = {
            ---@type Unit
            selection = whichPlayer.selection(),
            show = false,
            btn = {},
            charges = {},
        }
        -- 初始化数据
        for i = 1, stage.item_max do
            tmpData.btn[i] = {}
            tmpData.charges[i] = 0
        end
        if (isObject(tmpData.selection, 'Unit') and tmpData.selection.isAlive()) then
            tmpData.show = true
            --- 负重显示
            if (tmpData.selection.weight() > 0) then
                tmpData.weight = string.format('负重 %0.1f/%0.1fKG', tmpData.selection.weightCur(), tmpData.selection.weight())
            else
                tmpData.weight = '负重无上限'
            end
            --- 物品控制
            local storage = tmpData.selection.itemSlot().storage()
            for i = 1, stage.item_max, 1 do
                ---@type Item
                local it = storage[i]
                if (false == isObject(it, 'Item')) then
                    tmpData.btn[i].show = false
                else
                    tmpData.btn[i].show = true
                    tmpData.btn[i].texture = it.icon()
                    tmpData.btn[i].text = ''
                    tmpData.btn[i].border = 'btn\\border-white'
                    tmpData.btn[i].maskValue = 0
                    tmpData.charges[i] = math.floor(it.charges())
                    local ab = it.ability()
                    if (isObject(ab, "Ability")) then
                        if (ab.coolDown() > 0 and ab.coolDownRemain() > 0) then
                            tmpData.btn[i].maskValue = stage.item_itHeight * ab.coolDownRemain() / ab.coolDown() / stage.item_itHeight
                            tmpData.btn[i].text = math.round(ab.coolDownRemain(), 1)
                        elseif (ab.isProhibiting() == true) then
                            local reason = ab.prohibitReason()
                            tmpData.btn[i].maskValue = 1
                            if (reason == nil) then
                                tmpData.btn[i].text = ''
                            else
                                tmpData.btn[i].border = 'Singluar\\ui\\nil.tga'
                                tmpData.btn[i].text = reason
                            end
                        end
                        if (ab == tmpData.selection.owner().cursor().ability()) then
                            tmpData.btn[i].border = 'btn\\border-gold'
                        end
                    end
                end
            end
        end
        async.call(whichPlayer, function()
            stage.item.show(tmpData.show)
            if (tmpData.show) then
                stage.item_weight.text(tmpData.weight)
                for i = 1, stage.item_max do
                    stage.item_btn[i].texture(tmpData.btn[i].texture)
                    stage.item_btn[i].border(tmpData.btn[i].border)
                    stage.item_btn[i].maskValue(tmpData.btn[i].maskValue)
                    stage.item_btn[i].text(tmpData.btn[i].text)
                    stage.item_btn[i].show(tmpData.btn[i].show)
                    if (tmpData.charges[i] > 0) then
                        local tw = math.max(0.006, string.len(tostring(tmpData.charges[i])) * 0.004)
                        stage.item_charges[i]
                             .size(tw, 0.008)
                             .text(tmpData.charges[i])
                             .show(true)
                    else
                        stage.item_charges[i].show(false)
                    end
                end
            end
        end)
    end,
}