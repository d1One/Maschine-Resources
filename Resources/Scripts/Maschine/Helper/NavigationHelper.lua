------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/ViewHelper"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/LedColors"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
NavigationHelper = class( 'NavigationHelper' )

------------------------------------------------------------------------------------------------------------------------

local SCROLL_LEFT  = -1
local SCROLL_RIGHT =  1
local SCROLL_UP    = -1
local SCROLL_DOWN  =  1

local ZOOM_OUT = -1
local ZOOM_IN  =  1

------------------------------------------------------------------------------------------------------------------------

local function directionalIncrement(Direction)

    return Direction * 0.04 -- 0.04 is abitrary

end

------------------------------------------------------------------------------------------------------------------------

local function canParamChangeInDirection(Param, Direction)

    if not Param then
        return false
    end

    if Direction < 0 then
        return Param:getValue() > Param:getMin()
    else
        return Param:getValue() < Param:getMax()
    end

end

------------------------------------------------------------------------------------------------------------------------

local function scrollVertically(Param, Direction, Fine)

    if not Param then
        return
    end

    local ParamMax = Param:getMax()
    local ParamMin = Param:getMin()
    local Value = Param:getValue() + ((ParamMax - ParamMin) / Param:getNumSteps() * Direction * (Fine and 0.1 or 1))
    Value = math.bound(Value, ParamMin, ParamMax)
    NI.DATA.ParameterAccess.setSizeTParameter(App, Param, Value)

end

------------------------------------------------------------------------------------------------------------------------

