------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SceneHeader = class( 'SceneHeader' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SceneHeader:__init()

    self.SeqLength = 0   -- relevant area for zooming and scrolling is the sequence length

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:setup(Screen)

    self.TimeGrid = NI.GUI.TimeGrid()
    self.TimeGrid:setPixelPerQuarter(64)
    self.TimeGrid:setMinBeatWidth(32)
    self.TimeGrid:setMinSnapWidth(32)

    self.TimeGridHelper = NI.GUI.TimeGridHelper(self.TimeGrid, true, Screen)

    self.Timeline = NI.GUI.insertSongTimeline(Screen, App, self.TimeGrid, "Timeline")
    self.Timeline:style("")
    self.ClipHeader = NI.GUI.insertArrangerHeader(Screen, App, self.TimeGrid, "ScenesEditor")
    self.ClipHeader:style("Scene")

    self.Timeline:setHWScreen()
    self.Timeline:setMonochrome()
    self.ClipHeader:setHWScreen()
    self.ClipHeader:setMonochrome()

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:setActive(Active)

    self.Timeline:setActive(Active)
    self.ClipHeader:setActive(Active)

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:setSceneBackgroundWidget(SceneBackground)

    self.ClipHeader:setSceneBGWidget(SceneBackground.Widget)

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:update(ForceUpdate)

    local Workspace = App:getWorkspace()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and (ForceUpdate or NI.DATA.ParameterCache.isValid(App)) then

        self.SeqLength = NI.DATA.StateHelper.getSongOverviewLength(App)

        local IsInvalid = false

        local ZoomParameter   = Song:getArrangerZoomParameterHW()
        local OffsetParameter = Song:getArrangerOffsetParameterHW()

        if ForceUpdate or ZoomParameter:isChanged() or OffsetParameter:isChanged() then
            self.TimeGrid:setScale(ZoomParameter:getValue())
            self.TimeGrid:setFirstVisibleTick(OffsetParameter:getValue())
            IsInvalid = true
        end

        local FollowParameter = Workspace:getFollowPlayPositionParameter()

        if ForceUpdate or Song:isSongLengthChanged() or (FollowParameter:isChanged() and FollowParameter:getValue() == true) then
            self:clipZoom()
            self:clipOffset()
            IsInvalid = true
        end

        if IsInvalid then
    	    self.Timeline:setInvalid(0)
            self.ClipHeader:setInvalid(0)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:clipZoom()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and self.ClipHeader then
        local ZoomParameter = Song:getArrangerZoomParameterHW()
        local ZoomMin = (self.ClipHeader:getWidth() * self.TimeGrid:getTicksPerPixelUnscaled()) / self.SeqLength

        if ZoomParameter then
            self.TimeGrid:setScale(math.max(ZoomMin, ZoomParameter:getValue()))
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:clipOffset()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and self.TimeGrid then
        local OffsetParameter = Song:getArrangerOffsetParameterHW()
        local ViewLength = math.min(self.SeqLength, self.TimeGrid:calcTicksForPixels(self.ClipHeader:getWidth()))

        if OffsetParameter then
            self.TimeGrid:setFirstVisibleTick(math.min(self.SeqLength - ViewLength, OffsetParameter:getValue()))
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:onShow()

    -- clip offset and zoom (in case song length has been changed meanwhile)
    self:clipZoom()
    self:clipOffset()

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:onTimer()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local OffsetParameter = Song:getArrangerOffsetParameterHW()
        local InvalidRange = self.TimeGridHelper:advancePlayhead(App, OffsetParameter, true)

        self.TimeGridHelper:invalidatePlayRangeForTimeline(self.Timeline, InvalidRange)
        self.TimeGridHelper:invalidatePlayRangeForClipHeader(self.ClipHeader, InvalidRange)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:onZoom(Inc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local OffsetParameter = Song:getArrangerOffsetParameterHW()
        local ZoomParameter = Song:getArrangerZoomParameterHW()

        ArrangerHelper.zoomArrangerLeftAlign(Inc, Song, self.SeqLength, OffsetParameter, ZoomParameter,
            self.ClipHeader:getWidth(), self.TimeGrid:getTicksPerPixelUnscaled())
    end

end

------------------------------------------------------------------------------------------------------------------------

function SceneHeader:onScroll(Inc)

    local Workspace = App:getWorkspace()
    local FollowModeOn = Workspace:getFollowPlayPositionParameter():getValue() or false

    if FollowModeOn and MaschineHelper.isPlaying() then
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Workspace:getFollowPlayPositionParameter(), false)
    else
        local ViewLength = self.TimeGrid:calcTicksForPixels(self.ClipHeader:getWidth())
        ArrangerHelper.scrollArrangerBound(Inc, self.SeqLength, ViewLength)

        self.Timeline:setInvalid(0)
        self.ClipHeader:setInvalid(0)
    end

end

------------------------------------------------------------------------------------------------------------------------
