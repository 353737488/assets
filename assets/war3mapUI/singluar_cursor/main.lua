--[[
    玩家鼠标指针
    Author: hunzsig
]]

local kit = 'singluar_cursor'

local this = UIKit(kit)

this.onSetup(function()
    local stage = this.stage()
    stage.playerData = {}
    stage.radiusAreaLimit = 0
    stage.main = FrameBackdrop(kit, FrameGameUI)
    --- 单位技能左键引用
    mouse.onLeftClick(function(evtData)
        local cs = evtData.triggerPlayer.cursor()
        local ab = cs.ability()
        local obj = cs.followObject()
        local pIdx = evtData.triggerPlayer.index()
        if (isObject(ab, "Ability")) then
            local tt = ab.targetType()
            if (tt == ABILITY_TARGET_TYPE.TAG_U or tt == ABILITY_TARGET_TYPE.TAG_L or tt == ABILITY_TARGET_TYPE.TAG_R) then
                -- x 0.240 0.32
                -- y 0.125 0.5925
                local rx = japi.MouseRX()
                local ry = japi.MouseRY()
                if (ry < 0.125) then
                    if (rx > 0.240 and rx < 0.32) then
                        if (tt == ABILITY_TARGET_TYPE.TAG_U) then
                            sync.send("SINGLUAR_GAME_SYNC", { pIdx, "ability_effective_u", ab.id(), evtData.triggerPlayer.selection().id() })
                        end
                    end
                    return
                elseif (ry > 0.5925) then
                    return
                end
                if (tt == ABILITY_TARGET_TYPE.TAG_L or tt == ABILITY_TARGET_TYPE.TAG_R) then
                    sync.send("SINGLUAR_GAME_SYNC", { pIdx, "ability_effective_xyz", ab.id(), japi.DzGetMouseTerrainX(), japi.DzGetMouseTerrainY(), japi.DzGetMouseTerrainZ() })
                end
            end
        elseif (obj ~= nil) then
            if (isObject(obj, "Item")) then
                -- 丢弃物品在鼠标坐标
                local mx = japi.MouseRX()
                local my = japi.MouseRY()
                if (mx > 0.01 and mx < 0.79 and my > 0.155 and my < 0.56) then
                    sync.send("SINGLUAR_GAME_SYNC", { pIdx, "item_drop_cursor", obj.id(), japi.DzGetMouseTerrainX(), japi.DzGetMouseTerrainY() })
                end
            end
        end
    end, "singluar_cursor")
end)

---@param ab Ability
_sCursorCatcher = function(x, y, radius, limit, ab)
    local g = group.catch({
        key = "Unit",
        x = x, y = y, radius = radius,
        limit = limit,
        ---@param enumUnit Unit
        filter = function(enumUnit)
            return enumUnit.isAlive() and ab.isCastTarget(enumUnit)
        end
    })
    return g
end

