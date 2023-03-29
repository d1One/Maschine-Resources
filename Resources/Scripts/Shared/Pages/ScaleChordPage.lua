------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScaleChordPage = class( 'ScaleChordPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScaleChordPage:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "ScaleChordPage", Controller)

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function ScaleChordPage:setupScreen()

	self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"SCALE", "", "", ""}, "HeadButton", true)

    self.Screen.ScreenButton[1]:setStyle("PerformToggle")
    self.Screen.ScreenButton[1].Color = LEDColors.PERFORM_BLUE

    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, false)

end

------------------------------------------------------------------------------------------------------------------------

function ScaleChordPage:onShow(Show)

    PageMaschine.onShow(self, Show)

    NHLController:setEncoderMode(Show and NI.HW.ENC_MODE_CONTROL or NI.HW.ENC_MODE_NONE)

end

------------------------------------------------------------------------------------------------------------------------

function ScaleChordPage:updateScreens(ForceUpdate)

    local ScaleEngineActive = NI.HW.getScaleEngineActiveParameter(App)
    local ScaleOn = ScaleEngineActive and ScaleEngineActive:getValue() or false
    self.Screen.ScreenButton[1]:setSelected(ScaleOn)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    PageMaschine.updateScreens(self, ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function ScaleChordPage:updateLEDs()

    LEDHelper.setLEDState(NI.HW.LED_CLEAR, LEDHelper.LS_OFF)
end

------------------------------------------------------------------------------------------------------------------------

function ScaleChordPage:onScreenButton(Index, Pressed)

    local ScaleEngineActive = NI.HW.getScaleEngineActiveParameter(App)

    if Pressed and Index == 1 and ScaleEngineActive then
        NI.DATA.ParameterAccess.toggleBoolParameter(App, ScaleEngineActive)
    end

    PageMaschine.onScreenButton(self, Index, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function ScaleChordPage:updateParameters(ForceUpdate)

    local Params = {}

    if self.SetupParametersFunc then
        Params = self.SetupParametersFunc(self.ParameterHandler)
    else
        for Index = 1, 8 do
            Params[Index] = NI.DATA.ParameterCache.getParameterByPosition(App, Index - 1)
        end
    end

    self.ParameterHandler:setParameters(Params, false)
    self.Controller.CapacitiveList:assignParametersToCaps(self.ParameterHandler.Parameters)

    PageMaschine.updateParameters(self, ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

