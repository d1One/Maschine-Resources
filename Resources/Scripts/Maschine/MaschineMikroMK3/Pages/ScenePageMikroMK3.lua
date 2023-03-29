------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScenePageMikroMK3 = class( 'ScenePageMikroMK3', PageMikroMK3 )

local AppendMode = false

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "ScenePageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikroMK3:onShow(Show)

    ArrangerHelper.setAppendMode(self, AppendMode)

    if Show then
        NHLController:setPadMode(NI.HW.PAD_MODE_SCENE)
    end

    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikroMK3:updateScreen()

    local FocusScene = NI.DATA.StateHelper.getFocusScene(App)
    local FocusSceneName = FocusScene and FocusScene:getNameParameter():getValue() or "No Scene"
    self.Screen:setTopRowText(FocusSceneName)

    local FocusedParameter = NHLController:focusedParameter()
    local FocusedParameterName = FocusedParameter and FocusedParameter:name()

    if FocusedParameterName and FocusedParameterName == "Bank" then

        self.Screen:setSceneBankParameter()
    else
        self.Screen:setBottomRowToFocusedPageParameter()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikroMK3:onPadEvent(PadIndex, Trigger, PadValue)

    local DeleteScene = self.Controller:isErasePressed()
    local CreateSceneIfEmpty = not AppendMode

    ArrangerHelper.onPadEventIdeas(PadIndex, Trigger, DeleteScene, CreateSceneIfEmpty, AppendMode)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikroMK3:updatePadLEDs()

    ArrangerHelper.updatePadLEDsIdeaSpace(self.Controller, AppendMode)

end

------------------------------------------------------------------------------------------------------------------------
