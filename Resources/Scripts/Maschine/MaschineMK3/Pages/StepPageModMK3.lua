------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineStudio/Pages/StepPageModStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPageModMK3 = class( 'StepPageModMK3', StepPageModStudio )

------------------------------------------------------------------------------------------------------------------------

function StepPageModMK3:__init(Controller)

    StepPageModStudio.__init(self, Controller, "StepPageModMK3")

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModMK3:onWheel(Value, Mode)

    local WheelMode = Mode ~= nil and Mode or NHLController:getJogWheelMode()

    NI.DATA.EventPatternAccess.modifySelectedNotesByJogWheel(App, WheelMode, Value)

    if WheelMode ~= NI.HW.JOGWHEEL_MODE_DEFAULT then
        self.Controller:getInfoBar():setTempMode("QuickEditStep")
    end

    return true -- handled

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModMK3:onWheelDirection(Pressed, Button)

    ControlPageMK3.onWheelDirection(self, Pressed, Button)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModMK3:updateWheelButtonLEDs()

    ControlPageMK3.updateWheelButtonLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModMK3:getAccessiblePageInfo()

    return "Step Modulation"

end

------------------------------------------------------------------------------------------------------------------------

function StepPageModMK3:refreshAccessibleWheelInfo()

     local Layer = NI.HW.LAYER_UNSHIFTED
     NHLController:addAccessibilityControlData(NI.HW.ZONE_JOGWHEEL, 0, Layer, 0, 0, StepHelper.getWheelModeText())
     NHLController:addAccessibilityControlData(NI.HW.ZONE_JOGWHEEL, 0, Layer, 1, 0, QuickEditHelper.getStepValueText())
     NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_JOGWHEEL, 0)

end