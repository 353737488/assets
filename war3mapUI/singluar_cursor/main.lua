--[[
    玩家鼠标指针
    Author: hunzsig
]]

local kit = 'singluar_cursor'

local this = UIKit(kit)

this.onSetup(function()

    local cursor = Cursor()
        .uiKit(kit)
        --.textureRadius("circle\\common")

end)