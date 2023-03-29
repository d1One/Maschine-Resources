------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PageJam"
require "Scripts/Maschine/Jam/Helper/JamStepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NotesPage = class( 'NotesPage', PageJam )

------------------------------------------------------------------------------------------------------------------------

NotesPage.MAX_NUM_NOTES_PER_ROW = 64
NotesPage.DEFAULT_FIRST_ROW_OFFSET = 24

------------------------------------------------------------------------------------------------------------------------

function NotesPage:__init(Controller)

    PageJam.__init(self, "NotesPage", Controller)
    self.PageLEDs = { NI.HW.LED_NOTES }

    self.GetOSOTypeFn = function() return NI.HW.OSO_NOTES end

    self.NoteArray = JamStepHelper.calcNoteArray()
    self.FirstRowOffsets = {}

    self.Strumming = NHLController:getStrumming()

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:hasDuplicateMode()

    return true

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:getNumNotesInOctave()

    return #self.NoteArray + 1

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:onShow(Show)

    if Show then

        JamHelper.setTouchstripMode(NI.HW.TS_MODE_NOTES)
        PadModeHelper.setKeyboardMode(true)

        self:updateSceneButtonMode()
        self:updateScaleEngineParameters()

    end

    -- call base
    PageJam.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:onCustomProcess(ForceUpdate)

    self.NoteArray = JamStepHelper.calcNoteArray()

    PageJam.onCustomProcess(self)

end

------------------------------------------------------------------------------------------------------------------------
-- Basically sets the Scale parameter to 'off' if it's initially set to 'Chd Set' because 'Chd Set' isn't supported
-- for the Notes feature

function NotesPage:updateScaleEngineParameters()

    local ScaleEngine = NI.DATA.getScaleEngine(App)

    if ScaleEngine and ScaleEngine:getChordModeIsChordSet() then
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, ScaleEngine:getChordModeParameter(), 0)
    end

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:updateSceneButtonMode()

    local NotesPressed = self.Controller:isButtonPressed(NI.HW.BUTTON_NOTES)

    NHLController:setSceneButtonMode(NotesPressed
        and NI.HW.SCENE_BUTTON_MODE_STRUM
        or  NI.HW.SCENE_BUTTON_MODE_DEFAULT)

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:onPageButton(Button, PageID, Pressed)

    if PageID == NI.HW.PAGE_NOTES then

        if Pressed then
            self.Controller.CloseOnPageButtonRelease[PageID] = false
            self.Controller.ParameterHandler:showOSO(NI.HW.OSO_NOTES)
        else
            if JamHelper.isJamOSOVisible(NI.HW.OSO_NOTES) then
                self.Controller.ParameterHandler:startOSOTimeout()
            end
        end

        self:updateSceneButtonMode()

    end

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:isSceneButtonStrumEnabled()

    return NHLController:getSceneButtonMode() == NI.HW.SCENE_BUTTON_MODE_STRUM

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:onSceneButton(Index, Pressed)

    if self:isSceneButtonStrumEnabled() then

        if Pressed then
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local StrumModeParameter = Group and Group:getStrummingModeParameter()

            if Group and Index <= StrumModeParameter:getMax() + 1 then
                NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, StrumModeParameter, Index - 1)
            end
        end

    else
        -- call base
        PageJam.onSceneButton(self, Index, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:updateSceneButtonLEDs()

    if self:isSceneButtonStrumEnabled() then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)

        LEDHelper.updateLEDsWithFunctor(self.Controller.SCENE_LEDS, 0,
            function(Index)
                local StrumModeParameter = Group and Group:getStrummingModeParameter()
                local Enabled = Group and Index <= StrumModeParameter:getMax() + 1 -- max count of modes
                local Focused = Group and Index == StrumModeParameter:getValue() + 1 -- check if the CurrentMode is the selected mode
                return Focused, Enabled
            end,
            function(Index) return LEDColors.WHITE end)
    else
        -- call base
        PageJam.updateSceneButtonLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:updatePadLEDs()

    LEDHelper.updateMatrixLedsWithFunctor(self.Controller.PAD_LEDS,
        JamControllerBase.NUM_PAD_COLUMNS,
        JamControllerBase.NUM_PAD_ROWS,
        function(Row, Column) return self:getMatrixLEDState(Row, Column) end
    )

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:getMatrixLEDState(Row, Column)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Color = Sound and Sound:getColorParameter():getValue()

    local PadIndex = self:calcPadIndex(Row, Column) - 9 -- Subtract scene button row

    local IsRootNote, _ = PadModeHelper.getKeyboardModePadStates(PadIndex + 1, true) -- PadIndex is here 1-indexed
    local Selected = self.Strumming:isStrumPadAssigned(Column - 1, PadIndex)

    return IsRootNote or Selected, false, IsRootNote and not Selected and LEDColors.WHITE or Color, false, false

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:setFirstRowOffset(Offset)

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    self.FirstRowOffsets[GroupIndex] = Offset

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:getFirstRowOffset()

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    if self.FirstRowOffsets[GroupIndex] == nil then
        self.FirstRowOffsets[GroupIndex] = NotesPage.DEFAULT_FIRST_ROW_OFFSET
    end

    return self.FirstRowOffsets[GroupIndex]

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:onPadButton(Column, Row, Pressed)

    if Pressed then
        self.Strumming:toggleStrumPad(Column - 1, self:calcPadIndex(Row, Column))
    end

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:calcPadIndex(Row, Column)

    local RowTransformed = (8 - Row) + self:getFirstRowOffset()
    local C = (RowTransformed % 8) + 1
    local R = 9 - (math.floor(RowTransformed / 8) + 1)

    return JamControllerBase.PAD_BUTTONS[R][C]

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:onDPadButton(Button, Pressed)

    if not Pressed then
        return
    end

    local HandleDPad = (Button == NI.HW.BUTTON_DPAD_DOWN and self:canScrollDown())
        or (Button == NI.HW.BUTTON_DPAD_UP and self:canScrollUp())

    if HandleDPad then

        local NumNotesInOctave = self:getNumNotesInOctave()
        local Diff = (self.Controller:isShiftPressed() and NumNotesInOctave or 1)
            * (Button == NI.HW.BUTTON_DPAD_DOWN and -1 or 1)

        self:setFirstRowOffset(math.bound(self:getFirstRowOffset() + Diff, 0, self.MAX_NUM_NOTES_PER_ROW - 8))

     end

    PageJam.onDPadButton(self, Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:canScrollUp()

    return self:getFirstRowOffset() + self:getNumNotesInOctave() < self.MAX_NUM_NOTES_PER_ROW

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:canScrollDown()

    return self:getFirstRowOffset() > 0

end

------------------------------------------------------------------------------------------------------------------------

function NotesPage:updateDPadLEDs()

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, self:canScrollUp())
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, self:canScrollDown())
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_RIGHT, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_LEFT, false)

end

------------------------------------------------------------------------------------------------------------------------

