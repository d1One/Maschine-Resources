------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------
-- Arranger / PatternEditor screen combo
------------------------------------------------------------------------------------------------------------------------


local class = require 'Scripts/Shared/Helpers/classy'
ArrangerItemStudio = class( 'ArrangerItemStudio' )

ArrangerItemStudio.FocusOffset = nil

------------------------------------------------------------------------------------------------------------------------

function ArrangerItemStudio:__init(Style, OverviewSource)

    self.Style = Style
	self.OverviewSource = OverviewSource
	self.Arranger = nil

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerItemStudio:insertInto(Parent, Flex)

    if self.Arranger == nil then
        -- init Arranger
        self.Arranger = NI.GUI.insertArrangerPanel(Parent, App, "Arranger")
        self.Arranger:setStyle(self.Style)
        self.Arranger:setHWScreen(self.OverviewSource and true or false)
        if self.OverviewSource then
            self.Arranger:setArrangerViewport(self.OverviewSource.Arranger)
        else
            self.Arranger:resetViewport()
        end

    else

    	Parent:insertChild(self.Arranger, "Arranger")

    end

	if Flex then
		Parent:setFlex(self.Arranger)
	end

	self.Arranger:setTimer(1)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerItemStudio:setVisible(Visible)

    if self.Arranger then
        self.Arranger:setVisible(Visible)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerItemStudio:update(ForceUpdate)

	local StateCache = App:getStateCache()
	local Song = NI.DATA.StateHelper.getFocusSong(App)
	local FollowParameter = App:getWorkspace():getFollowPlayPositionParameter()

	if ForceUpdate or
		(Song and Song:isSongLengthChanged()) or
		(FollowParameter:isChanged() and FollowParameter:getValue() == true) then

		ArrangerItemStudio.FocusOffset = Song:getArrangerOffsetParameterHW():getValue()

		self.Arranger:setActive(true)
	end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerItemStudio:zoom(Inc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

	if Song then
        local SongLength = NI.DATA.StateHelper.getSongOverviewLength(App)
        local OffsetParameter = Song:getArrangerOffsetParameterHW()
        local ZoomParameter = Song:getArrangerZoomParameterHW()

        ArrangerHelper.zoomArrangerLeftAlign(Inc, Song, SongLength, OffsetParameter, ZoomParameter,
            self.Arranger:getInnerWidth(), self.Arranger:getTimeGrid():getTicksPerPixelUnscaled())
	end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerItemStudio:scroll(Inc)

    if App:getWorkspace():getFollowPlayPositionParameter():getValue() and MaschineHelper.isPlaying() then
        ArrangerHelper.toggleFollowMode()
    end

    local SeqLength = NI.DATA.StateHelper.getSongOverviewLength(App)
    local ViewLength = self.Arranger:getTimeGrid():calcTicksForPixels(self.Arranger:getInnerWidth())

    ArrangerHelper.scrollArrangerBound(Inc, SeqLength, ViewLength)

end

------------------------------------------------------------------------------------------------------------------------
