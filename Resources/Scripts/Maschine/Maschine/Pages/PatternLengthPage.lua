------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

require "Scripts/Maschine/Helper/GridHelper"
require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternLengthPage = class( 'PatternLengthPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "PatternLengthPage", Controller)

    -- setup screen
    self:setupScreen()

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- define page leds
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:setupScreen()

	self.Screen = ScreenMaschine(self)

    -- screen buttons
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"", "METRO", "", ""}, "HeadButton", true)
    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"2", "4", "8", "16"}, "HeadButton")

    -- right-screen
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")

    -- parameter bar
	self.Screen:addParameterBar(self.Screen.ScreenLeft)
    self.ParameterHandler.NumPages = 1

    local Line = NI.GUI.insertLabel(self.Screen.ScreenRight, "Line")
    Line:style("", "BlackLine")

    self.Screen.ParameterWidgets[4]:setName("LENGTH")

end

------------------------------------------------------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:updateScreens(ForceUpdate)

    self.Screen.ScreenButton[2]:setSelected(App:getMetronome():getEnabledParameter():getValue())

    local SongView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local SongClip = NI.DATA.StateHelper.getFocusClipEvent(App)

    for idx = 5, 8 do
        self.Screen.ScreenButton[idx]:setEnabled(SongView and SongClip ~= nil or not SongView)
    end

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:updateParameters(ForceUpdate)

	local StateCache = App:getStateCache()
	local Song = NI.DATA.StateHelper.getFocusSong(App)
	local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    local Length = "-"
    if Song and Pattern then
        Length = PatternHelper.lengthString()
    end

    self.Screen.ParameterWidgets[4]:setValue(Length)

end

------------------------------------------------------------------------------------------------------------------------
-- Event handling
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onScreenButton(Idx, Pressed)

    if Pressed then

		if Idx == 2 then

		    local EnabledParameter = App:getMetronome():getEnabledParameter()
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, EnabledParameter, not EnabledParameter:getValue())

        elseif Idx >= 5 and Idx <= 8 then

            local PatternLengthInBars = 2 ^ (Idx - 4)
            PatternHelper.setPatternOrClipEventLength(PatternLengthInBars)

		end
	end

    -- call base class
	PageMaschine.onScreenButton(self, Idx, Pressed)

end


------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()
    end

    PageMaschine.onShow(self, Show)

end


------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onScreenEncoder(Idx, Inc)

    if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) == 0 then
        return
	end

	if Idx == 4 then

        if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
            self.TransactionSequenceMarker:set()
            NI.DATA.EventPatternAccess.changeFocusClipEventLength(
                App, Inc > 0 and 1 or -1, self.Controller:getShiftPressed())
        else
            local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
            if Pattern then
                NI.DATA.EventPatternAccess.incrementExplicitLength(
                    App, Pattern, Inc > 0 and 1 or -1, self.Controller:getShiftPressed(), GridHelper.isQuickEnabled())
            end
        end
        if NHLController:isExternalAccessibilityRunning() then
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

            if Song and Pattern then
                Length = PatternHelper.lengthString()
                local row = 3
                NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, Idx, 0, row, 0, Length)
                NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_ERPS, Idx)
            end
        end

	end

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onRecordButton(Pressed)

    if not Pressed then
        NHLController:getPageStack():popPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onPageButton(Button, PageID, Pressed)

    if Pressed then
        NHLController:getPageStack():popPage()
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

