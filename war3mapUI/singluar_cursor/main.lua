--[[
    玩家鼠标指针
    Author: hunzsig
]]

local kit = 'singluar_cursor'

local this = UIKit(kit)

this.onSetup(function()

    local cursor = Cursor()
        .uiKit(kit)
        .textureAim({ normal = "aim\\white", ally = "aim\\green", enemy = "aim\\red" })
        .textureRadius("circle\\common")

end)