_singluarSetController = {
    ---@param stage{tooltips:FrameTooltip}
    onSetup = function(kit, stage)

        kit = kit .. '->ctl'

        -- 设置下方黑边
        japi.DzFrameEditBlackBorders(0, 0.125)

        -- 主背景
        stage.ctl = FrameBackdrop(kit, FrameGameUI)
            .absolut(FRAME_ALIGN_BOTTOM, 0, 0)
            .size(0.8, 0.1541666667)

        stage.ctl_bigBarWidth = 0.186
        stage.ctl_bigBarHeight = 0.016
        stage.ctl_tileX = 0.130
        stage.ctl_tileWidth = 0.060
        stage.ctl_tileHeight = 0.002
        stage.ctl_tileTypes = {
            { 'punish', 'yellow' },
            { 'exp', 'white' },
            { 'period', 'white' },
        }
        stage.ctl_RxMMP = 0.124
        stage.ctl_RxMMPI = 0.012
        stage.ctl_tips = {}

        -- 小地图
        stage.ctl_miniMap = Frame(kit .. '->minimap', japi.DzFrameGetMinimap(), nil)
            .relation(FRAME_ALIGN_LEFT_BOTTOM, stage.ctl, FRAME_ALIGN_LEFT_BOTTOM, 0.005, 0.006)
            .size(stage.ctl_RxMMP * 0.75, stage.ctl_RxMMP)

        --- 小地图按钮
        -----@type table<number,Frame>
        stage.ctl_miniMapBtns = {}
        local offset = {
            { 0.0020, -0.007 },
            { 0.0023, -0.007 - 0.021 },
            { 0.0022, -0.007 - 0.021 - 0.018 },
            { 0.0023, -0.007 - 0.021 - 0.018 - 0.018 },
            { 0.0023, -0.007 - 0.021 - 0.018 - 0.018 - 0.025 },
        }
        for i = 0, 4 do
            stage.ctl_miniMapBtns[i] = Frame(kit .. '->minimap->btn->' .. i, japi.DzFrameGetMinimapButton(i), nil)
                .relation(FRAME_ALIGN_LEFT_TOP, stage.ctl_miniMap, FRAME_ALIGN_RIGHT_TOP, offset[i + 1][1], offset[i + 1][2])
                .size(0.013, 0.013)
        end

        -- 单位头像
        stage.ctl_portrait = Frame(kit .. '->portrait', japi.DzFrameGetPortrait(), nil)
            .relation(FRAME_ALIGN_LEFT_TOP, stage.ctl_miniMap, FRAME_ALIGN_RIGHT_TOP, 0.140, -0.004)
            .size(0.090, 0.120)

        -- 单位头像阴影
        stage.ctl_portraitShadow = FrameBackdrop(kit .. '->portraitShadow', stage.ctl_portrait)
            .relation(FRAME_ALIGN_BOTTOM, stage.ctl_portrait, FRAME_ALIGN_BOTTOM, 0, 0)
            .size(0.090, 0.120)
            .texture('bg\\shadowUnit')

        -- 面板
        local plateTypes = { 'Nil', 'Unit', 'Item' }
        ---@type table<string,FrameBackdropTile[]>
        stage.ctl_plate = {}
        ---@type table<string,FrameButton>
        stage.ctl_info = {}
        --
        stage.ctl_mouseLeave = function(evtData)
            async.call(evtData.triggerPlayer, function()
                stage.tooltips.show(false, 0)
            end)
        end
        stage.ctl_mouseEnter = function(evtData, field)
            ---@type Player
            local triggerPlayer = evtData.triggerPlayer
            local selection = triggerPlayer.selection()
            if (selection == nil) then
                return
            end
            local primary = selection.primary()
            local tips = {}
            local x = -0.01
            local y = -0.01
            if (field == 'portrait') then
                x = 0.067
                y = 0.018
                if (primary ~= nil) then
                    table.insert(tips, colour.gold('主属性: ' .. primary.label))
                    table.insert(tips, colour.redLight('力量: ' .. math.floor(selection.str())))
                    table.insert(tips, colour.greenLight('敏捷: ' .. math.floor(selection.agi())))
                    table.insert(tips, colour.sky('智力: ' .. math.floor(selection.int())))
                else
                    table.insert(tips, '普通作战单位')
                end
                if (selection.exp() > 0) then
                    table.insert(tips, '经验: ' .. selection.exp())
                    table.insert(tips, '等级: ' .. selection.level() .. '/' .. selection.levelMax())
                else
                    table.insert(tips, '等级: ' .. selection.level())
                end
            elseif (field == 'attack') then
                if (false == selection.isAttackAble()) then
                    table.insert(tips, colour.red('无法攻击'))
                else
                    table.insert(tips, '基础攻击: ' .. math.floor(selection.attack()))
                    table.insert(tips, '攻击浮动: ' .. math.floor(selection.attackRipple()))
                    table.insert(tips, '伤害<加成>: ' .. math.round(selection.damageIncrease(), 2) .. '%')
                    table.insert(tips, '攻击吸血: ' .. math.round(selection.hpSuckAttack(), 2) .. '%')
                    table.insert(tips, '技能吸血: ' .. math.round(selection.hpSuckAbility(), 2) .. '%')
                    table.insert(tips, '攻击吸魔: ' .. math.round(selection.mpSuckAttack(), 2) .. '%')
                    table.insert(tips, '技能吸魔: ' .. math.round(selection.mpSuckAbility(), 2) .. '%')
                end
            elseif (field == 'attackSpeed') then
                table.insert(tips, '攻速<加成>: ' .. math.round(selection.attackSpeed(), 2) .. '%')
                table.insert(tips, '攻击范围: ' .. math.floor(selection.attackRange()))
                table.insert(tips, '命中<加成>: ' .. math.round(selection.aim(), 2) .. '%')
            elseif (field == 'attackRange') then
                if (selection.attackRange() < 250) then
                    table.insert(tips, '武器: 近战')
                else
                    if (selection.isRanged() == false) then
                        table.insert(tips, '武器: 极速')
                    elseif (selection.lightning() ~= nil) then
                        local l = selection.lightning()
                        table.insert(tips, '武器: 闪电')
                        if (l.scatter() > 0 and l.radius() > 0) then
                            table.insert(tips, '散射数量: ' .. math.floor(l.scatter()))
                            table.insert(tips, '散射范围: ' .. math.floor(l.radius()))
                        end
                        if (l.focus() > 0) then
                            table.insert(tips, '聚焦数量: ' .. math.floor(l.focus()))
                        end
                    else
                        local m = selection.missile()
                        if (m.homing()) then
                            table.insert(tips, '武器: 远程')
                        else
                            table.insert(tips, '武器: 远程[自动跟踪]')
                        end
                        table.insert(tips, '发射速度: ' .. math.floor(m.speed()))
                        table.insert(tips, '发射加速度: ' .. math.floor(m.acceleration()))
                        table.insert(tips, '发射高度: ' .. math.floor(m.height()))
                        if (m.scatter() > 0 and m.radius() > 0) then
                            table.insert(tips, '散射数量: ' .. math.floor(m.scatter()))
                            table.insert(tips, '散射范围: ' .. math.floor(m.radius()))
                        end
                        if (m.gatlin() > 0) then
                            table.insert(tips, '多段数量: ' .. math.floor(m.gatlin()))
                        end
                        if (m.reflex() > 0) then
                            table.insert(tips, '反弹数量: ' .. math.floor(m.reflex()))
                        end
                    end
                end
                table.insert(tips, '基准频率: ' .. math.round(selection.attackSpaceBase(), 2) .. ' 秒/击')
            elseif (field == 'knocking') then
                table.insert(tips, '暴击<加成>: ' .. math.round(selection.crit(), 2) .. '%')
                table.insert(tips, '暴击<几率>: ' .. math.round(selection.odds("crit"), 2) .. '%')
                table.insert(tips, '暴击<抗性>: ' .. math.round(selection.resistance('crit'), 2) .. '%')
            elseif (field == 'sight') then
                x = 0.02
                table.insert(tips, '白天视野: ' .. selection.sight())
                table.insert(tips, '黑夜视野: ' .. selection.nsight())
            elseif (field == 'defend') then
                x = 0.02
                table.insert(tips, '防御: ' .. selection.defend())
                table.insert(tips, '治疗<加成>: ' .. selection.cure() .. '%')
                table.insert(tips, '减伤<比例>: ' .. selection.hurtReduction() .. '%')
                table.insert(tips, '受伤<加深>: ' .. selection.hurtIncrease() .. '%')
                table.insert(tips, '反伤<几率>: ' .. selection.odds("hurtRebound") .. '%')
                table.insert(tips, '反伤<比例>: ' .. selection.hurtRebound() .. '%')
                table.insert(tips, '僵硬<抗性>: ' .. selection.resistance('punish') .. '%')
                table.insert(tips, '攻击吸血<抗性>: ' .. selection.resistance('hpSuck') .. '%')
                table.insert(tips, '技能吸血<抗性>: ' .. selection.resistance('hpSuckSpell') .. '%')
                table.insert(tips, '攻击吸魔<抗性>: ' .. selection.resistance('mpSuck') .. '%')
                table.insert(tips, '技能吸魔<抗性>: ' .. selection.resistance('mpSuckSpell') .. '%')
            elseif (field == 'move') then
                x = 0.02
                table.insert(tips, '移动速度: ' .. selection.move())
                table.insert(tips, '回避<几率>: ' .. selection.avoid() .. '%')
            end
            if (field == 'portrait') then
                stage.tooltips.relation(FRAME_ALIGN_RIGHT_BOTTOM, stage.ctl_info[field], FRAME_ALIGN_LEFT_BOTTOM, x, y)
                stage.tooltips.content({ tips = tips }).showGradient(true, { duration = 0.1, y = 0.002 })
            else
                stage.tooltips.relation(FRAME_ALIGN_RIGHT_BOTTOM, stage.ctl_info[field], FRAME_ALIGN_LEFT_BOTTOM, x, y)
                stage.tooltips.content({ tips = tips }).showGradient(true, { duration = 0.1, x = -0.001 })
            end
        end
        --
        for _, t in ipairs(plateTypes) do
            local kitP = kit .. '->' .. t
            stage.ctl_plate[t] = FrameBackdropTile(kitP, stage.ctl)
                .relation(FRAME_ALIGN_BOTTOM, stage.ctl, FRAME_ALIGN_BOTTOM, 0, 0)
                .size(0.6, 0.18)
                .show(false)

            if (t == 'Nil') then
                stage.ctl_nilDisplay = FrameText(kitP .. '->description', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_CENTER, stage.ctl_plate[t], FRAME_ALIGN_CENTER, -0.18, -0.03)
                    .textAlign(TEXT_ALIGN_CENTER)
                    .fontSize(10)
            elseif (t == 'Unit') then
                stage.ctl_mp = FrameBar(kitP .. '->mp', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_LEFT_BOTTOM, stage.ctl_plate[t], FRAME_ALIGN_LEFT_BOTTOM, 0.2342, 0.007)
                    .texture('value', 'bar\\blue')
                    .fontSize(LAYOUT_ALIGN_CENTER, 10.5)
                    .fontSize(LAYOUT_ALIGN_RIGHT, 9)
                    .value(0, stage.ctl_bigBarWidth, stage.ctl_bigBarHeight)

                stage.ctl_hp = FrameBar(kitP .. '->hp', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_BOTTOM, stage.ctl_mp, FRAME_ALIGN_TOP, 0, 0.005)
                    .texture('value', 'bar\\green')
                    .fontSize(LAYOUT_ALIGN_CENTER, 10.5)
                    .fontSize(LAYOUT_ALIGN_RIGHT, 9)
                    .value(0, stage.ctl_bigBarWidth, stage.ctl_bigBarHeight)

                -- 大头信息
                stage.ctl_info.portrait = FrameLabel(kitP .. '->info->portrait', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_LEFT_BOTTOM, stage.ctl_portrait, FRAME_ALIGN_LEFT_BOTTOM, 0.005, 0.006)
                    .size(0.080, 0.012)
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_LEFT)
                    .fontSize(10)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'portrait') end)

                -- 7个信息
                local infoMargin = -0.005
                local infoWidthL = 0.061
                local infoWidthR = 0.04
                local infoHeight = 0.014
                local infoAlpha = 220
                local infoFontSize = 10

                -- 攻击
                stage.ctl_info.attack = FrameLabel(kitP .. '->info->attack', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_LEFT_TOP, stage.ctl_plate[t], FRAME_ALIGN_LEFT_TOP, 0.030, -0.068)
                    .size(infoWidthL, infoHeight)
                    .alpha(infoAlpha)
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_LEFT)
                    .fontSize(infoFontSize)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'attack') end)

                -- 攻速
                stage.ctl_info.attackSpeed = FrameLabel(kitP .. '->info->attackSpeed', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_LEFT_TOP, stage.ctl_info.attack, FRAME_ALIGN_LEFT_BOTTOM, 0, infoMargin)
                    .size(infoWidthL, infoHeight)
                    .alpha(infoAlpha)
                    .icon('icon\\attack_speed')
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_LEFT)
                    .fontSize(infoFontSize)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'attackSpeed') end)

                -- 攻击范围
                stage.ctl_info.attackRange = FrameLabel(kitP .. '->info->attackRange', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_LEFT_TOP, stage.ctl_info.attackSpeed, FRAME_ALIGN_LEFT_BOTTOM, 0, infoMargin)
                    .size(infoWidthL, infoHeight)
                    .alpha(infoAlpha)
                    .icon('icon\\attack_range')
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_LEFT)
                    .fontSize(infoFontSize)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'attackRange') end)

                -- 暴击
                stage.ctl_info.knocking = FrameLabel(kitP .. '->info->knocking', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_LEFT_TOP, stage.ctl_info.attackRange, FRAME_ALIGN_LEFT_BOTTOM, 0, infoMargin)
                    .size(infoWidthL, infoHeight)
                    .alpha(infoAlpha)
                    .icon('icon\\knocking')
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_LEFT)
                    .fontSize(infoFontSize)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'knocking') end)

                -- 视野
                stage.ctl_info.sight = FrameLabel(kitP .. '->info->sight', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_LEFT, stage.ctl_info.attackSpeed, FRAME_ALIGN_RIGHT, 0, 0)
                    .size(infoWidthR, infoHeight)
                    .side(LAYOUT_ALIGN_RIGHT)
                    .alpha(infoAlpha)
                    .icon('icon\\sight')
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_RIGHT)
                    .fontSize(infoFontSize)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'sight') end)

                -- 防御
                stage.ctl_info.defend = FrameLabel(kitP .. '->info->defend', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_RIGHT_TOP, stage.ctl_info.sight, FRAME_ALIGN_RIGHT_BOTTOM, 0, infoMargin)
                    .size(infoWidthR, infoHeight)
                    .side(LAYOUT_ALIGN_RIGHT)
                    .alpha(infoAlpha)
                    .icon('icon\\defend')
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_RIGHT)
                    .fontSize(infoFontSize)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'defend') end)

                -- 移动
                stage.ctl_info.move = FrameLabel(kitP .. '->info->move', stage.ctl_plate[t])
                    .relation(FRAME_ALIGN_RIGHT_TOP, stage.ctl_info.defend, FRAME_ALIGN_RIGHT_BOTTOM, 0, infoMargin)
                    .size(infoWidthR, infoHeight)
                    .side(LAYOUT_ALIGN_RIGHT)
                    .alpha(infoAlpha)
                    .icon('icon\\move')
                    .highlight(true)
                    .textAlign(TEXT_ALIGN_RIGHT)
                    .fontSize(infoFontSize)
                    .onMouseLeave(stage.ctl_mouseLeave)
                    .onMouseEnter(function(evtData) stage.ctl_mouseEnter(evtData, 'move') end)

                -- 小值条条
                stage.ctl_tile = {}
                for _, tb in ipairs(stage.ctl_tileTypes) do
                    stage.ctl_tile[tb[1]] = FrameBar(kitP .. '->tile->' .. tb[1], stage.ctl_plate[t])
                        .relation(FRAME_ALIGN_RIGHT_BOTTOM, stage.ctl_plate[t], FRAME_ALIGN_LEFT_BOTTOM, 0, 0)
                        .texture('value', 'tile\\' .. tb[2])
                        .fontSize(LAYOUT_ALIGN_RIGHT_TOP, 7.5)
                        .value(0, stage.ctl_tileWidth, stage.ctl_tileHeight)
                end
            elseif (t == 'Item') then

            end
        end
    end,
    onRefresh = function(stage, whichPlayer)
        local tmpData = {
            class = 'Nil',
            selection = whichPlayer.selection(),
            race = whichPlayer.race(),
        }
        if (isObject(tmpData.selection, "Unit")) then
            tmpData.class = "Unit"
        elseif (isObject(tmpData.selection, "Item")) then
            tmpData.class = "Item"
        end
        if (tmpData.class == "Nil") then
            tmpData.nilDisplay = string.implode("|n", table.merge({ Game().name() }, Game().prop("infoIntro")))
        elseif (tmpData.class == "Unit") then
            if (tmpData.selection.isDead()) then
                whichPlayer.prop("selection", NIL)
                return
            end
            local primary = tmpData.selection.primary()
            tmpData.nilDisplay = ""
            tmpData.knocking = math.round(tmpData.selection.crit(), 2) .. '%'
            tmpData.sight = math.floor(tmpData.selection.sight())
            tmpData.defend = math.floor(tmpData.selection.defend())
            tmpData.move = math.floor(tmpData.selection.move())
            if (time.isNight()) then
                tmpData.sight = math.floor(tmpData.selection.nsight())
            else
                tmpData.sight = math.floor(tmpData.selection.sight())
            end
            tmpData.portraitTexture = 'icon\\common'
            if (tmpData.selection.isMelee()) then
                tmpData.attackTexture = 'icon\\attack_melee'
                if (primary ~= nil) then
                    tmpData.portraitTexture = 'icon\\' .. primary.value .. '_melee'
                end
            elseif (tmpData.selection.isRanged()) then
                if (tmpData.selection.lightning() ~= nil) then
                    tmpData.attackTexture = 'icon\\attack_lighting'
                else
                    tmpData.attackTexture = 'icon\\attack_ranged'
                end
                if (primary ~= nil) then
                    tmpData.portraitTexture = 'icon\\' .. primary.value .. '_ranged'
                end
            end
            if (tmpData.selection.properName() ~= nil and tmpData.selection.properName() ~= '') then
                tmpData.properName = tmpData.selection.name() .. '·' .. tmpData.selection.properName()
            else
                tmpData.properName = tmpData.selection.name()
            end
            if (tmpData.selection.isAttackAble()) then
                tmpData.attackAlpha = 255
                if (tmpData.selection.attackRipple() == 0) then
                    tmpData.attack = math.floor(tmpData.selection.attack())
                else
                    tmpData.attack = math.floor(tmpData.selection.attack()) .. '~' .. math.floor(tmpData.selection.attack() + tmpData.selection.attackRipple())
                end
                tmpData.attackSpeed = math.round(tmpData.selection.attackSpace(), 2) .. ' 秒/击'
                tmpData.attackRange = math.floor(tmpData.selection.attackRange())
            else
                tmpData.attackAlpha = 150
                tmpData.attack = ' - '
                tmpData.attackSpeed = ' - '
                tmpData.attackRange = ' - '
            end
            if (tmpData.selection.isInvulnerable()) then
                tmpData.defendTexture = 'icon\\defend_gold'
                tmpData.defend = colour.gold('无敌')
            else
                tmpData.defendTexture = 'icon\\defend'
                if (tmpData.selection.defend() <= 9999) then
                    tmpData.defend = math.floor(tmpData.selection.defend())
                else
                    tmpData.defend = math.numberFormat(tmpData.selection.defend(), 2)
                end
            end

            local hpCur = math.floor(tmpData.selection.hpCur())
            local hp = math.floor(tmpData.selection.hp() or 0)
            local hpRegen = math.round(tmpData.selection.hpRegen(), 2)
            if (hpRegen == 0 or hp == 0 or hpCur >= hp) then
                tmpData.hpRegen = ''
            elseif (hpRegen > 0) then
                tmpData.hpRegen = colour.green('+' .. hpRegen)
            elseif (hpRegen < 0) then
                tmpData.hpRegen = colour.red(hpRegen)
            end
            tmpData.hpPercent = math.round(hpCur / hp, 3)
            tmpData.hpTxt = hpCur .. ' / ' .. hp
            if (hpCur < hp * 0.35) then
                tmpData.hpTexture = 'bar\\red'
            elseif (hpCur < hp * 0.65) then
                tmpData.hpTexture = 'bar\\orange'
            else
                tmpData.hpTexture = 'bar\\green'
            end
            local mpCur = math.floor(tmpData.selection.mpCur())
            local mp = math.floor(tmpData.selection.mp() or 0)
            local mpRegen = math.round(tmpData.selection.mpRegen(), 2)
            if (mpRegen == 0 or mp == 0 or mpCur >= mp) then
                tmpData.mpRegen = ''
            elseif (mpRegen > 0) then
                tmpData.mpRegen = colour.skyLight('+' .. mpRegen)
            elseif (mpRegen < 0) then
                tmpData.mpRegen = colour.red(mpRegen)
            end
            if (mp == 0) then
                tmpData.mpPercent = 1
                tmpData.mpTxt = colour.grey(mpCur .. '/' .. mp)
                tmpData.mpTexture = 'bar\\blueGrey'
            else
                tmpData.mpPercent = math.round(mpCur / mp, 3)
                tmpData.mpTxt = mpCur .. '/' .. mp
                tmpData.mpTexture = 'bar\\blue'
            end

            local tileValueCount = 0
            local period = tmpData.selection.period()
            if (period > 0) then
                tileValueCount = tileValueCount + 1
                local cur = tmpData.selection.periodRemain() or 0
                tmpData.periodPercent = math.round(cur / period, 3)
                tmpData.periodTxt = colour.white('存在 ' .. math.round(cur, 1) .. ' 秒')
            end
            local level = tmpData.selection.level()
            if (level > 0) then
                tileValueCount = tileValueCount + 1
                local cur = tmpData.selection.exp() or 0
                local prev = tmpData.selection.expNeed(level) or 0
                local need = tmpData.selection.expNeed() or 0
                tmpData.expPercent = math.round((cur - prev) / (need - prev), 3)
                tmpData.expTxt = colour.white(math.integerFormat(cur) .. '/' .. math.integerFormat(need) .. '  ' .. level .. ' 级')
            end
            local punish = tmpData.selection.punish() or 0
            if (punish > 0) then
                tileValueCount = tileValueCount + 1
                local cur = tmpData.selection.punishCur() or 0
                local max = tmpData.selection.punish() or 0
                tmpData.punishPercent = math.round(cur / max, 3)
                if (tmpData.selection.isPunishing()) then
                    tmpData.punishTxt = colour.red(math.integerFormat(cur) .. '/' .. math.integerFormat(max) .. '  僵住')
                else
                    tmpData.punishTxt = colour.hex(math.integerFormat(cur) .. '/' .. math.integerFormat(max) .. '  硬直', 'DDC10C')
                end
            end
        elseif (tmpData.class == "Item") then
            if (tmpData.selection.instance() == false) then
                whichPlayer.prop("selection", NIL)
                return
            end
            tmpData.nilDisplay = ""
        end
        async.call(whichPlayer, function()
            if (tmpData.class == "Nil") then
                stage.ctl_nilDisplay.text(tmpData.nilDisplay)
                stage.ctl_plate.Unit.show(false)
                stage.ctl_plate.Item.show(false)
                stage.ctl_plate.Nil.show(true)
            elseif (tmpData.class == "Unit") then
                stage.ctl_hp
                     .texture('value', tmpData.hpTexture)
                     .value(tmpData.hpPercent, stage.ctl_bigBarWidth, stage.ctl_bigBarHeight)
                     .text(LAYOUT_ALIGN_CENTER, tmpData.hpTxt)
                     .text(LAYOUT_ALIGN_RIGHT, tmpData.hpRegen)
                stage.ctl_mp
                     .texture('value', tmpData.mpTexture)
                     .value(tmpData.mpPercent, stage.ctl_bigBarWidth, stage.ctl_bigBarHeight)
                     .text(LAYOUT_ALIGN_CENTER, tmpData.mpTxt)
                     .text(LAYOUT_ALIGN_RIGHT, tmpData.mpRegen)
                stage.ctl_info.portrait
                     .icon(tmpData.portraitTexture)
                     .text(tmpData.properName)
                stage.ctl_info.attack
                     .icon(tmpData.attackTexture)
                     .text(tmpData.attack)
                     .alpha(tmpData.attackAlpha)
                stage.ctl_info.attackSpeed
                     .text(tmpData.attackSpeed)
                     .alpha(tmpData.attackAlpha)
                stage.ctl_info.attackRange
                     .text(tmpData.attackRange)
                     .alpha(tmpData.attackAlpha)
                stage.ctl_info.knocking.text(tmpData.knocking)
                stage.ctl_info.sight.text(tmpData.sight)
                stage.ctl_info.defend
                     .icon(tmpData.defendTexture)
                     .text(tmpData.defend)
                stage.ctl_info.move.text(tmpData.move)
                --
                local tileIdx = 0
                for _, tb in ipairs(stage.ctl_tileTypes) do
                    if (tmpData[tb[1] .. 'Percent'] and tmpData[tb[1] .. 'Txt']) then
                        stage.ctl_tile[tb[1]]
                             .relation(FRAME_ALIGN_RIGHT_BOTTOM, stage.ctl_plate.Unit, FRAME_ALIGN_LEFT_BOTTOM, stage.ctl_tileX, 0.006 + tileIdx * 0.017)
                             .value(tmpData[tb[1] .. 'Percent'], stage.ctl_tileWidth, stage.ctl_tileHeight)
                             .text(LAYOUT_ALIGN_RIGHT_TOP, tmpData[tb[1] .. 'Txt'])
                             .show(true)
                        tileIdx = tileIdx + 1
                    else
                        stage.ctl_tile[tb[1]].show(false)
                    end
                end
                stage.ctl_plate.Nil.show(false)
                stage.ctl_plate.Item.show(false)
                stage.ctl_plate.Unit.show(true)
            elseif (tmpData.class == "Item") then
                stage.ctl_plate.Nil.show(false)
                stage.ctl_plate.Unit.show(false)
                stage.ctl_plate.Item.show(true)
            end
        end)
    end,
}