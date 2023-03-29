------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Maschine/Helper/GridHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/PatternHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPageMikro = class( 'PatternPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "PatternPage", Controller)

    -- setup screen
    self:setupScreen()

    self.ParameterIndex = 1

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PATTERN }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"PATTERN"})
    self.Screen:styleScreenButtons({"DOUBLE", "DUPL", "DELETE"}, "HeadButtonRow", "HeadButton")

    self.Screen.InfoBar:setMode("FocusedPattern")

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:updateScreens(ForceUpdate)

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Clip = Group and Group:getClipSequence():getFocusEvent()

    ScreenHelper.setWidgetText(self.Screen.Title, { SongClipView and "CLIP" or "PATTERN" })

    self.Screen.InfoBar:update(true)

    local EnablePatternEdit = Pattern ~= nil and not SongClipView
    local EnableClipEdit = Clip ~= nil and SongClipView

    if EnablePatternEdit then
        self.Screen.ScreenButton[1]:setEnabled(NI.DATA.EventPatternAccess.canDoublePattern(App, Pattern))
    elseif EnableClipEdit then
        self.Screen.ScreenButton[1]:setEnabled(NI.DATA.GroupAccess.canDoubleClipEvent(App, Clip))
    else
        self.Screen.ScreenButton[1]:setEnabled(false)
    end
    self.Screen.ScreenButton[1]:setVisible(not self.Controller:getShiftPressed() and Group ~= nil)
    self.Screen.ScreenButton[1]:setText("DOUBLE")

    self.Screen.ScreenButton[2]:setEnabled(Group and EnablePatternEdit or EnableClipEdit)
    self.Screen.ScreenButton[2]:setVisible(not self.Controller:getShiftPressed() and Group ~= nil)
    self.Screen.ScreenButton[2]:setText("DUPL")

    self.Screen.ScreenButton[3]:setEnabled(EnableClipEdit or EnablePatternEdit)
    self.Screen.ScreenButton[3]:setText((not SongClipView and self.Controller:getShiftPressed()) and "REMOVE" or "DELETE")

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:updateParameters(ForceUpdate)

    if self.Controller:getShiftPressed() then
        -- show pattern banks instead of parameters in parameter bar
		self:updatePatternBankParameters()
	else
		self:updatePatternParameters()
	end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:updatePatternParameters()

    local NameLabel = self.Screen.ParameterLabel[2]
    local ValueLabel = self.Screen.ParameterLabel[4]

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

    local ParameterNames = {}

    ParameterNames = { "POSITION", "START", "LENGTH" }

    local Name = self.ParameterIndex.."/" .. #ParameterNames .. ": " .. ParameterNames[self.ParameterIndex]
    local Value = "-"

    if SongClipView then
        if self.ParameterIndex == 1 then
            -- display position of selected clip
            Value = ClipHelper.getFocusClipStartString()

        elseif self.ParameterIndex == 2 then
            -- display start of selected clip
            Value = ClipHelper.getFocusClipStartString()

        elseif self.ParameterIndex == 3 then
            -- display length of selected clip
            Value = ClipHelper.getFocusClipLengthString()

        end
    else

        if self.ParameterIndex == 1 or self.ParameterIndex == 2 then
            -- display start of selected pattern
            Value = PatternHelper.startString()

        elseif self.ParameterIndex == 3 then
            -- display length of selected pattern
            Value = PatternHelper.lengthString()

        end
    end

    NameLabel:setText(Name)
    ValueLabel:setText(Value)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:updatePatternBankParameters()

    local NameLabel = self.Screen.ParameterLabel[2]
    local ValueLabel = self.Screen.ParameterLabel[4]

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

    local Name = ""

    if SongClipView then

        local Bank, NumBanks = ClipHelper.getCurrentBank()
        Name = "Bank: " ..tostring(Bank + 1).."/"..tostring(NumBanks + 1)

    else

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)

        if Song and Group then
            local PatternIdx = Group:getFocusPatternBankIndexParameter():getValue()
            local NumBanks = Song:getNumPatternBanksParameter():getValue()

            Name = "Bank: "..tostring(PatternIdx+1).."/"..tostring(NumBanks)
        end

    end

	NameLabel:setText(Name)
	ValueLabel:setText("")

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:updateLeftRightLEDs(ForceUpdate)

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local ShiftPressed = self.Controller:getShiftPressed()

    local NumParameters = 3

    if ShiftPressed and SongClipView then

        local Prev, Next = ClipHelper.hasPrevNextBank()

        self.Screen.ParameterLabel[1]:setVisible(Prev)
        self.Screen.ParameterLabel[3]:setVisible(Next)

    elseif ShiftPressed and not SongClipView then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Song and Group then
            local PatternIdx = Group:getFocusPatternBankIndexParameter():getValue()
            local NumBanks = Song:getNumPatternBanksParameter():getValue()

            -- once these labels' visibility are set correctly, the base implementation will do the rest
            self.Screen.ParameterLabel[1]:setVisible(PatternIdx > 0)
            self.Screen.ParameterLabel[3]:setVisible(PatternIdx+1 < NumBanks or PatternHelper.canAddPatternBank())
        end

    else

        self.Screen.ParameterLabel[1]:setVisible(self.ParameterIndex > 1)
        self.Screen.ParameterLabel[3]:setVisible(self.ParameterIndex < NumParameters)

    end

    PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:updatePadLEDs()

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
        ClipHelper.updatePadLEDs(self.Controller.PAD_LEDS)
    else
        PatternHelper.updatePadLEDs(self.Controller.PAD_LEDS)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:onPadEvent(PadIndex, Trigger)

    local ErasePressed = self.Controller:getErasePressed()

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
        ClipHelper.onClipPagePadEvent(PadIndex, Trigger, ErasePressed)
    else
    	PatternHelper.onPatternPagePadEvent(PadIndex, Trigger, ErasePressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:onWheel(Inc)

    if self.Controller:getShiftPressed() then
        return
    end

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then

        if self.ParameterIndex == 1 then

            self.TransactionSequenceMarker:set()

            NI.DATA.EventPatternAccess.changeFocusClipEventPosition(
                App, Inc, self.Controller:getWheelButtonPressed())

        elseif self.ParameterIndex == 2 then

            self.TransactionSequenceMarker:set()

            NI.DATA.EventPatternAccess.changeFocusClipEventStart(
                App, Inc, self.Controller:getWheelButtonPressed())


        elseif self.ParameterIndex == 3 then

            self.TransactionSequenceMarker:set()

            NI.DATA.EventPatternAccess.changeFocusClipEventLength(
                App, Inc, self.Controller:getWheelButtonPressed())
        end
    else

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        if not Pattern then
            return true
        end

        if self.ParameterIndex == 1 then
            self.TransactionSequenceMarker:set()
            NI.DATA.EventPatternAccess.incrementPosition(App, Pattern, Inc, self.Controller:getWheelButtonPressed())
        elseif self.ParameterIndex == 2 then
            self.TransactionSequenceMarker:set()
            NI.DATA.EventPatternAccess.incrementStart(App, Pattern, Inc, self.Controller:getWheelButtonPressed())
        elseif self.ParameterIndex == 3 then
            self.TransactionSequenceMarker:set()
            local Quick = GridHelper.isQuickEnabled()

            NI.DATA.EventPatternAccess.incrementExplicitLength(App, Pattern, Inc, self.Controller:getWheelButtonPressed(), Quick)
        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:onScreenButton(ButtonIdx, Pressed)

    if not self.Screen.ScreenButton[ButtonIdx]:isEnabled() then
        return
    end

    if Pressed then
        if ButtonIdx == 1 then
            NI.DATA.EventPatternAccess.doubleFocusPatternOrClipEvent(App)

        elseif ButtonIdx == 2 then
            if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
                NI.DATA.GroupAccess.duplicateFocusClipEvent(App)
            else
                PatternHelper.duplicatePattern()
            end

        elseif ButtonIdx == 3 then
            if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
                ClipHelper.deleteFocusClip()
            else
                if self.Controller:getShiftPressed() then
                    PatternHelper.removeFocusPattern()
                else
                    PatternHelper.deletePatternOrBank(false)
                end
            end
        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:onLeftRightButton(Right, Pressed)

    if not Pressed then
        return
    end

    local SongClipsInFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

    if self.Controller:getShiftPressed() then
        if SongClipsInFocus then
            ClipHelper.shiftBank(Right)
        else
            -- increment pattern bank when shift button is pressed
            PatternHelper.setPrevNextPatternBank(Right)
        end
    else
        local Inc = Right and 1 or -1
        -- new parameter index will 1 or 2 if in song clip view, 1 otherwise (just pattern length)
        self.ParameterIndex = math.bound(self.ParameterIndex + Inc, 1, 3)

        self:updateParameters()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikro:onShiftButton(Pressed)

	PageMikro.onShiftButton(self, Pressed)
	self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------
