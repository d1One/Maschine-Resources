------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RecModePageMikro = class( 'RecModePageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function RecModePageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "RecModePage", Controller)

    -- setup screen
    self:setupScreen()

    -- setup parameter handler
    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    -- define page leds
    self.PageLEDs = { NI.HW.LED_TRANSPORT_GRID }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function RecModePageMikro:setupScreen()

    -- create screen
    self.Screen = ScreenMikro(self)

    -- parameter handler
    self.ParameterHandler.Undoable = false

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"REC. MODE"})

    -- Screen Buttons
    self.Screen:styleScreenButtons({"METRO", "", ""}, "HeadButtonRow", "HeadButton")

end

------------------------------------------------------------------------------------------------------------------------

function RecModePageMikro:updateParameters(ForceUpdate)

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

    -- update the values
    self.ParameterHandler:update()

    -- override parameter names
    if self.ParameterHandler.ParameterIndex == 1 then
        self.ParameterHandler.ParamNameLabel:setText("1/5: METRONOME LEVEL")

    elseif self.ParameterHandler.ParameterIndex == 4 then
        self.ParameterHandler.ParamNameLabel:setText("4/5: COUNT-IN LENGTH")

    elseif self.ParameterHandler.ParameterIndex == 5 then
        self.ParameterHandler.ParamNameLabel:setText("5/5: QUANTIZE MODE")

    end

    self.Screen.ParameterLabel[1]:setVisible(self.ParameterHandler.ParameterIndex > 1)
    self.Screen.ParameterLabel[3]:setVisible(self.ParameterHandler.ParameterIndex < #self.ParameterHandler.Parameters)

end

------------------------------------------------------------------------------------------------------------------------

function RecModePageMikro:updateScreens(ForceUpdate)

    self.Screen.ScreenButton[1]:setSelected(App:getMetronome():getEnabledParameter():getValue())

    -- call base class (doesn't actually do anything)
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function RecModePageMikro:onScreenButton(Idx, Pressed)

    if Pressed then
		if Idx == 1 then
		    local EnabledParameter = App:getMetronome():getEnabledParameter()
		    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, EnabledParameter, not EnabledParameter:getValue())
		end
	end

	PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
