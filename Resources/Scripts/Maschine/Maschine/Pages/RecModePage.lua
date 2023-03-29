------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RecModePage = class( 'RecModePage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function RecModePage:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "RecModePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_CONTROL, NI.HW.LED_TRANSPORT_GRID }

end

------------------------------------------------------------------------------------------------------------------------

function RecModePage:setupScreen()

	self.Screen = ScreenMaschine(self)

    -- left screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"REC. MODE", "METRO", "", ""}, "HeadButton", true)
    self.Screen.ScreenButton[1]:style("REC. MODE", "HeadPin")

    -- always looks pinned
    self.Screen.ScreenButton[1]:setSelected(true)
    self.IsPinned = true

    -- right-screen
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")
    self.Screen:addParameterBar(self.Screen.ScreenRight)

    self.ParameterHandler:setCustomSections({"Metronome", "", "", "Count-In", "Quantize"})

end

------------------------------------------------------------------------------------------------------------------------

function RecModePage:updateScreens(ForceUpdate)

    self.Screen.ScreenButton[2]:setSelected(App:getMetronome():getEnabledParameter():getValue())

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function RecModePage:updateParameters(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local SongSignatureDenominatorParam = Song and Song:getDenominatorParameter() or nil
    local Metronome = App:getMetronome()

    if SongSignatureDenominatorParam and (SongSignatureDenominatorParam:isChanged() or ForceUpdate) then

        local Params = {
            Metronome:getVolumeParameter(),
            Metronome:getTimeSignatureParameter(SongSignatureDenominatorParam:getValue()),
            Metronome:getAutoEnableParameter(),
            Metronome:getCountInLengthParameter(),
            App:getWorkspace():getQuantizeModeParameter()
        }

        self.ParameterHandler:setParameters(Params, false)

    end

    -- Call base class
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- (PageMaschine)
------------------------------------------------------------------------------------------------------------------------

function RecModePage:onLeftRightButton(Right, Pressed)

    -- overwrite base class to avoid switching parameter area pages

end

------------------------------------------------------------------------------------------------------------------------

function RecModePage:onScreenButton(Idx, Pressed)

    if Pressed then
		if Idx == 2 then
		    local EnabledParameter = App:getMetronome():getEnabledParameter()
		    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, EnabledParameter, not EnabledParameter:getValue())
		end
	end

	PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