local function scrollPatternEditorHorizontally(Direction)
    return function (Fine)
        ViewHelper.scrollPatternEditor(directionalIncrement(Direction), Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canScrollPatternEditorHorizontally(Direction)
    return function ()
        local Param = NI.DATA.StateHelper.getPatternEditorOffsetParameter(App, false)
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function zoomPatternEditorHorizontally(Direction)
    return function (Fine)
        ViewHelper.zoomPatternEditor(directionalIncrement(Direction), Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canZoomPatternEditorHorizontally(Direction)
    return function ()
        local Param = NI.DATA.StateHelper.getPatternEditorZoomParameter(App, false)
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function isPatternEditorVisible()
    return function ()
        return NavigationHelper.isPatternEditorVisible()
    end
end

------------------------------------------------------------------------------------------------------------------------

local function scrollClipEditorHorizontally(Direction)
    return function (Fine)
        ViewHelper.scrollClipEditor(directionalIncrement(Direction), Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canScrollClipEditorHorizontally(Direction)
    return function ()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Param = Song and Song:getClipEditorOffsetParameter() or nil
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function zoomClipEditorHorizontally(Direction)
    return function (Fine)
        ViewHelper.zoomClipEditor(directionalIncrement(Direction), Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canZoomClipEditorHorizontally(Direction)
    return function ()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Param = Song and Song:getClipEditorZoomParameter() or nil
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function isClipEditorVisible()
    return function ()
        return NavigationHelper.isClipEditorVisible()
    end
end

------------------------------------------------------------------------------------------------------------------------

local function getHorizontalScrollParameterFromFocusZoneMap()
    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    return Sampler and Sampler:getZoneEditorScrollXParameter() or nil
end

------------------------------------------------------------------------------------------------------------------------

local function getVerticalScrollParameterFromFocusZoneMap()
    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    return Sampler and Sampler:getZoneEditorScrollYParameter() or nil
end

------------------------------------------------------------------------------------------------------------------------

local function getHorizontalZoomParameterFromFocusZoneMap()
    local Sampler = NI.DATA.StateHelper.getFocusSampler(App, nil)
    return Sampler and Sampler:getZoneEditorZoomXParameter() or nil
end


------------------------------------------------------------------------------------------------------------------------

local function scrollZoneMapHorizontally(Direction)
    return function (Fine)
        local Param = getHorizontalScrollParameterFromFocusZoneMap()
        if Param then
            local IsUndoable = true
            NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Direction * 50, Fine, IsUndoable)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canScrollZoneMapHorizontally(Direction)
    return function ()
        local Param = getHorizontalScrollParameterFromFocusZoneMap()
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function zoomZoneMapHorizontally(Direction)
    return function (Fine)
        local Param = getHorizontalZoomParameterFromFocusZoneMap()
        if Param then
            local IsUndoable = true
            NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Direction * 50, Fine, IsUndoable)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canZoomZoneMapHorizontally(Direction)
    return function ()
        local Param = getHorizontalZoomParameterFromFocusZoneMap()
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function isZoneMapVisible()
    return function ()
        return NavigationHelper.isZoneMapVisible()
    end
end

------------------------------------------------------------------------------------------------------------------------

local function scrollWaveformHorizontally(Direction)
    return function (Fine)
        local IsRecordTab = NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.RECORD
        SamplingHelper.scrollWaveForm(directionalIncrement(Direction), Fine, IsRecordTab)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canScrollWaveformHorizontally(Direction)
    return function ()
        local Param = (function ()
            local IsRecordTab = NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.RECORD
            local View = SamplingHelper.makeFocusSampleOwnerView(IsRecordTab)
            return View and View:waveOffsetParameter() or nil
        end)()
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function zoomWaveformHorizontally(Direction)
    return function (Fine)
        local IsRecordTab = NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.RECORD
        SamplingHelper.zoomWaveForm(directionalIncrement(Direction), Fine, IsRecordTab)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canZoomWaveformHorizontally(Direction)
    return function ()
        local Param = (function ()
            local IsRecordTab = NI.DATA.WORKSPACE.getSamplingTab(App) == SamplingScreenMode.RECORD
            local View = SamplingHelper.makeFocusSampleOwnerView(IsRecordTab)
            return View and View:waveZoomParameter() or nil
        end)()
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function isWaveformVisible()
    return function ()
        return NavigationHelper.isSamplingVisible()
    end
end

------------------------------------------------------------------------------------------------------------------------

local function getVerticalScrollParameterFromPianoroll()
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    return Sound and Sound:getPianorollOffsetYParameter() or nil
end

------------------------------------------------------------------------------------------------------------------------

local function scrollPianorollVertically(Direction)
    return function (Fine)
        scrollVertically(getVerticalScrollParameterFromPianoroll(), Direction, Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canScrollPianorollVertically(Direction)
    return function ()
        local Param = getVerticalScrollParameterFromPianoroll()
        return Param and canParamChangeInDirection(Param, Direction)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function isPianorollVisible()
    return function ()
        return NavigationHelper.isPatternEditorVisible() and PadModeHelper.getKeyboardMode()
    end
end

------------------------------------------------------------------------------------------------------------------------

local function scrollZoneMapVertically(Direction)
    return function (Fine)
        scrollVertically(getVerticalScrollParameterFromFocusZoneMap(), Direction, Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canScrollZoneMapVertically(Direction)
    return function ()
        local Param = getVerticalScrollParameterFromFocusZoneMap()
        return Param and canParamChangeInDirection(Param, Direction)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function scrollArrangerHorizontally(Direction)
    return function (Fine)
        ViewHelper.scrollArranger(directionalIncrement(Direction), Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canScrollArrangerHorizontally(Direction)
    return function ()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Param = Song and Song:getArrangerOffsetParameter() or nil
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function zoomArrangerHorizontally(Direction)
    return function (Fine)
        ViewHelper.zoomArranger(directionalIncrement(Direction), Fine)
    end
end

------------------------------------------------------------------------------------------------------------------------

local function canZoomArrangerHorizontally(Direction)
    return function ()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Param = Song and Song:getArrangerZoomParameter() or nil
        return Param and canParamChangeInDirection(Param, Direction) or false
    end
end

------------------------------------------------------------------------------------------------------------------------

local function isArrangerVisible()
    return function ()
        return NavigationHelper.isArrangerVisible()
    end
end

------------------------------------------------------------------------------------------------------------------------

local PAD_HANDLERS = {
    -- Horizontal scrolling a zooming in pattern editor, zone map or waveform.
    [1] = {{
        Action = scrollPatternEditorHorizontally(SCROLL_LEFT),
        When = isPatternEditorVisible(),
        CanChange = canScrollPatternEditorHorizontally(SCROLL_LEFT),
    }, {
        Action = scrollClipEditorHorizontally(SCROLL_LEFT),
        When = isClipEditorVisible(),
        CanChange = canScrollClipEditorHorizontally(SCROLL_LEFT),
    }, {
        Action = scrollZoneMapHorizontally(SCROLL_LEFT),
        When = isZoneMapVisible(),
        CanChange = canScrollZoneMapHorizontally(SCROLL_LEFT),
    }, {
        Action = scrollWaveformHorizontally(SCROLL_LEFT),
        When = isWaveformVisible(),
        CanChange = canScrollWaveformHorizontally(SCROLL_LEFT),
    }},
    [2] = {{
        Action = zoomPatternEditorHorizontally(ZOOM_OUT),
        When = isPatternEditorVisible(),
        CanChange = canZoomPatternEditorHorizontally(ZOOM_OUT),
    }, {
        Action = zoomClipEditorHorizontally(ZOOM_OUT),
        When = isClipEditorVisible(),
        CanChange = canZoomClipEditorHorizontally(ZOOM_OUT),
    }, {
        Action = zoomZoneMapHorizontally(ZOOM_OUT),
        When = isZoneMapVisible(),
        CanChange = canZoomZoneMapHorizontally(ZOOM_OUT),
    }, {
        Action = zoomWaveformHorizontally(ZOOM_OUT),
        When = isWaveformVisible(),
        CanChange = canZoomWaveformHorizontally(ZOOM_OUT),
    }},
    [3] = {{
        Action = scrollPatternEditorHorizontally(SCROLL_RIGHT),
        When = isPatternEditorVisible(),
        CanChange = canScrollPatternEditorHorizontally(SCROLL_RIGHT),
    }, {
        Action = scrollClipEditorHorizontally(SCROLL_RIGHT),
        When = isClipEditorVisible(),
        CanChange = canScrollClipEditorHorizontally(SCROLL_RIGHT),
    }, {
        Action = scrollZoneMapHorizontally(SCROLL_RIGHT),
        When = isZoneMapVisible(),
        CanChange = canScrollZoneMapHorizontally(SCROLL_RIGHT),
    }, {
        Action = scrollWaveformHorizontally(SCROLL_RIGHT),
        When = isWaveformVisible(),
        CanChange = canScrollWaveformHorizontally(SCROLL_RIGHT),
    }},
    [6] = {{
        Action = zoomPatternEditorHorizontally(ZOOM_IN),
        When = isPatternEditorVisible(),
        CanChange = canZoomPatternEditorHorizontally(ZOOM_IN),
    }, {
        Action = zoomClipEditorHorizontally(ZOOM_IN),
        When = isClipEditorVisible(),
        CanChange = canZoomClipEditorHorizontally(ZOOM_IN),
    }, {
        Action = zoomZoneMapHorizontally(ZOOM_IN),
        When = isZoneMapVisible(),
        CanChange = canZoomZoneMapHorizontally(ZOOM_IN),
    }, {
        Action = zoomWaveformHorizontally(ZOOM_IN),
        When = isWaveformVisible(),
        CanChange = canZoomWaveformHorizontally(ZOOM_IN),
    }},

    -- Vertical scrolling in pianoroll and zone map.
    [4]  = {{
        Action = scrollPianorollVertically(SCROLL_DOWN),
        When = isPianorollVisible(),
        CanChange = canScrollPianorollVertically(SCROLL_DOWN),
    }, {
        Action = scrollZoneMapVertically(SCROLL_DOWN),
        When = isZoneMapVisible(),
        CanChange = canScrollZoneMapVertically(SCROLL_DOWN),
    }},
    [8]  = {{
        Action = scrollPianorollVertically(SCROLL_UP),
        When = isPianorollVisible(),
        CanChange = canScrollPianorollVertically(SCROLL_UP),
    }, {
        Action = scrollZoneMapVertically(SCROLL_UP),
        When = isZoneMapVisible(),
        CanChange = canScrollZoneMapVertically(SCROLL_UP),
    }},

    -- Horizontal scrolling and zooming in arranger.
    [9] = {{
        Action = scrollArrangerHorizontally(SCROLL_LEFT),
        When = isArrangerVisible(),
        CanChange = canScrollArrangerHorizontally(SCROLL_LEFT),
    }},
    [10] = {{
        Action = zoomArrangerHorizontally(ZOOM_OUT),
        When = isArrangerVisible(),
        CanChange = canZoomArrangerHorizontally(ZOOM_OUT),
    }},
    [11] = {{
        Action = scrollArrangerHorizontally(SCROLL_RIGHT),
        When = isArrangerVisible(),
        CanChange = canScrollArrangerHorizontally(SCROLL_RIGHT),
    }},
    [14] = {{
        Action = zoomArrangerHorizontally(ZOOM_IN),
        When = isArrangerVisible(),
        CanChange = canZoomArrangerHorizontally(ZOOM_IN),
    }},
}

------------------------------------------------------------------------------------------------------------------------

local function padHandler(PadIndex)

    local PadHandlers = PAD_HANDLERS[PadIndex]
    if not PadHandlers then
        return
    end

    for _, PadHandler in pairs(PadHandlers) do
        if PadHandler.When() then
            return PadHandler
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text
function NavigationHelper.getPageNameAndStates(Index, ChannelMode)

    local FirstPageInBankIndex = NavigationHelper.getPageBankIndex() * 16
    local ChannelMode = not App:getWorkspace():getModulesVisibleParameter():getValue()

    local ParamCache = App:getStateCache():getParameterCache()
    local ParamOwner = ParamCache:getFocusParameterOwner()

    local CurrentPage = ParamCache:getValidPageParameterValue()
    local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()

    if ChannelMode then

        local PageGroupParameter = App:getWorkspace():getPageGroupParameter()
        local PageGroupIdx = PageGroupParameter:getValue()

        if Index + FirstPageInBankIndex <= NumPages then
            PageName = ParamOwner and ParamOwner:getPageDisplayName(PageGroupIdx, FirstPageInBankIndex + Index - 1) or ""
            return true, true, false, (Index + FirstPageInBankIndex == 1 + CurrentPage), PageName
        end

    else -- Plug-in Mode

        local Slot = NI.DATA.StateHelper.getFocusSlot(App)

        if Slot then

            local Module = Slot:getModule()

            if Module then

                if Index + FirstPageInBankIndex <= NumPages  then
                    local PageName = Module:getPageDisplayName(0, FirstPageInBankIndex + Index - 1)
                     return true, true, false, (Index + FirstPageInBankIndex == 1 + CurrentPage), PageName
                end

            end

        end

    end

    return true, false, false, false, ""

end


------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.getPageBankIndex()

    return NHLController:getContext():getPageNavBankParameter():getValue()

end


------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.hasPrevNextPageBank()

    local ParamCache = App:getStateCache():getParameterCache()
    local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
    local PageBankIndex = NavigationHelper.getPageBankIndex()

    return PageBankIndex > 0, PageBankIndex < (NumPages - 1) / 16

end


------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.setPrevNextPageBank(Next)

    local HasPrevPageBank, HasNextPageBank = NavigationHelper.hasPrevNextPageBank()

    if (not Next and not HasPrevPageBank) or (Next and not HasNextPageBank) then
        return
    end

    local PageBankIndexParameter = NHLController:getContext():getPageNavBankParameter()
    local NewPageBankIndex = NavigationHelper.getPageBankIndex() + (Next and 1 or -1)
    NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PageBankIndexParameter, NewPageBankIndex)

end


------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.updatePadColors(DisplayGroup, PadButtons)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local LevelTab = Song:getLevelTab()

    local FocusGroupIndex = DisplayGroup or NI.DATA.StateHelper.getFocusGroupIndex(App)
    if FocusGroupIndex ~= NPOS then
        FocusGroupIndex = FocusGroupIndex + 1
    end

    if LevelTab == NI.DATA.LEVEL_TAB_SONG then

        for Index, PadButton in ipairs (PadButtons) do

            PadButton:setPaletteColorIndex(0)  -- 0 is white
            PadButton.Label:setPaletteColorIndex(0)
            PadButton:setInvalid(0)
        end

    elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP then

        for Index, PadButton in ipairs (PadButtons) do

            ColorPaletteHelper.setGroupColor(PadButton, FocusGroupIndex)
            ColorPaletteHelper.setGroupColor(PadButton.Label, FocusGroupIndex)
            PadButton:setInvalid(0)
        end

    else
        local SoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App) + 1
        for Index, PadButton in ipairs (PadButtons) do

            ColorPaletteHelper.setSoundColor(PadButton, SoundIndex, FocusGroupIndex)
            ColorPaletteHelper.setSoundColor(PadButton.Label, SoundIndex, FocusGroupIndex)
            PadButton:setInvalid(0)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.updatePadLEDsForPageNav(LEDs, FirstPageInBankIndex)

    local Color = LEDColors.WHITE

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local LevelTab = Song and Song:getLevelTab() or 0

    if LevelTab == 1 then           -- Groups

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        Color = Group and Group:getColorParameter():getValue() or 16

    elseif LevelTab == 2 then       -- Sounds

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        Color = Sound and Sound:getColorParameter():getValue() or 16

    end

    local ParamCache = StateCache:getParameterCache()
    local NumPages = ParamCache:getNumPagesOfFocusParameterOwner()
    -- Note: getValidPageParameterValue() returns 0 if there are no pages (not NPOS/-1)
    local CurrentPage = NumPages > 0 and StateCache:getParameterCache():getValidPageParameterValue() or -1

    LEDHelper.updateLEDsWithFunctor(LEDs, 0,
        function(PadIndex) return (PadIndex - 1 + FirstPageInBankIndex == CurrentPage),
                                  (PadIndex - 1 + FirstPageInBankIndex < NumPages) end,
        function() return Color end,
        MaschineHelper.getFlashState16LevelsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.updatePadLEDsForPageView(LEDs)

    LEDHelper.updateLEDsWithFunctor(LEDs, 0, function (Index)
        local Handler = padHandler(Index)
        return Handler and Handler.CanChange(), Handler ~= nil
    end, function()
        return LEDColors.WHITE
    end)

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.triggerPad(PadIndex, UseFineResolution)

    local Handler = padHandler(PadIndex)
    if not Handler or not Handler.CanChange() then
        return
    end

    Handler.Action(UseFineResolution)

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.incrementEnumParameter(EnumParam, Inc)

    if EnumParam then

        local Value = math.bound(EnumParam:getValue() + Inc, EnumParam:getMin(), EnumParam:getMax())
        NI.DATA.ParameterAccess.setEnumParameter(App, EnumParam, Value)

    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isSamplingVisible()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local IsSamplingVisible = Group and Group:getSamplingVisibleParameter():getValue() or false
    return not NavigationHelper.isMixerVisible() and IsSamplingVisible

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isPatternEditorVisible()

    return not NavigationHelper.isMixerVisible()
           and not NavigationHelper.isSamplingVisible()
           and not NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isClipEditorVisible()

    return not NavigationHelper.isMixerVisible()
           and not NavigationHelper.isSamplingVisible()
           and NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isZoneMapVisible()

    local IsZoneWaveVisible = App:getWorkspace():getZoneWaveVisibleParameter():getValue()
    local OnZoneTab = NI.DATA.WORKSPACE.getSamplingTab(App) == 3
    return NavigationHelper.isSamplingVisible() and OnZoneTab and not IsZoneWaveVisible

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isIdeasVisible()

    return not NavigationHelper.isMixerVisible() and ArrangerHelper.isIdeaSpaceFocused()

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.activateIdeasTab()

    ArrangerHelper.enterIdeaSpaceView()

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isArrangerVisible()

    return not NavigationHelper.isMixerVisible() and not NavigationHelper.isIdeasVisible()

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.activateArrangerTab()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        NI.DATA.SongAccess.focusSongTimeline(App, Song)
    end

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isMixerVisible()

    return App:getWorkspace():getMixerVisibleParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.toggleMixer()

    local Param = App:getWorkspace():getMixerVisibleParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isBrowserVisible()

    return App:getWorkspace():getBrowserVisibleParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.toggleBrowser()

    local Param = App:getWorkspace():getBrowserVisibleParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isModulationVisible()

    return App:getWorkspace():getGroupPanelLowerAreaVisibleParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.toggleModulation()

    local Param = App:getWorkspace():getGroupPanelLowerAreaVisibleParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.isMixerExpanded()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getFunctionalBlocksVisibleMixerParameter():getValue() or false

end

------------------------------------------------------------------------------------------------------------------------

function NavigationHelper.toggleMixerExpanded()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local Param = Song:getFunctionalBlocksVisibleMixerParameter()
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())
    end

end

------------------------------------------------------------------------------------------------------------------------
