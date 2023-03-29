------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Components/Events4DWheel"
require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Maschine/Helper/NavigationHelper"
require "Scripts/Maschine/KompleteKontrolS2/Helper/ScenePatternHelper"

local ATTR_ZOOM_Y = NI.UTILS.Symbol("zoom-y")
local ATTR_MUTED = NI.UTILS.Symbol("Muted")
local ATTR_IDEA_SPACE = NI.UTILS.Symbol("IdeaSpace")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPageKKS2 = class( 'PatternPageKKS2', PageMaschine )

local NumPatternBanks = 0

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:__init(Controller)

    PageMaschine.__init(self, "PatternPage", Controller)

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    self.Screen = ScreenMaschineStudio(self)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton", false, true)
    self.Screen:styleScreenWithParameters(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton", false, true)

    self.Screen.ScreenRight.ParamBar:setActive(false)

    self.PageLEDs = {NI.HW.LED_PATTERN}

    self.Keyboard = NI.GUI.insertPianorollKeyboard(self.Screen.ScreenRight.DisplayBar, App, "Keyboard")
    self.Keyboard:setHWScreen()

    self.SoundList = NI.GUI.insertLabelVector(self.Screen.ScreenRight.DisplayBar,"SoundList")
    self.SoundList:style(false, '')
    self.SoundList:getScrollbar():setVisible(false)

    NI.GUI.connectVector(self.SoundList,
        function() return 16 end,
        function(Label) Label:style("", "SoundListItem") end,

        function(Label, Index)
            Label:setText(Index == NPOS and "" or tostring(Index+1))
            ColorPaletteHelper.setSoundColor(Label, Index+1)
            Label:setSelected(Index == NI.DATA.StateHelper.getFocusSoundIndex(App))

            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local ZoomedY = Group and Group:getPatternEditorVerticalZoomParameterHW():getValue() ~= 0
            Label:setAttribute(ATTR_ZOOM_Y, ZoomedY and "true" or "false")
        end)

    -- Setup Arranger Widgets
    self.Arranger = self.Controller.SharedObjects.PatternEditor
    self.ArrangerOverview = self.Controller.SharedObjects.PatternEditorOverview

    self.Screen.ScreenLeft.InfoBar:setMode("Group")
    self.Screen.ScreenRight.InfoBar:setMode("Sound")

    self.PatternBank = 0
    self.ShiftFunctionsDiscard = false

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:updateWheelButtonLEDs()

    -- handled

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onControllerTimer()

    Events4DWheel.onControllerTimer(self.Controller, not MaschineHelper.isDrumkitMode())

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()
        self.ArrangerOverview:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.Arranger:insertInto(self.Screen.ScreenRight.DisplayBar, true)
        self.ArrangerOverview.Editor:setOverviewSource(self.Arranger.Editor)
    end

    self.Keyboard:setActive(not MaschineHelper.isDrumkitMode())
    self.Controller.CapacitiveNavIcons:Enable(Show, true)

    -- call base
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:updateScreens(ForceUpdate)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self.Keyboard:setActive(not MaschineHelper.isDrumkitMode())
    self.SoundList:setActive(MaschineHelper.isDrumkitMode())

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if FocusGroup and NI.DATA.ParameterCache.isValid(App) and App:getStateCache():isFocusPatternChanged() then

        local FocusPatternIndex = PatternHelper.getFocusPatternIndexNoGaps()
        self.PatternBank =  FocusPatternIndex and math.ceil(FocusPatternIndex / 8) - 1 or 0
    end

    if ForceUpdate or
        (MaschineHelper.isDrumkitMode() and NI.DATA.ParameterCache.isValid(App) and
            (App:getStateCache():isFocusSoundChanged() or
                (FocusGroup and FocusGroup:getPatternEditorVerticalZoomParameterHW():isChanged()))) then

        local FocusedSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)
        self.SoundList:setFocusItem(FocusedSoundIndex)
        self.Arranger.Editor:getVector():setFocusItem(FocusedSoundIndex)

        self.SoundList:setAlign()
    end

    if self.Controller:getShiftPressed() and not self.ShiftFunctionsDiscard then
        self:updateScreenButtonsShift()
    else
        self:updateScreenButtonsNoShift()
    end

    if not self.Controller:getShiftPressed() then
        self.ShiftFunctionsDiscard = false
    end

    -- update arrangers
    self.Arranger:update(ForceUpdate)
    self.ArrangerOverview:update(ForceUpdate)

    -- update overlay icons
    local HasPattern = NI.DATA.StateHelper.getFocusEventPattern(App) ~= nil
    self.Controller.CapacitiveNavIcons:Enable(HasPattern, not MaschineHelper.isDrumkitMode(), nil,
                                              MaschineHelper.isDrumkitMode())
    self:updateCapacitiveNavIcons()

    PageMaschine.updateScreens(self, ForceUpdate)

    NumPatternBanks = math.ceil((#PatternHelper.getFocusedGroupPatternList() + 1) / 8)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, self.PatternBank > 0)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT,
                              self.PatternBank < (NumPatternBanks - 1))

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:updateScreenButtonsShift()

    for Index = 1, 8 do
        self.Screen.ScreenButton[Index]:setVisible(Index >= 2 and Index <= 6)
        self.Screen.ScreenButton[Index].Color = nil
        self.Screen.ScreenButton[Index]:setPaletteColorIndex(0)
        self.Screen.ScreenButton[Index]:setSelected(false)
        self.Screen.ScreenButton[Index]:style("", "HeadButton")
    end

    local ClipsInFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local FocusPattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    self.Screen.ScreenButton[2]:setText("REMOVE")
    self.Screen.ScreenButton[2]:setVisible(not ClipsInFocus)
    self.Screen.ScreenButton[2]:setEnabled(FocusPattern ~= nil)

    self.Screen.ScreenButton[3]:setText("DOUBLE")
    self.Screen.ScreenButton[3]:setEnabled(FocusPattern ~= nil)

    self.Screen.ScreenButton[4]:setText("DUPLICATE")
    self.Screen.ScreenButton[4]:setEnabled(FocusPattern ~= nil)

    self.Screen.ScreenButton[5]:setText("INSERT")
    self.Screen.ScreenButton[5]:setEnabled(true)

    self.Screen.ScreenButton[6]:setText("DELETE")
    self.Screen.ScreenButton[6]:setEnabled(FocusPattern ~= nil)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:updateScreenButtonsNoShift()

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if FocusGroup and NI.DATA.ParameterCache.isValid(App) and App:getStateCache():isFocusPatternChanged() then

        local FocusPatternIndex = PatternHelper.getFocusPatternIndexNoGaps()
        self.PatternBank =  FocusPatternIndex and math.ceil(FocusPatternIndex / 8) - 1 or 0
    end


    local PatternList, FocusPattern = PatternHelper.getFocusedGroupPatternList()

    for Index = 1, 8 do

        local PatternIndex = Index + self.PatternBank * 8

        local Pattern = PatternList[PatternIndex]

        self.Screen.ScreenButton[Index].Pattern = Pattern
        self.Screen.ScreenButton[Index]:setVisible(Pattern ~= nil)

        if FocusGroup and PatternIndex == #PatternList + 1 then

            self.Screen.ScreenButton[Index]:setVisible(true)
            self.Screen.ScreenButton[Index]:setEnabled(true)
            self.Screen.ScreenButton[Index].Color = nil
            self.Screen.ScreenButton[Index]:setPaletteColorIndex(0)
            self.Screen.ScreenButton[Index]:setSelected(false)
            self.Screen.ScreenButton[Index]:style("+", "HeadButton")

        elseif Pattern then

            local Name = Pattern:getNameParameter():getValue()

            self.Screen.ScreenButton[Index]:setVisible(true)
            self.Screen.ScreenButton[Index]:setEnabled(true)
            self.Screen.ScreenButton[Index]:style(Name, "HeadPattern")
            self.Screen.ScreenButton[Index]:setAttribute(ATTR_MUTED, FocusGroup:getMuteParameter():getValue() and "true" or "false")
            self.Screen.ScreenButton[Index]:setAttribute(ATTR_IDEA_SPACE, "true")

            local Color = Pattern:getColorParameter():getValue()
            self.Screen.ScreenButton[Index].Color = Color
            self.Screen.ScreenButton[Index]:setPaletteColorIndex(Color == nil and 0 or (Color + 1))

            self.Screen.ScreenButton[Index]:setSelected(ScenePatternHelper.isModeAndViewInSync() and Pattern == FocusPattern)

        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:updateLEDs()

    local HasEvents = MaschineHelper.isDrumkitMode() and ActionHelper.hasGroupEvents() or ActionHelper.hasSoundEvents()
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_CLEAR, NI.HW.BUTTON_CLEAR, HasEvents)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:updateParameters(ForceUpdate)

    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
    local SoundName = FocusSound and FocusSound:getDisplayName() or ""

    local ClipsInFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    self.ParameterHandler:setCustomSections({"Sound", ClipsInFocus and "Clip" or "Pattern"})
    self.ParameterHandler:setCustomNames({"SELECT", "POSITION", "START", "LENGTH"})
    self.ParameterHandler:setCustomValues({
        SoundName,
        ClipsInFocus and ClipHelper.getFocusClipStartString() or PatternHelper.startString(),
        ClipsInFocus and ClipHelper.getFocusClipStartString() or PatternHelper.startString(),
        ClipsInFocus and ClipHelper.getFocusClipLengthString() or PatternHelper.lengthString()
    })

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onScreenEncoder(Idx, Inc)

    local ValueChanged = false

    if not self.Controller.SpeechAssist:isTrainingMode() then

        self:onZoomScrollEncoder(Idx, Inc)

        local DirectionPlusOrMinusOne = Inc > 0 and 1 or -1
        local Fine = self.Controller:getShiftPressed()

        if Idx == 1 then
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            if Group and MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
                NI.DATA.GroupAccess.shiftSoundFocus(App, Group, DirectionPlusOrMinusOne, false, false)
            end
            return
        end

        local ClipsInFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
        if ClipsInFocus then
            ClipHelper.onClipPageScreenEncoder(Idx, Inc, self.TransactionSequenceMarker, Fine, 2)
            ValueChanged = true
        else

            local RangeHandlers = {
                [2] = function (Pattern, Direction, Fine) NI.DATA.EventPatternAccess.incrementPosition(App, Pattern, Direction, Fine) end,
                [3] = function (Pattern, Direction, Fine) NI.DATA.EventPatternAccess.incrementStart(App, Pattern, Direction, Fine) end,
                [4] = function (_, Direction, Fine) PatternHelper.incrementPatternLength(Direction, Fine) end,
            }

            if RangeHandlers[Idx] ~= nil and not Fine and MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) == 0 then
                return
            end

            if RangeHandlers[Idx] ~= nil then
                local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
                if Pattern then
                    RangeHandlers[Idx](Pattern, DirectionPlusOrMinusOne, Fine)
                    ValueChanged = true
                end

            end
        end
    end

    self.Controller.SpeechAssist:onEncoderEvent(Idx, ValueChanged)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onZoomScrollEncoder(Idx, Inc)

    if Idx == 5 then -- ZOOM (HORZ)

        self.Arranger:zoom(Inc)

    elseif Idx == 6 then -- SCROLL (HORZ)

        self.Arranger:scroll(Inc)

    elseif Idx == 7 then -- ZOOM (VERT)

        local HasPattern = NI.DATA.StateHelper.getFocusEventPattern(App) ~= nil
        if HasPattern and MaschineHelper.isDrumkitMode() then
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local VertZoomParam = Group and Group:getPatternEditorVerticalZoomParameterHW()
            NavigationHelper.incrementEnumParameter(VertZoomParam, Inc >= 0 and 1 or -1)
            self:updateCapacitiveNavIcons()
        end

    elseif Idx == 8 then -- SCROLL (VERT)

        if PadModeHelper.getKeyboardMode() then
            self.Arranger:scrollPianoroll(Inc)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onLeftRightButton(Right, Pressed)

    if Pressed then
        self.PatternBank = math.bound(self.PatternBank + (Right and 1 or -1), 0, NumPatternBanks - 1)
    end
