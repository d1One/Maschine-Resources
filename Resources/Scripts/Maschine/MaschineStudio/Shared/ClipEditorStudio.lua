------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ClipEditorStudio = class( 'ClipEditorStudio' )

------------------------------------------------------------------------------------------------------------------------

function ClipEditorStudio:__init(Style)

    self.Style = Style
	self.Editor = nil

end

------------------------------------------------------------------------------------------------------------------------

function ClipEditorStudio:insertInto(Parent, Flex, CustomStyle)

    if self.Editor == nil then
        -- init PatternEditor
        self.Editor = NI.GUI.insertClipEditor(Parent, App, "ClipEditor")
    else
	    Parent:insertChild(self.Editor, "ClipEditor")
	end

   	self.Editor:setStyle(CustomStyle or self.Style)

	if Flex then
        if Parent then
            Parent:setFlex(self.Editor)
        else
            print("Warning: ClipEditorStudio:insertInto(): Trying to set flex widget in parent when parent doesn't exist!")
        end
    end

    self.Editor:setTimer(1)

end

------------------------------------------------------------------------------------------------------------------------

function ClipEditorStudio:zoom(Inc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        local SongLength = NI.DATA.StateHelper.getSongOverviewLength(App)
        local OffsetParameter = Song:getClipEditorOffsetParameterHW()
        local ZoomParameter = Song:getClipEditorZoomParameterHW()

        ArrangerHelper.zoomArrangerLeftAlign(Inc, Song, SongLength, OffsetParameter, ZoomParameter,
            self.Editor:getInnerWidth(), self.Editor:getTimeGrid():getTicksPerPixelUnscaled())
    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipEditorStudio:scroll(Inc)

    if App:getWorkspace():getFollowPlayPositionParameter():getValue() and MaschineHelper.isPlaying() then
        ArrangerHelper.toggleFollowMode()
    end

    local SeqLength = NI.DATA.StateHelper.getSongOverviewLength(App)
    local ViewLength = self.Editor:getTimeGrid():calcTicksForPixels(self.Editor:getInnerWidth())

    ArrangerHelper.scrollClipEditorBound(Inc, SeqLength, ViewLength)

end

------------------------------------------------------------------------------------------------------------------------

function ClipEditorStudio:scrollPianoroll(Inc)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if Sound == nil then
        return
    end

    local OffsetParameter = Sound:getPianorollOffsetYParameterHW()
    local Delta = Inc * 500

    if OffsetParameter:getValue() + Delta < 0 then
    	Delta = -OffsetParameter:getValue()
    end


    NI.DATA.ScrollingAccess.scrollPianorollHW(App, Sound, Delta)

end

------------------------------------------------------------------------------------------------------------------------
