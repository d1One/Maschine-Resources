------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------
-- Arranger / PatternEditor screen combo
------------------------------------------------------------------------------------------------------------------------


local class = require 'Scripts/Shared/Helpers/classy'
PatternEditorStudio = class( 'PatternEditorStudio' )

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:__init(Style, OverviewSource)

    self.Style = Style
	self.OverviewSource = OverviewSource
	self.Editor = nil

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:insertInto(Parent, Flex, CustomStyle)

    if self.Editor == nil then
        -- init PatternEditor
        self.Editor = NI.GUI.insertEventPatternEditor(Parent, App, "PatternEditor")
        self.Editor:setHWScreen(self.OverviewSource ~= nil)
        self.Editor:setKompleteKeyboardScreen(NI.HW.FEATURE.KEYBOARD == true)
        self.Editor:setOverviewSource(self.OverviewSource and self.OverviewSource.Arranger)
    else
	    Parent:insertChild(self.Editor, "PatternEditor")
	end

   	self.Editor:setStyle(CustomStyle or self.Style)

	if Flex then
        if Parent then
            Parent:setFlex(self.Editor)
        else
            print("Warning: PatternEditorStudio:insertInto(): Trying to set flex widget in parent when parent doesn't exist!")
        end
	end

	self.Editor:setTimer(1)

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:setOverview(OverviewSource)

    self.OverviewSource = OverviewSource
    self.Editor:setHWScreen(true)
    self.Editor:setOverviewSource(OverviewSource)
end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:update(ForceUpdate)

	local StateCache = App:getStateCache()
    local FocusPattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local LengthParam = FocusPattern and FocusPattern:getLengthParameter()

	if ForceUpdate or
		(NI.DATA.ParameterCache.isValid(App) and
		(StateCache:isFocusPatternChanged() or
		StateCache:isFocusPatternNameChanged() or
		(LengthParam and LengthParam:isChanged()))) then

		if not self.OverviewSource then

			self.Editor:updateOverviewTimeGrid()

			-- clip
			self:zoom(0)
		end

		self.Editor:setActive(true)
	end

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:zoom(Inc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
	if Song then
        ArrangerHelper.zoomPatternEditorLeftAlign(Inc, Song, self:getFocusPatternLength(), self.Editor:getInnerWidth(),
            self.Editor:getTimeGrid():getTicksPerPixelUnscaled())
	end

end


------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:scroll(Inc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return
    end

    if App:getWorkspace():getFollowPlayPositionParameter():getValue() and self:isPlayingFocusPattern() then
        ArrangerHelper.toggleFollowMode()
    end

    local ViewLength = self.Editor:getTimeGrid():calcTicksForPixels(self.Editor:getInnerWidth())
    local FocusOffset = ArrangerHelper.scrollPatternEditorBound(Inc, self:getFocusPatternLength(), ViewLength)

    local PatternEditorFocusOffsetParameterHW = Song:getPatternEditorFocusOffsetParameterHW()
    if PatternEditorFocusOffsetParameterHW then
        NI.DATA.ParameterAccess.setTickParameterNoUndo(App, PatternEditorFocusOffsetParameterHW, FocusOffset)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:scrollPianoroll(Inc)

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

function PatternEditorStudio:isPlayingFocusPattern()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if not Group or not MaschineHelper.isPlaying() then
        return false
    end

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local ClipGrowing = Group:isReplacementClipRecordingActive()
    local Pos = self.Editor:getTimeGrid():getPlayPosition()
    local InsideActiveRange = Pos >= self.Editor:getTimeGrid():getStart() and Pos <= self.Editor:getTimeGrid():getEnd()
    return (SongClipView and ClipGrowing) or InsideActiveRange

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:setHWCompactVelocityLayout(Set)

	self.Editor:setHWCompactVelocityLayout(Set)

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:setUseGlobalFollow(Set)

	self.Editor:setUseGlobalFollow(Set)

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:getFocusPatternLength()

    return NI.DATA.StateHelper.getFocusPatternLength(App)

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:getPlayPosition()

	return self.Editor:getTimeGrid():getPlayPosition()

end

------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:isPlayInfoValid()

	return self.Editor:getTimeGrid():isPlayInfoValid()

end

------------------------------------------------------------------------------------------------------------------------
-- Will focus the Pattern editor to a particular 16 steps Segment
------------------------------------------------------------------------------------------------------------------------

function PatternEditorStudio:zoomScrollOnSegment(Segment)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song == nil then
        return
    end

    local ViewWidth = self.Editor:getInnerWidth()
	local TicksPerPixel = self.Editor:getTimeGrid():getTicksPerPixelUnscaled()

    local ZoomParameter     = NI.DATA.StateHelper.getPatternEditorZoomParameter(App, true)
    local OffsetParameter   = NI.DATA.StateHelper.getPatternEditorOffsetParameter(App, true)

    if not ZoomParameter or not OffsetParameter then
        return
    end

    local ViewTickLenFull = ViewWidth * self.Editor:getTimeGrid():getTicksPerPixelUnscaled()

    local StepSize = StepHelper.getPatternEditorSnapInTicks()
    local SegmentSize = StepSize * 16
    local Zoom = (ViewWidth * TicksPerPixel) / SegmentSize
    local ViewTickLenZoom = ViewTickLenFull / Zoom
    local MinZoom = ViewTickLenFull / NI.DATA.StateHelper.getFocusPatternLength(App)

    local Offset    = SegmentSize * Segment
    local MaxOffset = NI.DATA.StateHelper.getFocusPatternLength(App) - ViewTickLenZoom

    Offset = Offset > MaxOffset and MaxOffset or Offset
    Zoom   = Zoom   < MinZoom and MinZoom or Zoom

    NI.DATA.ParameterAccess.setTickParameterNoUndo(App, OffsetParameter, Offset)
    NI.DATA.ParameterAccess.setDoubleParameterNoUndo(App, ZoomParameter, Zoom)

end

------------------------------------------------------------------------------------------------------------------------
