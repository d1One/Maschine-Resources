------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ViewHelper = class( 'ViewHelper' )

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.isSamplingVisible()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getSamplingVisibleParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.isPianorollVisible()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local IsPianorollEnabled = Group and Group:getKeyboardModeEnabledParameter():getValue()
    return IsPianorollEnabled and not ViewHelper.isSamplingVisible()

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.getPatternEditorViewParameters()

    local IsPatternFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN) and
                           NI.DATA.StateHelper.getFocusEventPattern(App) ~= nil

    if not IsPatternFocus then
        return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ZoomXParameter = Song and Song:getPatternEditorZoomParameter() or nil
    local ScrollXParameter = Song and Song:getPatternEditorOffsetParameter() or nil

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local ZoomYParameter = Group and not ViewHelper.isPianorollVisible() and
                           Group:getPatternEditorVerticalZoomParameterSW() or nil

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local ScrollYParameter = Sound and ViewHelper.isPianorollVisible() and Sound:getPianorollOffsetYParameter() or nil

    return ZoomXParameter, ScrollXParameter, ZoomYParameter, ScrollYParameter

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.getClipEditorViewParameters()

    local IsClipFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) and
                        NI.DATA.StateHelper.getFocusClipEvent(App) ~= nil

    if not IsClipFocus then
        return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local ZoomXParameter = Song and Song:getClipEditorZoomParameter() or nil
    local ScrollXParameter = Song and Song:getClipEditorOffsetParameter() or nil
    local ZoomYParameter = Group and not ViewHelper.isPianorollVisible()
                                 and Group:getPatternEditorVerticalZoomParameterSW() or nil

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local ScrollYParameter = Sound and ViewHelper.isPianorollVisible() and Sound:getPianorollOffsetYParameter() or nil

    return ZoomXParameter, ScrollXParameter, ZoomYParameter, ScrollYParameter

end

------------------------------------------------------------------------------------------------------------------------

local function zoom(ZoomParam, Increment, Fine)

    Increment = Increment * (Fine and 0.1 or 1)

    local Delta
    if _VERSION == "Lua 5.1" then
        Delta = math.pow(1.06, Increment * 100.0 )
    else
        Delta = 1.06 ^ (Increment * 100.0)
    end
    local Zoom = math.bound(ZoomParam:getValue() * Delta, ZoomParam:getMin(), ZoomParam:getMax());

    NI.DATA.ParameterAccess.setDoubleParameterNoUndo(App, ZoomParam, Zoom)

end

------------------------------------------------------------------------------------------------------------------------

local function scroll(OffsetParam, ZoomParam, Increment, Fine)

    Increment = Increment * (Fine and 0.1 or 1)

    local Delta = Increment * 100000 / ZoomParam:getValue()
    local Offset = OffsetParam:getValue() + Delta

    NI.DATA.ParameterAccess.setTickParameterNoUndo(App, OffsetParam, Offset)

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.zoomArranger(Increment, Fine)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil then
        return
    end

    zoom(Song:getArrangerZoomParameter(), Increment, Fine)

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.scrollArranger(Increment, Fine)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil then
        return
    end

    scroll(Song:getArrangerOffsetParameter(), Song:getArrangerZoomParameter(), Increment, Fine)

    local FollowModeOn = App:getWorkspace():getFollowPlayPositionParameter():getValue()
    if FollowModeOn and MaschineHelper.isPlaying() then
        ArrangerHelper.toggleFollowMode()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.zoomPatternEditor(Increment, Fine)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil then
        return
    end

    zoom(Song:getPatternEditorZoomParameter(), Increment, Fine)

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.scrollPatternEditor(Increment, Fine)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil then
        return
    end

    scroll(Song:getPatternEditorOffsetParameter(), Song:getPatternEditorZoomParameter(), Increment, Fine)

    local FollowModeOn = App:getWorkspace():getFollowPlayPositionParameter():getValue()
    if FollowModeOn and MaschineHelper.isPlaying() then
        ArrangerHelper.toggleFollowMode()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.zoomClipEditor(Increment, Fine)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil then
        return
    end

    zoom(Song:getClipEditorZoomParameter(), Increment, Fine)

end

------------------------------------------------------------------------------------------------------------------------

function ViewHelper.scrollClipEditor(Increment, Fine)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song == nil then
        return
    end

    scroll(Song:getClipEditorOffsetParameter(), Song:getClipEditorZoomParameter(), Increment, Fine)

end

------------------------------------------------------------------------------------------------------------------------
