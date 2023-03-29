------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ClipHelper = class( 'ClipHelper' )

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.isClipEventInFocus(Group, ClipEvent)

    return Group and ClipEvent:isEventEqual(Group:getClipSequence():getFocusEvent())
               and NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
               and not ArrangerHelper.isIdeaSpaceFocused()

end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text

function ClipHelper.ClipStateFunctor(ButtonIndex, canAdd)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Group then

        local Index = ClipHelper.getClipIndex(ButtonIndex)
        local ClipEvent = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, Index)
        local Pattern = ClipEvent and ClipEvent:getEventPattern() or nil

        if Pattern then
            local HasFocus = ClipHelper.isClipEventInFocus(Group, ClipEvent)
            local Name = Pattern:getNameParameter():getValue()

            return true, true, false, HasFocus, Name
        elseif canAdd and Index == Group:getClipSequence():size() then
            return true, true, false, false, "+"
        end

    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.updateParameters(ParameterHandler)

    ParameterHandler:setCustomSection(1, "Clip")
    ParameterHandler:setCustomNames({"POSITION", "", "START", "LENGTH"})
    local Values = { ClipHelper.getFocusClipStartString(),
                     nil,
                     ClipHelper.getFocusClipStartString(),
                     ClipHelper.getFocusClipLengthString() }
    ParameterHandler:setCustomValues(Values)

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.updatePadLEDs(LEDs)

    local getFocusStateAndColor =
        function(ClipIndex)
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local Bank = Group and Group:getClipEventBankParameter():getValue() or 0
            local ClipEvent = Group and NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, ClipIndex) or nil
            local Pattern = ClipEvent and ClipEvent:getEventPattern() or nil

            local HasFocus = ClipEvent and ClipHelper.isClipEventInFocus(Group, ClipEvent)
            local Color = nil
            if Pattern then
                Color = Pattern:getColorParameter():getValue()
            elseif ClipIndex == Group:getClipSequence():size() then
                Color = LEDColors.WHITE
            end

            return HasFocus, Color
        end


    local SelectedEnabledFunctor =
        function(Index)
            local HasFocus, Color = getFocusStateAndColor(Index - 1)
            return HasFocus, Color ~= nil
        end

    local ColorFunctor =
        function(Index)
            local _, Color = getFocusStateAndColor(Index - 1)
            return Color
        end

    local CurrentBank = ClipHelper.getCurrentBank()

    if CurrentBank then
        LEDHelper.updateLEDsWithFunctor(LEDs, CurrentBank * 16, SelectedEnabledFunctor, ColorFunctor)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.getClipIndex(PadIndex)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local BankIndex = Group and Group:getClipEventBankParameter():getValue() or 0
    return BankIndex * 16 + PadIndex - 1

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.onClipPagePadEvent(PadIndex, Trigger, ErasePressed)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if not Trigger or not Group then
        return
    end

    local ClipIndex = ClipHelper.getClipIndex(PadIndex)
    local ClipEvent = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, ClipIndex)

    if ClipEvent then
        if ErasePressed then
            ClipHelper.deleteClipByIndex(ClipIndex)
        else
            NI.DATA.GroupAccess.setFocusClipEvent(App, Group, ClipEvent)
            NI.DATA.SongAccess.triggerScrollToFocusClip(App)
        end
    elseif ClipIndex == Group:getClipSequence():size() then
        ClipHelper.createClipAfterFocusClip()
        NI.DATA.SongAccess.triggerScrollToFocusClip(App)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.onClipPageLeftRightButton(Right, Pressed)

    if Pressed then
        NI.DATA.GroupAccess.shiftClipEventFocus(App, Right)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.createClipAfterFocusClip()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        NI.DATA.GroupAccess.createClipEvent(App, Group, Group:getClipSequence():getLength())
    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.createClipAtNextFreeTick(Tick)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        local CreateAtTick = NI.DATA.GroupAlgorithms.findNextTickNotInClip(Group, Tick)
        NI.DATA.GroupAccess.createClipEvent(App, Group, CreateAtTick)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.deleteClipByIndex(Index)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Clip = Group and NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, Index) or nil

    if Clip then
        NI.DATA.GroupAccess.removeClipEvent(App, Group, Clip)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.deleteFocusClip()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Clip = Group and Group:getClipSequence():getFocusEvent()

    if Clip then
        NI.DATA.GroupAccess.removeClipEvent(App, Group, Clip)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.deleteFocusBank()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Clip = Group and Group:getClipSequence():getFocusEvent()

    if Clip then
        local Bank = Group and Group:getClipEventBankParameter():getValue() or 0
        NI.DATA.GroupAccess.removeClipBank(App, Group, Bank)
    end
