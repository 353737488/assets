--[[
    动画
    Author: hunzsig
]]

local kit = 'singluar_animate'

local this = UIKit(kit)

this.onSetup(function()
    local stage = this.stage()
    stage.main = FrameAnimate(kit .. "->an1", FrameGameUI)
        .relation(FRAME_ALIGN_CENTER, FrameGameUI, FRAME_ALIGN_CENTER, 0, 0)
        .size(0.048, 0.06)
        .duration(1)
        .halt(0)
        .motion({
        "motion\\00",
        "motion\\01",
        "motion\\02",
        "motion\\03",
        "motion\\04",
        "motion\\05",
        "motion\\06",
        "motion\\07",
        "motion\\08",
        "motion\\09",
    })
    stage.main.play(true)
end)
