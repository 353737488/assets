--[[
    S控制全套
    Author: hunzsig
]]

local kit = 'singluar_set'

local this = UIKit(kit)

this.onSetup(function()
    local stage = this.stage()
    _singluarSetMsg.onSetup(kit, stage)
    _singluarSetMenu.onSetup(kit, stage)
    _singluarSetController.onSetup(kit, stage)
    _singluarSetBuff.onSetup(kit, stage)
    _singluarSetWarehouse.onSetup(kit, stage)
    _singluarSetItem.onSetup(kit, stage)
    _singluarSetAbility.onSetup(kit, stage)
    _singluarSetCaster.onSetup(kit, stage)
    --- 提示框
    stage.tooltips = FrameTooltip(kit .. '->tooltips').textAlign(TEXT_ALIGN_LEFT).fontSize(10)
end)

this.onRefresh(0.03, function()
    ---@type {tips:table,main:FrameBackdrop,miniMap:Frame,miniMapBtns:Frame[],portrait:Frame,portraitShadow:FrameBackdrop,plate:table<string,FrameBackdropTile>,nilDisplay:FrameText,mp:FrameBar,hp:FrameBar,info:table<string,FrameButton|FrameText>,tile:table<string,FrameBar>}
    local stage = this.stage()
    for _, p in ipairs(Players(table.section(1, 12))) do
        if (p.isPlaying()) then
            _singluarSetMsg.onRefresh(stage, p)
            _singluarSetMenu.onRefresh(stage, p)
            _singluarSetController.onRefresh(stage, p)
            _singluarSetBuff.onRefresh(stage, p)
            _singluarSetWarehouse.onRefresh(stage, p)
            _singluarSetItem.onRefresh(stage, p)
            _singluarSetAbility.onRefresh(stage, p)
            _singluarSetCaster.onRefresh(stage, p)
        end
    end
end)