end

------------------------------------------------------------------------------------------------------------------------

-- returns bool, bool
function ClipHelper.hasPrevNextBank()
    local Prev = false
    local Next = false
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        local BankParameter = Group:getClipEventBankParameter()
        Prev = BankParameter:getMin() < BankParameter:getValue()
        Next = BankParameter:getMax() > BankParameter:getValue()
    end
    return Prev, Next
end

------------------------------------------------------------------------------------------------------------------------

-- returns (0-based bank index, 0-based num of banks) or (nil, nil) if no focused group
function ClipHelper.getCurrentBank()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        return Group:getClipEventBankParameter():getValue(), Group:getClipEventBankParameter():getMax()
    end
    return nil, nil
end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.shiftBank(Next)

    local AllowPrev, AllowNext = ClipHelper.hasPrevNextBank()

    if Next and AllowNext or not Next and AllowPrev then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            local BankParameter = Group:getClipEventBankParameter()
            local Inc = Next and 1 or -1

            NI.DATA.ParameterAccess.setSizeTParameter(App, BankParameter, BankParameter:getValue() + Inc)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.getFocusClipLengthString()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ClipEvent = NI.DATA.StateHelper.getFocusClipEvent(App)

    return ClipEvent and Song:getTickToString(NI.DATA.StateHelper.getFocusPatternLength(App)) or "-"
end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.getFocusClipStartString()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ClipEvent = NI.DATA.StateHelper.getFocusClipEvent(App)

    return ClipEvent and Song:getTickPositionToString(NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App)) or "-"
end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.getNumClipsInFocusedGroup()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getClipSequence():size() or nil

end

------------------------------------------------------------------------------------------------------------------------
-- Screen buttons 3, 4, 6, 7, 8 have clip functionality. (clip-related pages currently reached by ARRANGER/PATTERN)
------------------------------------------------------------------------------------------------------------------------

function ClipHelper.updateClipPageScreenButtons(Screen, ShiftPressed, ShowBankSelector)

    local FocusClip = NI.DATA.StateHelper.getFocusClipEvent(App)
    local HasClip = FocusClip ~= nil

    -- Showing rename as shift functionality is only available to non-desktop MASCHINE
    local ShowRename = NI.APP.isHeadless()

    -- Button 3 -- Double
    Screen.ScreenButton[3]:setText("DOUBLE")
    Screen.ScreenButton[3]:setVisible(not ShiftPressed)
    Screen.ScreenButton[3]:setEnabled(not ShiftPressed and HasClip and NI.DATA.GroupAccess.canDoubleClipEvent(App, FocusClip))

    -- Button 4 -- Duplicate
    Screen.ScreenButton[4]:setText("DUPLICATE")
    Screen.ScreenButton[4]:setVisible(not ShiftPressed)
    Screen.ScreenButton[4]:setEnabled(not ShiftPressed and HasClip)

    -- Button 5 -- Create / Rename
    if ShiftPressed and ShowRename then

        Screen.ScreenButton[5]:setText("RENAME")
        Screen.ScreenButton[5]:setEnabled(HasClip)
        Screen.ScreenButton[5]:setVisible(true)

    elseif ShiftPressed then

        Screen.ScreenButton[5]:setText("")
        Screen.ScreenButton[5]:setEnabled(false)
        Screen.ScreenButton[5]:setVisible(false)

    else

        Screen.ScreenButton[5]:setText("CREATE")
        Screen.ScreenButton[5]:setEnabled(true)
        Screen.ScreenButton[5]:setVisible(true)

    end

    -- Button 6 -- Delete / Delete Bank
    if ShiftPressed then

        Screen.ScreenButton[6]:setText("DEL BANK")

    else

        Screen.ScreenButton[6]:setText("DELETE")

    end

    Screen.ScreenButton[6]:setVisible(true)
    Screen.ScreenButton[6]:setEnabled(HasClip)

    -- prev/next clip banks
    local HasPrev, HasNext = ClipHelper.hasPrevNextBank()
    local BankIndex, _ = ClipHelper.getCurrentBank()
    if (ShowBankSelector and BankIndex) then
        Screen:setArrowText(1, "BANK "..tostring(BankIndex + 1))
    else
        Screen:unsetArrowText(1)
    end

     -- Button 7 -- Prev Clip Bank
    Screen.ScreenButton[7]:setVisible(ShowBankSelector)
    Screen.ScreenButton[7]:setEnabled(HasPrev)

    -- Button 8 -- Next Clip Bank
    Screen.ScreenButton[8]:setVisible(ShowBankSelector)
    Screen.ScreenButton[8]:setEnabled(HasNext)

