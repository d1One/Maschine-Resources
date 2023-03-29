------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/DuplicateHelper"
require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicateScenePageMikroMK3 = class( 'DuplicateScenePageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function DuplicateScenePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "DuplicateScenePageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateScenePageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateScenePageMikroMK3:onShow(Show)

    self:reset()
    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateScenePageMikroMK3:reset()

    self.Mode = DuplicateHelper.SCENE
    self.SourceIndex = -1
    self.SourceGroupIndex = -1

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateScenePageMikroMK3:updateScreen()

    local FocusScene = NI.DATA.StateHelper.getFocusScene(App)
    local FocusSceneName = FocusScene and "Dupl. "..FocusScene:getNameParameter():getValue() or "No Scene"
    self.Screen:setTopRowText(FocusSceneName)

    local FocusedParameter = NHLController:focusedParameter()
    local FocusedParameterName = FocusedParameter and FocusedParameter:name()

    if FocusedParameterName and FocusedParameterName == "Bank" then
        self.Screen:setSceneBankParameter()
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateScenePageMikroMK3:onPadEvent(PadIndex, Trigger, _)

    if not Trigger then
        return
    end

    DuplicateHelper.onPadEvent(self, PadIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateScenePageMikroMK3:updatePadLEDs()

    DuplicateHelper.updatePadLEDs(self, self.Controller.PAD_LEDS, self.SourceIndex >= 0)

end

------------------------------------------------------------------------------------------------------------------------
