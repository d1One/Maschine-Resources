------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"

require "Scripts/Maschine/Helper/GridHelper"
require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Maschine/MaschineMikro/ScreenMikro"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternLengthPageMikro = class( 'PatternLengthPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- Setup
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "PatternLengthPageMikro", Controller)

    -- setup screen
    self:setupScreen()

    self.ParameterIndex = 1

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- define page leds
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:setupScreen()

	self.Screen = ScreenMikro(self)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"RECORD"})
    self.Screen:styleScreenButtons({"2", "4", "8"}, "HeadButtonRow", "HeadButton")

end


------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:updateScreens(ForceUpdate)

    local SongView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local SongClip = NI.DATA.StateHelper.getFocusClipEvent(App)

    for idx = 1, 3 do
        self.Screen.ScreenButton[idx]:setEnabled(SongView and SongClip ~= nil or not SongView)
    end

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:updateParameters(ForceUpdate)

    local NameLabel = self.Screen.ParameterLabel[2]
    local ValueLabel = self.Screen.ParameterLabel[4]

    local Name = self.ParameterIndex .. "/1: LENGTH"
    local Value = "-"

	local StateCache = App:getStateCache()
	local Song = NI.DATA.StateHelper.getFocusSong(App)
	local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    -- display length of selected pattern
    if Song and Pattern then
        Value = Song:getTickToString(Pattern:getLengthParameter():getValue())
    end

    NameLabel:setText(Name)
    ValueLabel:setText(Value)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:updateLeftRightLEDs(ForceUpdate)

	self.Screen.ParameterLabel[1]:setVisible(false)
    self.Screen.ParameterLabel[3]:setVisible(false)

	PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- Event handling
------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:onWheel(Inc)

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
        self.TransactionSequenceMarker:set()
        NI.DATA.EventPatternAccess.changeFocusClipEventLength(App, Inc, self.Controller:getWheelButtonPressed())
    else
        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        if Pattern then
            local Quick = GridHelper.isQuickEnabled()
            NI.DATA.EventPatternAccess.incrementExplicitLength(App, Pattern, Inc, self.Controller:getWheelButtonPressed(), Quick)
        end
    end

	return true

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:onScreenButton(Idx, Pressed)

    if Pressed then
		if Idx >= 1 and Idx <= 3 then

            local PatternLengthInBars = 2 ^ Idx
            PatternHelper.setPatternOrClipEventLength(PatternLengthInBars)

		end
	end

    -- call base class
	PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:onRecordButton(Pressed)

    if not Pressed then
        NHLController:getPageStack():popPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPageMikro:onPageButton(Button, PageID, Pressed)

    if Pressed then
        NHLController:getPageStack():popPage()
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