end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onScreenButton(Idx, Pressed)

    if not Pressed then
        return
    end

    if not self.Controller.SpeechAssist:isTrainingMode() then

        local ClipsInFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

        if self.Controller:getShiftPressed() and not self.ShiftFunctionsDiscard then

            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            if (not ClipsInFocus and Idx == 2) or Idx == 4 or (Group and Idx == 5) or Idx == 6 then
                self.ShiftFunctionsDiscard = true
            end

            if ClipsInFocus then

                ClipHelper.onClipPageScreenButtonPressed(Idx)

            else

                if Idx == 2 then
                    PatternHelper.removeFocusPattern()
                elseif Idx == 3 then
                    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
                    if Pattern then
                        NI.DATA.EventPatternAccess.doublePattern(App, Pattern)
                    end
                elseif Idx == 4 then
                    PatternHelper.duplicatePattern()
                elseif Idx == 5 then
                    if Group then
                        NI.DATA.GroupAccess.insertPattern(App, Group, NI.DATA.StateHelper.getFocusEventPattern(App))
                    end    
                elseif Idx == 6 then
                    PatternHelper.deletePatternOrBank(false)
                end

            end

        else

            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            if Group ~= nil then
                if self.Screen.ScreenButton[Idx].Pattern then
                    if ClipsInFocus then
                        local ClipEvent = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, Idx + self.PatternBank * 8 - 1)
                        if ClipEvent then
                            NI.DATA.GroupAccess.setFocusClipEvent(App, Group, ClipEvent)
                        end
                    else
                        NI.DATA.GroupAccess.insertPatternAndFocus(App, Group, self.Screen.ScreenButton[Idx].Pattern)
                    end
                elseif Idx + self.PatternBank * 8 == #PatternHelper.getFocusedGroupPatternList() + 1 then
                    if ClipsInFocus then
                        ClipHelper.createClipAfterFocusClip()
                    else
                        NI.DATA.GroupAccess.insertPattern(App, Group, nil)
                    end
                end
            end
        end

        PageMaschine.onScreenButton(self, Idx, Pressed)

    end

    local isButtonDisabled = not self.Screen.ScreenButton[Idx]:isEnabled()
    self.Controller.SpeechAssist:onScreenButton(Idx, self, isButtonDisabled)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onClear(Pressed)

    if Pressed then
        local ClearSelectedNotes = NI.DATA.EventPatternTools.getNumSelectedNoteEventsInPatternRange(App) > 0

        if MaschineHelper.isDrumkitMode() then

            if ClearSelectedNotes then
                NI.DATA.EventPatternTools.removeNoteAndAudioEvents(App)
            else
                NI.DATA.EventPatternTools.removeAllEventsFromGroup(App)
            end
        else
            if ClearSelectedNotes then
                NI.DATA.EventPatternTools.removeNoteAndAudioEventsFromFocusedSound(App)
            else
                NI.DATA.EventPatternTools.removeAllEventsFromFocusedSound(App)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onWheelDirection(Pressed, Button)

    Events4DWheel.onWheelDirection(self.Controller, Pressed, not MaschineHelper.isDrumkitMode())

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:onWheel(Value)

    if not self.Controller:getShiftPressed() then
        Events4DWheel.onWheel(self.Controller, Value)
        return true
    end
