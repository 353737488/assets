-- 单位BUFF指引
_singluarSetBuff = {
    onSetup = function(kit, stage)

        kit = kit .. '->buff'

        stage.buff_max = 11 * 2 --最大buff数,偶数
        -- buff名词转接
        stage.buff_turner = {}
        stage.buff_turner._name = {
            rgba = "偏色",
            invulnerable = "无敌",
            invisible = "隐身",
            animateScale = "动作",
            --
            crit = "暴击",
            split = "分裂",
            stun = "眩晕",
            freeze = "冻结",
            silent = "沉默",
            unArm = "缴械",
            fetter = "定身",
            lightningChain = "闪电链",
            crackFly = "击飞",
            --
            reborn = "复活时间",
            hp = "生命",
            hpRegen = "生命恢复",
            hpSuckAttack = "攻击吸血",
            hpSuckAbility = "技能吸血",
            mp = "魔法",
            mpRegen = "魔法恢复",
            mpSuckAttack = "攻击吸魔",
            mpSuckAbility = "技能吸魔",
            move = "移动",
            defend = "防御",
            attackSpeed = "攻速",
            attackSpace = "攻击间隔",
            attackSpaceBase = "攻击间隔",
            attack = "攻击",
            attackRange = "攻击范围",
            attackRangeAcquire = "主动攻击范围",
            sight = "视野范围",
            str = "力量",
            agi = "敏捷",
            int = "智力",
            cure = "治疗<加成>", --(%)
            avoid = "回避",
            aim = "命中",
            punish = "硬直",
            punishRegen = "硬直<恢复>",
            weight = "负重",
            hurtIncrease = "受伤<加深>", --(%)
            hurtReduction = "减伤", --(%)
            hurtRebound = "反弹伤害", --(%)
            damageIncrease = "伤害<增幅>", --(%)
            hpCur = "<当前>生命",
            mpCur = "<当前>魔法",
            punishCur = "<当前>硬直",
            weightCur = "<当前>负重",
        }
        -- 图标转接
        stage.buff_turner._icon = {
            attackSpaceBase = "attackSpace",
            attackRangeAcquire = "attackRange",
        }
        enchant.types.forEach(function(key, value)
            stage.buff_turner._name["e_" .. key] = value.label .. '<强化>'
            stage.buff_turner._name["<WEAPON>e_" .. key] = value.label .. '<附武>'
            stage.buff_turner._name["<APPEND>e_" .. key] = value.label .. '<附着>'
            stage.buff_turner._icon["<WEAPON>e_" .. key] = "e_" .. key
            stage.buff_turner._icon["<APPEND>e_" .. key] = "e_" .. key
        end)
        for _, v in ipairs(ATTR_ODDS) do
            stage.buff_turner._name["<ODDS>" .. v] = stage.buff_turner._name[v] .. '<几率>'
            stage.buff_turner._icon["<ODDS>" .. v] = v
        end
        for _, v in ipairs(ATTR_RESISTANCE) do
            stage.buff_turner._name["<ODDS>" .. v] = stage.buff_turner._name[v] .. '<抗性>'
            stage.buff_turner._icon["<RESISTANCE>" .. v] = v
        end
        -- 名字
        stage.buff_turner.name = function(buffName)
            return stage.buff_turner._name[buffName] or buffName
        end
        -- 图标
        stage.buff_turner.icon = function(buffName)
            if (buffName) then
                if (stage.buff_turner._icon[buffName] ~= nil) then
                    return "buff\\" .. stage.buff_turner._icon[buffName]
                else
                    return "buff\\" .. buffName
                end
            end
            return "Singluar\\ui\\default.tga"
        end

        stage.buff_bagRx = 0.016
        stage.buff_bagRy = stage.buff_bagRx * (8 / 6)
        stage.buff_margin = 0
        stage.buff_offsetX = 0.134
        stage.buff_offsetY = 0.134
        stage.buff_buffs = {}
        stage.buff_buffSignal = {}
        stage.buff_catches = {}

        stage.buff = FrameBackdrop(kit, FrameGameUI)
            .relation(FRAME_ALIGN_LEFT_BOTTOM, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, stage.buff_offsetX, stage.buff_offsetY)
            .size(0.2, 0.1)
        for i = 1, stage.buff_max do
            local x = (stage.buff_bagRx + stage.buff_margin) * (i - 1)
            local y = 0
            local half = stage.buff_max / 2
            if (i > half) then
                x = (stage.buff_bagRx + stage.buff_margin) * (i - half - 1)
                y = stage.buff_bagRy + stage.buff_margin
            end
            stage.buff_buffs[i] = FrameButton(kit .. '->btn->' .. i, stage.buff)
                .relation(FRAME_ALIGN_LEFT_BOTTOM, stage.buff, FRAME_ALIGN_LEFT_BOTTOM, x, y)
                .size(stage.buff_bagRx, stage.buff_bagRy)
                .highlight(false)
                .fontSize(6.5)
                .maskValue(1)
                .show(false)
                .onMouseLeave(function(_) stage.tooltips.show(false, 0) end)
                .onMouseEnter(
                function(evtData)
                    local pi = evtData.triggerPlayer.index()
                    if (stage.buff_catches[pi] ~= nil and stage.buff_catches[pi][i] ~= nil and stage.buff_catches[pi][i].tips ~= nil) then
                        stage.tooltips
                             .relation(FRAME_ALIGN_BOTTOM, stage.buff_buffs[i], FRAME_ALIGN_TOP, 0, 0.002)
                             .content({ tips = stage.buff_catches[pi][i].tips })
                             .show(true)
                    end
                end)
            stage.buff_buffs[i].childText().relation(FRAME_ALIGN_BOTTOM, stage.buff_buffs[i], FRAME_ALIGN_BOTTOM, 0, 0.003)
            stage.buff_buffSignal[i] = FrameBackdrop(kit .. '->signal->' .. i, stage.buff_buffs[i])
                .relation(FRAME_ALIGN_CENTER, stage.buff_buffs[i], FRAME_ALIGN_CENTER, 0, 0)
                .size(stage.buff_bagRx, stage.buff_bagRy)
        end
    end,
    ---@type fun(stage:{buff_buffs:FrameButton[]},whichPlayer:Player)
    onRefresh = function(stage, whichPlayer)
        local pi = whichPlayer.index()
        local tmpData = {
            ---@type Unit
            selection = whichPlayer.selection(),
            buffTexture = {},
            buffAlpha = {},
            buffText = {},
            signalTexture = {},
            maskTexture = {},
            borderTexture = {},
        }
        local buffShow = {}
        for i = 1, stage.buff_max, 1 do
            buffShow[i] = false
        end
        if (isObject(tmpData.selection, 'Unit')) then
            if (tmpData.selection.isAlive()) then
                stage.buff_catches[pi] = {}
                local catch = BuffCatcher(tmpData.selection)
                if (#catch > 0) then
                    local ewi = 0
                    local epi = 0
                    local ewq = 0
                    local epq = 0
                    for _, b in ipairs(catch) do
                        if (#stage.buff_catches[pi] >= stage.buff_max) then
                            break
                        end
                        -- 合并武器
                        local isWeapon = (string.subPos(b.name(), '<WEAPON>') == 1)
                        local isAppend = (string.subPos(b.name(), '<APPEND>') == 1)
                        if (isWeapon == true) then
                            ewq = math.floor(ewq + 1)
                            if (ewi == 0) then
                                table.insert(stage.buff_catches[pi], {
                                    buffTexture = stage.buff_turner.icon(b.name()),
                                    signalTexture = 'signal\\weapon',
                                    maskTexture = 'Singluar\\ui\\nil.tga',
                                    borderTexture = 'btn\\border-white',
                                    text = ewq,
                                    alpha = 255,
                                    tips = { stage.buff_turner.name(b.name()), colour.gold('等级：' .. ewq) },
                                })
                                ewi = #stage.buff_catches[pi]
                            else
                                stage.buff_catches[pi][ewi].text = ewq
                                stage.buff_catches[pi][ewi].tips[2] = colour.gold('等级：' .. ewq)
                            end
                        elseif (isAppend == true) then
                            epq = math.floor(epq + 1)
                            if (epi == 0) then
                                table.insert(stage.buff_catches[pi], {
                                    buffTexture = stage.buff_turner.icon(b.name()),
                                    signalTexture = 'signal\\append',
                                    maskTexture = 'Singluar\\ui\\nil.tga',
                                    borderTexture = 'btn\\border-white',
                                    text = ewq,
                                    alpha = 255,
                                    tips = { stage.buff_turner.name(b.name()), colour.gold('等级：' .. epq) },
                                })
                                epi = #stage.buff_catches[pi]
                            else
                                stage.buff_catches[pi][epi].text = epq
                                stage.buff_catches[pi][epi].tips[2] = colour.gold('等级：' .. epq)
                            end
                        else
                            local isOdds = (string.subPos(b.name(), '<ODDS>') == 1)
                            local isResistance = (string.subPos(b.name(), '<RESISTANCE>') == 1)
                            local signalTexture = 'Singluar\\ui\\nil.tga'
                            local maskTexture = 'Singluar\\ui\\nil.tga'
                            local borderTexture = 'btn\\border-white'
                            if (isOdds) then
                                signalTexture = 'signal\\odds'
                            elseif (isResistance) then
                                signalTexture = 'signal\\resistance'
                            elseif (isWeapon) then
                                signalTexture = 'signal\\weapon'
                            elseif (isAppend) then
                                signalTexture = 'signal\\append'
                            end
                            local lName = stage.buff_turner.name(b.name())
                            local lDur
                            local lText = ''
                            local lAlpha = 255
                            local duration = b.duration()
                            if (duration <= 0) then
                                lDur = colour.gold('常驻效果')
                                borderTexture = 'btn\\border-gold'
                            else
                                lDur = colour.sky('持续: ' .. string.format('%0.1f', duration) .. ' 秒')
                                local remain = b.remain()
                                local line = math.min(5, duration)
                                if (remain > line) then
                                    lAlpha = 255
                                else
                                    lAlpha = 55 + 200 * remain / line
                                end
                                lText = string.format('%0.1f', remain)
                            end
                            local diff = b.diff()
                            if (diff > 0) then
                                lName = lName .. ': ' .. colour.green('+' .. math.round(diff, 2))
                                maskTexture = 'signal\\up'
                            elseif (diff < 0) then
                                lName = lName .. ': ' .. colour.red(math.round(diff, 2))
                                maskTexture = 'signal\\down'
                                borderTexture = 'btn\\border-red'
                            end
                            table.insert(stage.buff_catches[pi], {
                                buffTexture = stage.buff_turner.icon(b.name()),
                                signalTexture = signalTexture,
                                maskTexture = maskTexture,
                                borderTexture = borderTexture,
                                text = lText,
                                alpha = lAlpha,
                                tips = { lName, lDur },
                            })
                        end
                    end
                end
                if (#stage.buff_catches[pi] > 0) then
                    for i, c in ipairs(stage.buff_catches[pi]) do
                        if (i > stage.buff_max) then
                            buffShow[i] = false
                            break
                        end
                        tmpData.buffTexture[i] = c.buffTexture
                        tmpData.maskTexture[i] = c.maskTexture
                        tmpData.borderTexture[i] = c.borderTexture
                        tmpData.buffAlpha[i] = c.alpha
                        tmpData.buffText[i] = c.text
                        tmpData.signalTexture[i] = c.signalTexture
                        buffShow[i] = true
                    end
                end
            end
        end
        async.call(whichPlayer, function()
            for bi = 1, stage.buff_max, 1 do
                if (buffShow[bi] == true) then
                    stage.buff_buffSignal[bi].texture(tmpData.signalTexture[bi])
                    stage.buff_buffs[bi].texture(tmpData.buffTexture[bi])
                    stage.buff_buffs[bi].alpha(tmpData.buffAlpha[bi])
                    stage.buff_buffs[bi].text(tmpData.buffText[bi])
                    stage.buff_buffs[bi].mask(tmpData.maskTexture[bi])
                    stage.buff_buffs[bi].border(tmpData.borderTexture[bi])
                    stage.buff_buffs[bi].show(true)
                else
                    stage.buff_buffs[bi].show(false)
                end
            end
        end)
    end,
}