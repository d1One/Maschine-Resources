
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Maschine/Helper/GridHelper"
require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPageBase = class( 'PatternPageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:__init(ParentPage, Controller, Page)

    PageMaschine.__init(self, Page, Controller)

    -- setup screen
    self:setupScreen()

    self.TransactionSequenceMarker = TransactionSequenceMarker()
    self.ParentPage = ParentPage

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PATTERN }

    -- Showing rename as shift functionality is only available to non-desktop MASCHINE
    self.ShowRename = NI.APP.isHeadless()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:setupScreen()

    self.Screen.ScreenButton[1]:style("PATTERN", "HeadPin")
    self.Screen.ScreenButton[7]:style("<", "ScreenButton")
    self.Screen.ScreenButton[8]:style(">", "ScreenButton")

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:updateScreenButtons(ForceUpdate)

    -- Pin Button
    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local ShiftPressed = self.Controller:getShiftPressed()
    local HasPattern = Pattern ~= nil
    local HasGroup = Group ~= nil

    -- Button 2 -- Remove
    self.Screen.ScreenButton[2]:setEnabled(HasPattern)
    self.Screen.ScreenButton[2]:setVisible(not ShiftPressed)

    -- Button 3 -- Double
    self.Screen.ScreenButton[3]:setEnabled(HasPattern and NI.DATA.EventPatternAccess.canDoublePattern(App, Pattern))
    self.Screen.ScreenButton[3]:setVisible(not ShiftPressed and HasGroup)

    -- Button 4 -- Duplicate
    self.Screen.ScreenButton[4]:setEnabled(HasPattern)
    self.Screen.ScreenButton[4]:setVisible(not ShiftPressed and HasGroup)

    -- Button 5 -- Create / Rename
    if ShiftPressed and self.ShowRename then

        self.Screen.ScreenButton[5]:setText("RENAME")
        self.Screen.ScreenButton[5]:setEnabled(HasPattern)
        self.Screen.ScreenButton[5]:setVisible(true)

    elseif ShiftPressed then

        self.Screen.ScreenButton[5]:setText("")
        self.Screen.ScreenButton[5]:setEnabled(false)
        self.Screen.ScreenButton[5]:setVisible(false)

    else

        self.Screen.ScreenButton[5]:setText("CREATE")
        self.Screen.ScreenButton[5]:setEnabled(HasGroup)
        self.Screen.ScreenButton[5]:setVisible(true)

    end

    -- Button 6 -- Delete / Delete Bank
    if ShiftPressed then

        self.Screen.ScreenButton[6]:setText("DEL BANK")
        self.Screen.ScreenButton[6]:setEnabled(Group and (not Group:getPatterns():empty()) or false)

    else

        self.Screen.ScreenButton[6]:setText("DELETE")
        self.Screen.ScreenButton[6]:setEnabled(HasPattern)

    end

    -- prev/next pattern banks
    local HasPrev, HasNext = PatternHelper.hasPrevNextPatternBanks()
    local CanAdd = PatternHelper.canAddPatternBank()

    -- Button 7 -- Prev Pattern Bank
    self.Screen.ScreenButton[7]:setEnabled(HasPrev)

    -- Button 8 -- Next Pattern Bank
    self.Screen.ScreenButton[8]:setText(CanAdd and "+" or ">>")
    self.Screen.ScreenButton[8]:setEnabled(HasNext or CanAdd)

    -- call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

    -- update left/right LEDs
    self:updateLeftRightLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:updateParameters(ForceUpdate)

    if self.ParameterHandler.PageIndex == 1 then

        self.ParameterHandler:setCustomSections({"Pattern"})
        self.ParameterHandler:setCustomNames({"POSITION", nil, "START", "LENGTH"})
        self.ParameterHandler:setCustomValues({PatternHelper.startString(), nil, PatternHelper.startString(), PatternHelper.lengthString()})

    end

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:updatePadLEDs()

    PatternHelper.updatePadLEDs(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:updateLeftRightLEDs()

    local HasNext = PatternHelper.hasPrevNextPattern(true)
    local HasPrev = PatternHelper.hasPrevNextPattern(false)

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, HasPrev)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, HasNext)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onPadEvent(PadIndex, Trigger)

    PatternHelper.onPatternPagePadEvent(PadIndex, Trigger, self.Controller:getErasePressed())
    self:updateLeftRightLEDs()

    return true --handled

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onLeftRightButton(Right, Pressed)

    if Pressed and PatternHelper.hasPrevNextPattern(Right) then
        PatternHelper.focusPrevNextPattern(Right)
    end

    self:updateLeftRightLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onScreenButton(Idx, Pressed)

    if Pressed then

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local ShiftPressed = self.Controller:getShiftPressed()

        if Idx == 1 then

            self.ParentPage:togglePinState()

        elseif Idx == 2 and not ShiftPressed then

            PatternHelper.removeFocusPattern()

        elseif Idx == 3 and not ShiftPressed and Pattern then

            NI.DATA.EventPatternAccess.doublePattern(App, Pattern)

        elseif Idx == 4 and not ShiftPressed then

            PatternHelper.duplicatePattern()

        elseif Idx == 5 and Group then

            if ShiftPressed and self.ShowRename and Pattern then

                local NameParam = Pattern:getNameParameter()
                MaschineHelper.openRenameDialog(NameParam:getValue(), Pattern:getNameParameter())

            elseif not ShiftPressed then

                NI.DATA.GroupAccess.insertPattern(App, Group, NI.DATA.StateHelper.getFocusEventPattern(App))

            end

        elseif Idx == 6 then

            PatternHelper.deletePatternOrBank(ShiftPressed)

        elseif Pressed and (Idx == 7 or Idx == 8) then

            PatternHelper.setPrevNextPatternBank(Idx == 8)

        end

    end

    self:updateLeftRightLEDs()

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onScreenEncoder(KnobIdx, EncoderInc)

    if self.ParameterHandler.PageIndex == 1 then

        if MaschineHelper.onScreenEncoderSmoother(KnobIdx, EncoderInc, .1) == 0 then
            return
        end

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        if not Pattern then
            return
        end

        if KnobIdx == 1 then
            self.TransactionSequenceMarker:set()
            NI.DATA.EventPatternAccess.incrementPosition(
                App, Pattern, EncoderInc > 0 and 1 or -1, self.Controller:getShiftPressed())

        elseif KnobIdx == 3 then
            self.TransactionSequenceMarker:set()
            NI.DATA.EventPatternAccess.incrementStart(
                App, Pattern, EncoderInc > 0 and 1 or -1, self.Controller:getShiftPressed())

        elseif KnobIdx == 4 then
            self.TransactionSequenceMarker:set()

            local Quick = GridHelper.isQuickEnabled()
            NI.DATA.EventPatternAccess.incrementExplicitLength(
                App, Pattern, EncoderInc > 0 and 1 or -1, self.Controller:getShiftPressed(), Quick)
        end

    end
end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onWheel()

    if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
        self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onVolumeEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onTempoEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:onSwingEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageBase:getScreenButtonInfo(Index)
    local ButtonText = self.Screen.ScreenButton[Index]:getText()

    if ButtonText == "+" then
        ButtonText = "Create Pattern"
    end

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ButtonText
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = true
    Info.SpeakValueInNormalMode = false
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = false

    return Info

end
