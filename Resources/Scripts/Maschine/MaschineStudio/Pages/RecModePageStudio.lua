------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RecModePageStudio = class( 'RecModePageStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function RecModePageStudio:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "RecModePageStudio", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_CONTROL, NI.HW.LED_TRANSPORT_GRID }

end

------------------------------------------------------------------------------------------------------------------------

function RecModePageStudio:setupScreen()

	self.Screen = ScreenMaschineStudio(self)

    -- left screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"REC. MODE", "METRONOME", "", ""}, "HeadButton", true)
    self.Screen.ScreenButton[1]:style("REC. MODE", "HeadPin")

    -- always looks pinned
    self.Screen.ScreenButton[1]:setSelected(true)
    self.IsPinned = true

    -- right screen
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, false)

    self.ParameterHandler:setCustomSections({"Metronome", "", "", "Count-In", "Quantize"})

end

------------------------------------------------------------------------------------------------------------------------

function RecModePageStudio:updateScreens(ForceUpdate)

    self.Screen.ScreenButton[2]:setSelected(App:getMetronome():getEnabledParameter():getValue())

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function RecModePageStudio:updateParameters(ForceUpdate)

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

	    self.Controller.CapacitiveList:assignParametersToCaps(Params)
    end

    -- Call base class
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- (PageMaschine)
------------------------------------------------------------------------------------------------------------------------

function RecModePageStudio:onLeftRightButton(Right, Pressed)

    -- overwrite base class to avoid switching parameter area pages

end

------------------------------------------------------------------------------------------------------------------------

function RecModePageStudio:onScreenButton(Idx, Pressed)

    if Pressed then
		if Idx == 2 then
		    local EnabledParameter = App:getMetronome():getEnabledParameter()
		    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, EnabledParameter, not EnabledParameter:getValue())
		end
	end

	PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

