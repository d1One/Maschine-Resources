require "Scripts/Shared/Helpers/MiscHelper"
require 'math'
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerHelper = class( 'ArrangerHelper' )

------------------------------------------------------------------------------------------------------------------------
-- Consts and class vars
------------------------------------------------------------------------------------------------------------------------

ArrangerHelper.PadSectionIndex = {}

------------------------------------------------------------------------------------------------------------------------
-- scene state functor for the on-screen button states
-- Functor: Visible, Enabled, Selected, Focused, Text
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.SceneStateFunctor(ButtonIndex, CanAdd, HideFocus)  -- 1-indexed

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then

        local Index = ArrangerHelper.getSceneIndexFromPadIndex(ButtonIndex)
        local Scene = Song:getScenes():at(Index)

        if Scene then

            local HasFocus = not HideFocus and Scene == NI.DATA.StateHelper.getFocusScene(App)
            local Name = Scene:getNameParameter():getValue()

            return true, true, HasFocus, HasFocus, Name

        elseif CanAdd and Index == Song:getScenes():size() then     -- "+" button

            return true, true, false, false, "+"
        end
    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------
-- section state functor for the on-screen button states
-- Functor: Visible, Enabled, Selected, Focused, Text
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.SectionStateFunctor(ButtonIndex, IncludeLoopInfo)

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local Index = Song:getFocusSectionBankIndexParameter():getValue() * NI.UTILS.CONST_SCENES_PER_BANK +
                          ButtonIndex - 1
        local Section = Song:getSections():find(Index)

        if Section then
            local IsSectionPartOfLoop = NI.DATA.SongAlgorithms.isSectionPartOfLoop(Song, Section) and
                not ArrangerHelper.isIdeaSpaceFocused()
            local HasFocus = (Section == NI.DATA.StateHelper.getFocusSection(App))
            local Name = NI.DATA.SectionAlgorithms.getName(Section)

            return true, true, IncludeLoopInfo and IsSectionPartOfLoop, HasFocus, Name
        end
    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.duplicateScene(SrcIndex, DstIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scene = nil

    if Song then

        if SrcIndex == nil then -- default is the focused Scene
            Scene = NI.DATA.StateHelper.getFocusScene(App)
        else
            Scene = Song:getScenes():at(SrcIndex)
        end

        if Scene and DstIndex <= Song:getScenes():size() then

            return NI.DATA.IdeaSpaceAccess.duplicateSceneReplace(App, Song, Scene, DstIndex)

        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.duplicateSection(SrcIndex, DstIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Section = nil

    if Song then

        if SrcIndex == nil then -- default is the focused Section
            Section = NI.DATA.StateHelper.getFocusSection(App)
        else
            Section = Song:getSections():find(SrcIndex)
        end

        if Section then
            if DstIndex then
                NI.DATA.SongAccess.duplicateSectionReplace(App, Song, Section, DstIndex, false)
            else
                NI.DATA.SongAccess.duplicateSection(App, Song, Section)
            end
            return true
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.makeSectionSceneUnique()

    local Song       = NI.DATA.StateHelper.getFocusSong(App)
    local Section    = NI.DATA.StateHelper.getFocusSection(App)

    if Song and Section then

            NI.DATA.SongAccess.makeSectionSceneUnique(App, Song, Section)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.removeFocusedSceneOrBank(ShiftPressed)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if ShiftPressed then

        -- remove the whole scene bank if shift-delete is pressed
        if Song and ArrangerHelper.isIdeaSpaceFocused() then
            NI.DATA.IdeaSpaceAccess.removeFocusSceneBank(App, Song)
            return true
        end

    else

        local Scene = NI.DATA.StateHelper.getFocusScene(App)

        if Song and Scene then
            NI.DATA.IdeaSpaceAccess.removeScene(App, Song, Scene)
            return true
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.removeFocusedSectionOrBank(ShiftPressed)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if ShiftPressed then

        -- remove the whole section bank if shift-delete is pressed
        if Song and not ArrangerHelper.isIdeaSpaceFocused() then
            NI.DATA.SongAccess.removeSectionBank(App, Song, Song:getFocusSectionBankIndexParameter():getValue())
            return true
        end

    else

        local Section = NI.DATA.StateHelper.getFocusSection(App)

        if Song and Section then
            NI.DATA.SongAccess.removeSection(App, Song, Section)
            return true
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.onPadEventIdeas(PadIndex, Pressed, ErasePressed, CreateSceneIfEmpty, AppendMode)

    if Pressed then
        local Index = ArrangerHelper.getSceneIndexFromPadIndex(PadIndex)
        local Song = NI.DATA.StateHelper.getFocusSong(App)

        if ErasePressed then
            ArrangerHelper.removeSceneByIndex(Index)

        elseif AppendMode then
            local Scene = Song and Song:getScenes():at(Index)
            if Scene then
                NI.DATA.SongAccess.createSectionWithScene(App, Song, -1, Scene, false)
            end

        else
            if Song and CreateSceneIfEmpty and Index == Song:getScenes():size() then
                NI.DATA.IdeaSpaceAccess.createScene(App, Song)
            end
            -- Actual Scene Switch is done via NHL event -> RT event
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.onPadEventSections(PadIndex, Pressed, ErasePressed, CreateSectionIfEmpty)

    -- Section mode handler
    local Index = ArrangerHelper.getSectionIndexFromPadIndex(PadIndex)

    ArrangerHelper.PadSectionIndex[PadIndex] = (Pressed and not ErasePressed) and Index or nil

    if NHLController:getPadMode() == NI.HW.PAD_MODE_SECTION then

        if Pressed then
            if ErasePressed then
                ArrangerHelper.removeSectionByIndex(Index)
            elseif not ErasePressed then
                if CreateSectionIfEmpty then
                    NI.DATA.ArrangerAccess.createSectionIfKeyUnused(App, Index)
                end
                -- Actual Section Switch is done via NHL event -> RT event
            end
        end

    else

        if Pressed then
            -- focus section and set loop
            local Min, Max = ArrangerHelper.getMinMaxSectionIndexFromHoldingPads()

            if Index ~= nil and Min ~= nil and Max ~= nil then
                NI.DATA.ArrangerAccess.focusSectionAndSetLoop(App, Index, Min, Max)
            end
        end

    end

    -- looks hacky at best
    if ArrangerHelper.getHoldingPadsSize() > 0 then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.resetHoldingPads()

    MiscHelper.resetTable(ArrangerHelper.PadSectionIndex)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getHoldingPadsSize()

    return MiscHelper.getTableSize(ArrangerHelper.PadSectionIndex)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getMinMaxSectionIndexFromHoldingPads()

    return MiscHelper.getMinMaxFromTable(ArrangerHelper.PadSectionIndex)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.swapFocusedSection(Inc)

    NI.DATA.SongAccess.swapFocusedSection(App, Inc > 0)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.updatePadLEDsIdeaSpace(Controller, AppendMode)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local CanAdd = not AppendMode
        local BaseIndex = Song:getFocusSceneBankIndexParameter():getValue() * NI.UTILS.CONST_SCENES_PER_BANK

        -- update pad leds with focus state
        LEDHelper.updateLEDsWithFunctor(Controller.PAD_LEDS,
            BaseIndex,
            function (Index) return MaschineHelper.isSceneFocusByIndex(Index, CanAdd, AppendMode) end,
            function (Index) return MaschineHelper.getIdeaSpaceSceneColorByIndex(Index, CanAdd) end)

        -- update pressed pad led in append mode
        if AppendMode then
            for PadIndex, LedID in ipairs (Controller.PAD_LEDS) do
                if Controller.CachedPadStates[PadIndex] then
                    local Index = BaseIndex + PadIndex
                    LEDHelper.updateLedState(LedID, true, true, MaschineHelper.getIdeaSpaceSceneColorByIndex(Index, false))
                end
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.updatePadLEDsSections(LEDs)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        -- update pad leds with focus state
        LEDHelper.updateLEDsWithFunctor(LEDs,
            Song:getFocusSectionBankIndexParameter():getValue() * NI.UTILS.CONST_SCENES_PER_BANK,
            MaschineHelper.isSectionSelectedByIndex,
            MaschineHelper.getSectionSceneColorByIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Regular Scroll / Zoom
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.scrollArranger(EncoderInc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local PixelPerBeat = Song:getArrangerZoomParameterHW():getValue()
        local Delta        = EncoderInc * 10000.0 / PixelPerBeat

        NI.DATA.ScrollingAccess.scrollArrangerTimeHW(App, Song, Delta)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.zoomArranger(EncoderInc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local ZoomParameter = Song:getArrangerZoomParameterHW()

        local PixelPerBeat  = ZoomParameter:getValue()
        local Delta
        if _VERSION == "Lua 5.1" then
            Delta = math.pow(1.06, EncoderInc * 100.0 )
        else
            Delta = 1.06 ^ (EncoderInc * 100.0)
        end
        PixelPerBeat        = PixelPerBeat * Delta;

        NI.DATA.ParameterAccess.setDoubleParameterNoUndo(App, ZoomParameter, PixelPerBeat)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Scrolls Arranger and Restrict to Sequence length
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.scrollArrangerBound(EncoderInc, SeqLength, ViewLength)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil or SeqLength == 0 then
        return 0
    end

    local CurrentOffset = Song:getArrangerOffsetParameterHW():getValue()
    local Delta = math.bound(EncoderInc * ViewLength, -CurrentOffset, SeqLength - CurrentOffset - ViewLength)

    if Delta ~= 0 then
        NI.DATA.ScrollingAccess.scrollArrangerTimeHW(App, Song, Delta)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.scrollPatternEditorBound(EncoderInc, SeqLength, ViewLength)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil or SeqLength == 0 then
        return 0
    end

    local PatternEditorOffsetParameter = NI.DATA.StateHelper.getPatternEditorOffsetParameter(App, true)
    if not PatternEditorOffsetParameter then
        return 0
    end

    local CurrentOffset = PatternEditorOffsetParameter:getValue()
    local Delta = math.bound(EncoderInc * ViewLength, -CurrentOffset, SeqLength - CurrentOffset - ViewLength)

    if Delta ~= 0 then
        NI.DATA.ScrollingAccess.scrollPatternEditorTimeHW(App, Delta)
    end

    return math.floor(CurrentOffset + Delta)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.scrollClipEditorBound(EncoderInc, SeqLength, ViewLength)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil or SeqLength == 0 then
        return 0
    end

    local CurrentOffset = Song:getClipEditorOffsetParameterHW():getValue()
    local Delta = math.bound(EncoderInc * ViewLength, -CurrentOffset, SeqLength - CurrentOffset - ViewLength)

    if Delta ~= 0 then
        NI.DATA.ScrollingAccess.scrollClipEditorHW(App, Song, Delta)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Zooms Arranger, Restrict to Sequence length and Focuses on a Tick
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.zoomArrangerLeftAlign(EncoderInc, Song, SeqLength, OffsetParameter, ZoomParameter, ViewWidth, TicksPerPixel)

    if SeqLength == 0 or OffsetParameter == nil or ZoomParameter == nil then
        return
    end

    local Zoom  = ZoomParameter:getValue()

    local Delta
    if _VERSION == "Lua 5.1" then
        Delta = math.pow(1.06, EncoderInc * 80.0 )
    else
        Delta = 1.06 ^ (EncoderInc * 80.0)
    end

    -- calc 'max' zoom (1 beat fills the screen) and leave if we're already maxed
    local ZoomMax = math.min((ViewWidth * TicksPerPixel) / Song:getTicksPerBeat(), ZoomParameter:getMax())
    if Delta > 1 and Zoom == ZoomMax then
        return
    end

    -- calc 'min' zoom
    local ZoomMin = (ViewWidth * TicksPerPixel) / SeqLength

    Zoom = Zoom * Delta;

    -- cap zoom
    Zoom = math.bound(Zoom, ZoomMin, ZoomMax)

    if EncoderInc ~= 0 then
	    NI.DATA.ParameterAccess.setDoubleParameterNoUndo(App, ZoomParameter, Zoom)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Zoom Pattern Editor
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.zoomPatternEditorLeftAlign(EncoderInc, Song, SeqLength, ViewWidth, TicksPerPixel)

    local OffsetParameter = NI.DATA.StateHelper.getPatternEditorOffsetParameter(App, true)
    local ZoomParameter = NI.DATA.StateHelper.getPatternEditorZoomParameter(App, true)

    ArrangerHelper.zoomArrangerLeftAlign(EncoderInc, Song, SeqLength, OffsetParameter, ZoomParameter, ViewWidth, TicksPerPixel)

    if OffsetParameter and ZoomParameter and EncoderInc ~= 0 then

		-- right-align zoom if Parameter Offset < Focus Offset
        local PatternEditorFocusOffsetParameterHW = Song:getPatternEditorFocusOffsetParameterHW()

        local FocusOffset = PatternEditorFocusOffsetParameterHW
            and PatternEditorFocusOffsetParameterHW:getValue()
            or 0

        if OffsetParameter:getValue() < FocusOffset then

			local NewOffset = SeqLength - ViewWidth * TicksPerPixel / ZoomParameter:getValue()

			if NewOffset < FocusOffset then
				FocusOffset = NewOffset
			end

			NI.DATA.ParameterAccess.setTickParameterNoUndo(App, OffsetParameter, FocusOffset)
		end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.zoomPatternEditor(EncoderInc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil then
        return
    end

    local ZoomParameter = NI.DATA.StateHelper.getPatternEditorZoomParameter(App, true)

    if ZoomParameter then
        local PixelPerBeat  = ZoomParameter:getValue()
        local Delta
        if _VERSION == "Lua 5.1" then
            Delta = math.pow(1.06, EncoderInc * 100.0 )
        else
            Delta = 1.06 ^ (EncoderInc * 100.0)
        end
        PixelPerBeat        = PixelPerBeat * Delta;

        NI.DATA.ParameterAccess.setDoubleParameterNoUndo(App, ZoomParameter, PixelPerBeat)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getSceneIndexFromPadIndex(PadIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        -- make 0-indexed
        return Song:getFocusSceneBankIndexParameter():getValue() * NI.UTILS.CONST_SCENES_PER_BANK + PadIndex - 1
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getSectionIndexFromPadIndex(PadIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        -- make 0-indexed
        return Song:getFocusSectionBankIndexParameter():getValue() * NI.UTILS.CONST_SCENES_PER_BANK + PadIndex - 1
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.insertSectionAfterFocused()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        NI.DATA.ArrangerAccess.insertSection(App, Song, NI.DATA.StateHelper.getFocusSection(App))
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.focusScene(Scene, ForceFocus)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return
    end

    if Scene then
        if ForceFocus then
            NI.DATA.IdeaSpaceAccess.focusScene(App, Song, Scene)
        end
        -- handled through RT events.
    else
        NI.DATA.IdeaSpaceAccess.createScene(App, Song)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.focusSectionByIndex(Index, CreateIfNull, ForceFocus, Scene)

    if Index == nil or Index < 0 then
		return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Section = Song and Song:getSections():find(Index) or nil

    if Section then
        if ForceFocus then
            NI.DATA.SongAccess.focusSection(App, Song, Section)
        else
            -- focus action is done in RT::SequenceProcessor (event pushed in MaschineControllerBase::processPadEvent())
        end

    elseif Song and CreateIfNull then
        -- create a section that isn't there yet
        NI.DATA.SongAccess.createEmptySection(App, Song, Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.removeSceneByIndex(Index)

    if Index == nil or Index < 0 then
        return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scene = Song and Song:getScenes():at(Index)

    if Song and Scene then
        NI.DATA.IdeaSpaceAccess.removeScene(App, Song, Scene)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.removeSectionByIndex(Index)

    if Index == nil or Index < 0 then
        return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Section = Song and Song:getSections():find(Index)

    if Song and Section then
        NI.DATA.SongAccess.removeSection(App, Song, Section)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.setPrevNextSceneBank(Next)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local FocusSceneBank = Song:getFocusSceneBankIndexParameter():getValue()
        local MaxSceneBank = math.floor(Song:getScenes():size() / NI.UTILS.CONST_SCENES_PER_BANK)
        local SceneBank = math.bound(Next and FocusSceneBank + 1 or FocusSceneBank - 1, 0, MaxSceneBank)
        NI.DATA.ParameterAccess.setSizeTParameter(App, Song:getFocusSceneBankIndexParameter(), SceneBank)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.hasPrevNextSceneBanks()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local MaxSceneBank = math.floor(Song and Song:getScenes():size() / NI.UTILS.CONST_SCENES_PER_BANK or 0)
    local HasPrev, HasNext =
        Song and (Song:getFocusSceneBankIndexParameter():getValue() > 0) or false,
        Song and (Song:getFocusSceneBankIndexParameter():getValue() < MaxSceneBank) or false

    return HasPrev, HasNext

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.hasPrevNextScene()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    local HasPrev = false
    local HasNext = false

    if Song then

        HasPrev = NI.DATA.IdeaSpaceAccess.canShiftFocusedScene(Song, false)
        HasNext = NI.DATA.IdeaSpaceAccess.canShiftFocusedScene(Song, true)

    end

    return HasPrev, HasNext

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.setPrevNextSectionBank(Next)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local SectionIdx = Song:getFocusSectionBankIndexParameter():getValue()
        local NumBanks = Song:getNumSectionBanksParameter():getValue()

        if SectionIdx+1 == NumBanks and Next and ArrangerHelper.canAddSectionBank() then
            NI.DATA.SongAccess.addSectionBank(App, Song)
            return true

        elseif (Next and SectionIdx < NumBanks-1) or (not Next and SectionIdx > 0) then
            local NewPageIdx = SectionIdx + (Next and 1 or -1)
            NI.DATA.ParameterAccess.setSizeTParameter(App, Song:getFocusSectionBankIndexParameter(), NewPageIdx)
            return true
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.hasPrevNextSectionBanks()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local FocusBankIdx = Song and Song:getFocusSectionBankIndexParameter():getValue() or 0 -- 0-indexed
    local NumBanks  = Song and Song:getNumSectionBanksParameter():getValue() or 0

    return FocusBankIdx >= 1, FocusBankIdx+1 < NumBanks

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.canAddSectionBank()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local NumBanks = Song:getNumSectionBanksParameter():getValue()
        local FocusBankIdx = Song:getFocusSectionBankIndexParameter():getValue()

        if FocusBankIdx+1 == NumBanks then -- focused bank must be the last one
            local Sections = Song:getSections()
            for Idx = FocusBankIdx*NI.UTILS.CONST_SCENES_PER_BANK,
                      (FocusBankIdx*NI.UTILS.CONST_SCENES_PER_BANK) + NI.UTILS.CONST_SCENES_PER_BANK do
                if Sections:find(Idx) then
                    return true -- bank is not empty, so adding a bank is allowed
                end
            end
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.hasPrevNextSection(Next)

    local Song    = NI.DATA.StateHelper.getFocusSong(App)
    local Section = NI.DATA.StateHelper.getFocusSection(App)
    if Song and Section then
        local Sections = Song:getSections()

        if Next then
            return Sections:getNext(Section) ~= nil
        else
            return Sections:getPrev(Section) ~= nil
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.focusPrevNextSection(Next)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then

        NI.DATA.SongAccess.shiftSectionFocus(App, Song, Next)

    end

end


------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getFocusedSectionSongPosAsString()

    local PosString = "-"

    local Pos = NI.DATA.ArrangerAccess.getFocusedSectionSongPos(App)
    if Pos ~= NPOS then
        PosString = "#" .. tostring(Pos + 1)
    end

    return PosString

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getFocusSectionLengthString()

    local LengthString = "-"

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Section = NI.DATA.StateHelper.getFocusSection(App)

    if Song and Section then
        if Section:getAutoLengthParameter():getValue() then
            LengthString = "Auto"
        else
            LengthString = Song:getTickToString(NI.DATA.SongAlgorithms.getSectionLength(Song, Section))
        end
    end

    return LengthString

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.incrementFocusSectionLength(Inc, Fine)

    NI.DATA.SectionAccess.incrementFocusSectionLength(App, Inc > 0 and 1 or -1, Fine)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.setFocusSectionAutoLength()

    local Section = NI.DATA.StateHelper.getFocusSection(App)

    if Section then
        NI.DATA.SectionAccess.setAutoLength(App, Section)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getSectionRetrigValueString()

    local Retrig = "-"

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        Retrig = Song:getPerformRetrigParameter():getValueString()
    end

    return Retrig

end

------------------------------------------------------------------------------------------------------------------------
-- Toggle Follow Mode On/Off
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.toggleFollowMode()

    local Workspace = App:getWorkspace()

    local FollowModeParam = Workspace:getFollowPlayPositionParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, FollowModeParam, not FollowModeParam:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.setPrevNextPattern(EncoderInc)

    local Group        = NI.DATA.StateHelper.getFocusGroup(App)
    local FocusPattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if Group and FocusPattern then

        -- switch pattern
        local Pattern = nil
        if EncoderInc < 0 then
            Pattern = Group:getPatterns():getPrev(FocusPattern)
        else
            Pattern = Group:getPatterns():getNext(FocusPattern)
        end

        -- set focus
        if Pattern then
             -- change pattern
            NI.DATA.GroupAccess.insertPatternAndFocus(App, Group, Pattern)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Loop helper
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.setLoopToWholeSong()

    NI.DATA.TransportAccess.setLoopToWholeSong(App)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getLoopPosAsString()

    local PosString = "-"

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local Pos = Song:getLoopParameter():getLoopBeginInTicks()
        PosString = Song:getTickPositionToString(Pos)
    end

    return PosString

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getLoopLengthAsString()

    local LengthString = "-"

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local Length = Song:getLoopParameter():getLoopLengthInTicks()
        LengthString = Song:getTickToString(Length)
    end

    return LengthString

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getLoopActiveAsString()
    return NI.DATA.TransportAccess.isLoopActive(App) and "ON" or "OFF"
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getSceneLoopActiveAsString()
    return NI.DATA.TransportAccess.isSectionLoopActive(App) and "ON" or "OFF"
end

------------------------------------------------------------------------------------------------------------------------
-- Idea Space
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.toggleIdeasView()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        NI.DATA.SongAccess.toggleIdeasView(App, Song)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.enterIdeaSpaceView()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        NI.DATA.SongAccess.focusIdeas(App, Song)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- SongClipViewMode
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.isSongFocusEntityChanged()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getFocusEntityParameter():isChanged() or false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.immediateSwitchToSongView()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song and ArrangerHelper.isIdeaSpaceFocused() then
        -- this will send the view change request to the RT thread, but it could be handled after the next onCustomProcess
        ArrangerHelper.toggleIdeasView()
        -- therefore we need to set the corresponding view parameter instantly here
        NI.DATA.SongAccess.enterTimeline(App, Song)
        -- however we need the request to the RT thread in case audio is playing because the playback would have to change
        -- along the view switch (from Ideas View to Song View)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Group Labels
------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getGroupListCount()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    local BankCount = Song and math.floor((Song:getGroups():size() + 7) / 8) or 0

    return BankCount * 8

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.setupGroupLabel(Label)

    Label:style("","GroupListItem")

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.loadGroupLabel(Label, Index)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
	local Groups = Song and Song:getGroups()

	if Groups and Groups:at(Index) then
		Label:setVisible(true)
		Label:setText( NI.DATA.Group.getLabel(Index) )
		ColorPaletteHelper.setGroupColor(Label, Index+1)
		Label:setSelected(Index == NI.DATA.StateHelper.getFocusGroupIndex(App))
	else
		Label:setVisible(false)
	end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.isIdeaSpaceFocusChanged()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getArrangerState():isFocusChanged() or false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.isIdeaSpaceFocused()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and NI.DATA.SongAlgorithms.isIdeaSpaceFocused(Song) or false

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.setAppendMode(IdeasPage, AppendMode)

    IdeasPage.AppendMode = AppendMode

    if AppendMode then
        NHLController:setPadMode(NI.HW.PAD_MODE_NONE)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_SCENE)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getSceneNamesList()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local SceneNamesVector = Song and NI.GUI.MenuHelper.getSceneNames(Song) or VectorString()

    local SceneNamesList = {"None"}
    for i=0,SceneNamesVector:size() - 1 do
        SceneNamesList[i+2] = SceneNamesVector:at(i)
    end

    return SceneNamesList

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getSceneReferenceParameterValue()

    local Section = NI.DATA.StateHelper.getFocusSection(App)
    local Scene = Section and Section:getScene()

    return not Section and "-" or Scene and Scene:getNameParameter():getValue() or "None"

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.updateSceneReferenceCapacitiveListAndFocus(Controller, CapPosition)

    local Section = NI.DATA.StateHelper.getFocusSection(App)

    if not Section then
        Controller.CapacitiveList:reset(true)
        return
    end

    Controller.CapacitiveList:assignListToCap(CapPosition, ArrangerHelper.getSceneNamesList())

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scene = Section and Section:getScene()

    local ScenePosition = Song and Scene and Song:getScenes():calcIndex(Scene) or NPOS
    local FocusIndex = ScenePosition ~= NPOS and ScenePosition + 1 or 0

    Controller.CapacitiveList:setListFocusItem(CapPosition, FocusIndex)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.shiftSceneOfFocusSection(Inc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Section = NI.DATA.StateHelper.getFocusSection(App)
    if Song and Section then
        NI.DATA.SectionAccess.shiftSceneOfSection(App, Song, Section, Inc > 0)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.deleteSectionButtonText(ShiftPressed)

    return ShiftPressed and "DEL BANK" or "DELETE"

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.canConvertLoopToClips()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return false
    end
    local Loop = Song:getLoopParameter()
    local CanConvertLoop = NI.DATA.SongAlgorithms.canConvertLoopToClips(Song, Loop)

    return CanConvertLoop
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.convertLoopToClips()

    local keepSongFocusEntity = true -- after conversion we want to stay in SECTIONS
    NI.DATA.SongAccess.convertLoopToClips(App, keepSongFocusEntity)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.canConvertFocusSectionToClips()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Section = NI.DATA.StateHelper.getFocusSection(App)
    if not Song or not Section then
        return false
    end
    local CanConvertFocusSection = NI.DATA.SongAlgorithms.canConvertSectionToClips(Song, Section)

    return CanConvertFocusSection
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.convertFocusSectionToClips()
    local Section = NI.DATA.StateHelper.getFocusSection(App)
    if Section then

        local keepSongFocusEntity = true -- after conversion we want to stay in SECTIONS
        NI.DATA.SongAccess.convertSectionToClips(App, Section, keepSongFocusEntity)
    end
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerHelper.getAccessibleSectionNameByPadIndex(PadIdx, AllowCreatingSections)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return ""
    end

    local Index = Song:getFocusSectionBankIndexParameter():getValue() * NI.UTILS.CONST_SCENES_PER_BANK + PadIdx - 1
    local Section = Song:getSections():find(Index)

    if Section then
        local SectionName = NI.DATA.SectionAlgorithms.getName(Section)
        return (SectionName ~= "") and SectionName or "Empty Section"
    elseif AllowCreatingSections then
        return "New Section"
    else
        return ""
    end

end

------------------------------------------------------------------------------------------------------------------------