end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:updateCapacitiveNavIcons()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local VertZoomParam = Group and Group:getPatternEditorVerticalZoomParameterHW()

    if VertZoomParam then
        self.Controller.CapacitiveNavIcons:updateIconForVerticalZoom(VertZoomParam:getValue())
    end
end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:getScreenEncoderInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""

    if Index == 1 then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)

        Info.SpeechSectionName = "Sound,"
        Info.SpeechName = "Select"
        Info.SpeechValue = Sound:getDisplayName()
    elseif Index == 2 then
        Info.SpeechSectionName = "Pattern"
        Info.SpeechName = "Position"
        Info.SpeechValue = PatternHelper.startString()

    elseif Index == 3 then
        Info.SpeechSectionName = "Pattern"
        Info.SpeechName = "Start"
        Info.SpeechValue = PatternHelper.startString()
    elseif Index == 4 then
        local Length = NI.DATA.StateHelper.getFocusPatternLength(App)
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song and Length then
            local TickString = Song:getTickToString(Length) or ""
            Info.SpeechSectionName = "Pattern"
            Info.SpeechName = "Length"
            Info.SpeechValue = TickString
        end
    elseif Index == 5 then
        Info.SpeechName = "Horizontal Zoom"
    elseif Index == 6 then
        Info.SpeechName = "Horizontal Scroll"
    elseif Index == 8 then
        Info.SpeechName = "Vertical Zoom"
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:getScreenButtonInfo(Index)

    local Info = PageMaschine.getScreenButtonInfo(self, Index)
    if Info == nil then return end

    Info.SpeakNameInNormalMode = true
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    if Info.SpeechName == "+" then
        Info.SpeechName = "Create Pattern"
        Info.SpeakValueInTrainingMode = false
        Info.SpeakValueInNormalMode = false
    end


    if self.Controller:getShiftPressed() then
        -- Action buttons should have an object, e.g. "Insert Pattern"
        Info.SpeechName = Info.SpeechName .. " Pattern"
        Info.SpeakValueInNormalMode = false
        Info.SpeakValueInTrainingMode = false
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageKKS2:getCurrentPageSpeechAssistanceMessage(Right)
    local DirectionString = Right and "Right" or "Left"
    local Msg = DirectionString

    local PatternList, FocusPattern = PatternHelper.getFocusedGroupPatternList()
    local PatternIndex = 0 + self.PatternBank * 8
    local Pattern = PatternList[PatternIndex + 1]
    if Pattern then
        Msg = Msg .. " to " .. AccessibilityTextHelper.getPatternName(Pattern:getNameParameter():getValue())
    end

    return Msg
end

------------------------------------------------------------------------------------------------------------------------
