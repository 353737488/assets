--[[
    Singluar debug提示
    Author: hunzsig
]]

if (DEBUGGING) then

    collectgarbage("collect")
    local ram = collectgarbage("count")

    local kit = 'singluar_debug'

    local this = UIKit(kit)

    this.onSetup(function()
        local stage = this.stage()
        stage.main = FrameText(kit, FrameGameUI)
            .relation(FRAME_ALIGN_LEFT, FrameGameUI, FRAME_ALIGN_LEFT, 0.001, 0.05)
            .textAlign(TEXT_ALIGN_LEFT)
            .fontSize(8)

        stage.mark = FrameBackdrop(kit .. "->mark", FrameGameUI)
            .relation(FRAME_ALIGN_CENTER, FrameGameUI, FRAME_ALIGN_CENTER, 0, 0)
            .size(2, 2)
            .alpha(100)
            .texture("ReplaceableTextures\\TeamColor\\TeamColor12.blp")
            .show(false)

        ---@type FrameBackdropTile[]
        stage.line = {}
        local graduation = 0.05
        local texture = "ReplaceableTextures\\TeamColor\\TeamColor04.blp"
        local txtColor = "ffe600"
        for i = 1, math.floor(0.6 / graduation - 0.5), 1 do
            local tile = FrameBackdropTile(kit .. "->horizontal->" .. i, FrameGameUI)
                .relation(FRAME_ALIGN_BOTTOM, FrameGameUI, FRAME_ALIGN_BOTTOM, 0, graduation * i)
                .size(2, 0.001)
                .texture(texture)
                .show(false)
            FrameText(kit .. "->horizontal->txt->" .. i, tile)
                .relation(FRAME_ALIGN_LEFT, tile, FRAME_ALIGN_LEFT, 0.002, 0.01)
                .textAlign(TEXT_ALIGN_LEFT)
                .fontSize(12)
                .text(colour.hex(graduation * i, txtColor))
            table.insert(stage.line, tile)
        end
        for i = 1, math.floor(0.8 / graduation - 0.5), 1 do
            local tile = FrameBackdropTile(kit .. "->vertical->" .. i, FrameGameUI)
                .relation(FRAME_ALIGN_LEFT, FrameGameUI, FRAME_ALIGN_LEFT, graduation * i, 0)
                .size(0.001, 2)
                .texture(texture)
                .show(false)
            FrameText(kit .. "->vertical->txt->" .. i, tile)
                .relation(FRAME_ALIGN_BOTTOM, tile, FRAME_ALIGN_BOTTOM, 0.01, 0.01)
                .textAlign(TEXT_ALIGN_LEFT)
                .fontSize(12)
                .text(colour.hex(graduation * i, txtColor))
            table.insert(stage.line, tile)
        end

        local kbKey = KEYBOARD['Control']

        keyboard.onRelease(kbKey, function(_)
            local s = stage.mark.show()
            stage.mark.show(not s)
            for _, l in ipairs(stage.line) do
                l.show(not s)
            end
        end, "debug")

        local types = { "all", "max" }
        local typesLabel = {
            all = "总共",
            max = "最大值",
            ["+tmr"] = "计时器",
            ["+ply"] = "玩家",
            ["+frc"] = "玩家势力",
            ["+flt"] = "过滤器",
            ["+w3u"] = "单位",
            ["+w3d"] = "可破坏物",
            ["+grp"] = "单位组",
            ["+rct"] = "区域",
            ["+snd"] = "声音",
            ["+que"] = "任务",
            ["+trg"] = "触发器",
            ["+tac"] = "触发器动作",
            ["+EIP"] = "对点特效",
            ["+EIm"] = "附着特效",
            ["+loc"] = "点",
            ["pcvt"] = "玩家聊天事件",
            ["pevt"] = "玩家事件",
            ["uevt"] = "单位事件",
            ["tcnd"] = "触发器条件",
            ["wdvt"] = "可破坏物事件",
            ["+cst"] = "镜头",
            ["+dlg"] = "对话框",
            ["+dlb"] = "对话框按钮",
            ["devt"] = "对话框事件",
        }
        stage.costMax = stage.costMax or 0
        stage.costAvg = stage.costAvg or {}
        stage.debug = function()
            local count = { all = 0, max = JassDebug.handlemax() }
            for i = 1, count.max do
                local h = 0x100000 + i
                local info = JassDebug.handledef(h)
                if (info and info.type) then
                    if (not table.includes(types, info.type)) then
                        table.insert(types, info.type)
                    end
                    if (count[info.type] == nil) then
                        count[info.type] = 0
                    end
                    count.all = count.all + 1
                    count[info.type] = count[info.type] + 1
                end
            end
            local txts = { "  [J句柄]" }
            for _, t in ipairs(types) do
                table.insert(txts, "  " .. (typesLabel[t] or t) .. " : " .. (count[t] or 0))
            end
            table.insert(txts, "|n  [S内核]")
            table.insert(txts, "  漂浮模型 : " .. _ttg_limiter)
            local i = 0
            for _, _ in pairs(time.kernel) do
                i = i + 1
            end
            table.insert(txts, "  计时器 : " .. i)
            local cost = math.round((collectgarbage("count") - ram) / 1024, 2)
            if (stage.costMax < cost) then
                stage.costMax = cost
            end
            local avg = 0
            if (#stage.costAvg < 100) then
                table.insert(stage.costAvg, cost)
                avg = table.average(stage.costAvg)
            else
                avg = table.average(stage.costAvg)
                stage.costAvg = { avg }
            end
            avg = math.round(avg, 2)
            table.insert(txts, "|n  [内存占用]")
            table.insert(txts, colour.greenLight("  平均 : " .. avg .. ' MB'))
            table.insert(txts, colour.redLight("  最大 : " .. stage.costMax .. ' MB'))
            table.insert(txts, colour.gold("  当前 : " .. cost .. ' MB'))
            return txts
        end

    end)

    this.onRefresh(1, function()
        ---@type {main:FrameText,debug:fun():table<number,number>}
        local stage = this.stage()
        for _, p in ipairs(Players(table.section(1, 12))) do
            if (p.isPlaying() and p.isComputer() == false) then
                local s = string.implode('|n', stage.debug())
                async.call(p, function()
                    stage.main.text(s)
                end)
            end
        end
    end)

end