this.onRefresh(0.03, function()
    local stage = this.stage()
    stage.radiusAreaLimit = stage.radiusAreaLimit + 1
    for pi, p in ipairs(Players(table.section(1, 12))) do
        if (p.isPlaying()) then
            if (stage.playerData[pi] == nil) then
                stage.playerData[pi] = {}
            end
            local race = p.race()
            local tmpData = stage.playerData[pi]
            tmpData.alpha = 255
            tmpData.texture = "Singluar\\ui\\nil.tga"
            tmpData.size = { 0.01, 0.01 }
            tmpData.radius = tmpData.radius or {
                x = 0,
                y = 0,
                range = nil,
                ---@type Unit[]
                units = {}
            }
            tmpData.radius.size = 0.01
            tmpData.radius.z = -9999
            ---@type Ability
            local ab = p.cursor().ability()
            if (isObject(ab, "Ability") == false) then
                tmpData.texture = "Singluar\\ui\\nil.tga"
                tmpData.size = { 0.01, 0.01 }
            else
                local tt = ab.targetType()
                if (tt == nil or tt == ABILITY_TARGET_TYPE.PAS or tt == ABILITY_TARGET_TYPE.TAG_E) then
                    tmpData.texture = "Singluar\\ui\\nil.tga"
                    tmpData.size = { 0.01, 0.01 }
                else
                    -- 选择圈特效
                    if (tmpData.radius.area ~= nil) then
                        if (stage.radiusAreaLimit >= 25) then
                            stage.radiusAreaLimit = 0
                            japi.EXSetEffectSize(tmpData.radius.area, 0.01)
                            japi.EXSetEffectXY(tmpData.radius.area, 0, 0)
                            japi.EXSetEffectZ(tmpData.radius.area, -9999)
                            J.DestroyEffect(tmpData.radius.area)
                            J.handleUnRef(tmpData.radius.area)
                            tmpData.radius.area = nil
                        end
                    end
                    if (tmpData.radius.area == nil) then
                        local eff
                        if (p.handle() == JassCommon["GetLocalPlayer"]()) then
                            eff = AUIKit(kit, "spellArea\\" .. race, "mdl")
                        else
                            eff = ''
                        end
                        tmpData.radius.area = J.AddSpecialEffect(eff, tmpData.radius.x, tmpData.radius.y)
                        J.handleRef(tmpData.radius.area)
                        japi.EXSetEffectZ(tmpData.radius.area, tmpData.radius.z)
                        japi.EXSetEffectSize(tmpData.radius.area, tmpData.radius.size)
                    end
                    --
                    local bindUnit = ab.bindUnit()
                    local isProhibiting = ab.isProhibiting()
                    local coolDownRemain = ab.coolDownRemain()
                    if (isProhibiting or coolDownRemain > 0 or isObject(bindUnit, "Unit") == false) then
                        tmpData.texture = "Singluar\\ui\\nil.tga"
                        tmpData.size = { 0.01, 0.01 }
                    else
                        local isBan = bindUnit.isInterrupt() or bindUnit.isPause() or bindUnit.isAbilityChantCasting() or bindUnit.isAbilityKeepCasting()
                        local castRadius = ab.castRadius()
                        local rx = japi.MouseRX()
                        local ry = japi.MouseRY()
                        if (rx < 0.015 or rx > 0.784 or ry < 0.02 or ry > 0.577) then
                            tmpData.texture = "Singluar\\ui\\nil.tga"
                            tmpData.size = { 0.01, 0.01 }
                        else
                            local tx = japi.DzGetMouseTerrainX()
                            local ty = japi.DzGetMouseTerrainY()
                            if (tt == ABILITY_TARGET_TYPE.TAG_U or tt == ABILITY_TARGET_TYPE.TAG_L) then
                                tmpData.texture = "cursor\\aim_white"
                                tmpData.size = { 0.03, 0.04 }
                                if (isBan) then
                                    tmpData.alpha = 100
                                end
                                local catch = _sCursorCatcher(tx, ty, 120, 5, ab)
                                local closest
                                if (#catch > 0) then
                                    local closestDst = 999
                                    for _, c in ipairs(catch) do
                                        local dst = math.distance(tx, ty, c.x(), c.y())
                                        if (dst < closestDst) then
                                            closest = c
                                            closestDst = dst
                                        end
                                    end
                                end
                                if (isObject(closest, "Unit")) then
                                    if (closest.isEnemy(p)) then
                                        tmpData.texture = "cursor\\aim_red"
                                    else
                                        tmpData.texture = "cursor\\aim_green"
                                    end
                                end
                                async.call(p, function()
                                    japi.DzFrameSetPoint(stage.main.handle(), FRAME_ALIGN_CENTER, FrameGameUI.handle(), FRAME_ALIGN_LEFT_BOTTOM, rx, ry)
                                end)
                            elseif (tt == ABILITY_TARGET_TYPE.TAG_R) then
                                tmpData.texture = "Singluar\\ui\\nil.tga"
                                tmpData.size = { 0.01, 0.01 }
                                if (ry >= 0.1343) then
                                    local curRadius = tmpData.radius.range
                                    if (curRadius == nil) then
                                        curRadius = castRadius
                                    elseif (curRadius ~= castRadius) then
                                        if (castRadius - curRadius > 20) then
                                            curRadius = curRadius + 20
                                        elseif (curRadius - castRadius > 20) then
                                            curRadius = curRadius - 20
                                        else
                                            curRadius = castRadius
                                        end
                                    end
                                    tmpData.radius.range = curRadius
                                    tmpData.radius.size = tmpData.radius.range / 256
                                    tmpData.radius.x = tx
                                    tmpData.radius.y = ty
                                    tmpData.radius.z = japi.DzGetMouseTerrainZ()
                                    local radiusUnits = _sCursorCatcher(tx, ty, tmpData.radius.range, 30, ab)
                                    local radiusUnitFlag = {}
                                    for _, ru in ipairs(radiusUnits) do
                                        radiusUnitFlag[ru.id()] = true
                                    end
                                    for _, dru in ipairs(tmpData.radius.units) do
                                        if (radiusUnitFlag[dru.id()] == nil) then
                                            local rgba = dru.rgba()
                                            local red = rgba.get('red')
                                            local green = rgba.get('green')
                                            local blue = rgba.get('blue')
                                            local alpha = rgba.get('alpha')
                                            async.call(p, function()
                                                J.SetUnitVertexColor(dru.handle(), red, green, blue, alpha)
                                            end)
                                        end
                                    end
                                    tmpData.radius.units = radiusUnits
                                    radiusUnits = nil
                                    if (#tmpData.radius.units > 0) then
                                        for _, ru in ipairs(tmpData.radius.units) do
                                            local red = 255
                                            local green = 255
                                            local blue = 255
                                            local alpha = 255
                                            if (ru.owner().isNeutral()) then
                                                green = 230
                                                blue = 0
                                            elseif (ru.isEnemy(p)) then
                                                green = 0
                                                blue = 0
                                            elseif (ru.isAlly(p)) then
                                                red = 127
                                                blue = 0
                                            else
                                                alpha = 100
                                            end
                                            if ((red ~= 255 or green ~= 255 or blue ~= 255)) then
                                                async.call(p, function()
                                                    J.SetUnitVertexColor(ru.handle(), red, green, blue, alpha)
                                                end)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if (tmpData.radius.z == -9999 and #tmpData.radius.units > 0) then
                for _, dru in ipairs(tmpData.radius.units) do
                    local rgba = dru.prop("rgbaBase")
                    local red = rgba.get('red')
                    local green = rgba.get('green')
                    local blue = rgba.get('blue')
                    local alpha = rgba.get('alpha')
                    async.call(p, function()
                        J.SetUnitVertexColor(dru.handle(), red, green, blue, alpha)
                    end)
                end
                tmpData.radius.units = {}
            end
            japi.EXSetEffectXY(tmpData.radius.area, tmpData.radius.x, tmpData.radius.y)
            japi.EXSetEffectZ(tmpData.radius.area, tmpData.radius.z)
            japi.EXSetEffectSize(tmpData.radius.area, tmpData.radius.size)
            async.call(p, function()
                japi.DzFrameSetTexture(stage.main.handle(), AUIKit(kit, tmpData.texture, 'tga'), 0)
                japi.DzFrameSetSize(stage.main.handle(), tmpData.size[1], tmpData.size[2])
                japi.DzFrameSetAlpha(stage.main.handle(), tmpData.alpha)
            end)
        end
    end
end)