end

------------------------------------------------------------------------------------------------------------------------
-- button handler for clip-related screen buttons (See updateClipPageScreenButtons above)
------------------------------------------------------------------------------------------------------------------------

function ClipHelper.onClipPageScreenButtonPressed(Idx, ShiftPressed, SupportBankSelector)

    local ShowRename = NI.APP.isHeadless()
    local FocusClip = NI.DATA.StateHelper.getFocusClipEvent(App)
    local Pattern = FocusClip and FocusClip:getEventPattern() or nil

    if Idx == 1 then

        -- switch to the Pattern Page (needs a song focus entity toggle)
        NI.DATA.ArrangerAccess.toggleSongFocusEntity(App)

    elseif Idx == 3 and not ShiftPressed and FocusClip then

        NI.DATA.GroupAccess.doubleClipEvent(App, FocusClip)

    elseif Idx == 4 and not ShiftPressed then

        NI.DATA.GroupAccess.duplicateFocusClipEvent(App)

    elseif Idx == 5 then

        if ShiftPressed and ShowRename and Pattern then

            local NameParam = Pattern:getNameParameter()
            MaschineHelper.openRenameDialog(NameParam:getValue(), NameParam)

        elseif not ShiftPressed then

            ClipHelper.createClipAfterFocusClip()

        end

    elseif Idx == 6 then

        if ShiftPressed then

            ClipHelper.deleteFocusBank()

        else

            ClipHelper.deleteFocusClip()

        end

    elseif (Idx == 7 or Idx == 8) and SupportBankSelector then

        ClipHelper.shiftBank(Idx == 8)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.onClipPageScreenEncoder(KnobIdx, EncoderInc, TransactionSequenceMarker, ShiftPressed, PositionParameterIndex)

    if MaschineHelper.onScreenEncoderSmoother(KnobIdx, EncoderInc, .1) == 0 then
        return
    end

    -- position parameter per default is on knob 1
    if not PositionParameterIndex then
        PositionParameterIndex = 1
    end

    if KnobIdx == PositionParameterIndex then

        TransactionSequenceMarker:set()

        NI.DATA.EventPatternAccess.changeFocusClipEventPosition(
            App, EncoderInc > 0 and 1 or -1, ShiftPressed)

    elseif KnobIdx == 3 then

        TransactionSequenceMarker:set()

        NI.DATA.EventPatternAccess.changeFocusClipEventStart(
            App, EncoderInc > 0 and 1 or -1, ShiftPressed)

    elseif KnobIdx == 4 then

        TransactionSequenceMarker:set()

        NI.DATA.EventPatternAccess.changeFocusClipEventLength(
            App, EncoderInc > 0 and 1 or -1, ShiftPressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipHelper.duplicateClip(SrcIndex, DstIndex)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local SrcClipEvent = Group and NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, SrcIndex) or nil

    if SrcClipEvent and DstIndex <= Group:getClipSequence():size() then
        local DstClipEvent = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, DstIndex)
        NI.DATA.GroupAccess.duplicateClipEventReplace(App, Group, SrcClipEvent, DstClipEvent)
    end
end

------------------------------------------------------------------------------------------------------------------------
