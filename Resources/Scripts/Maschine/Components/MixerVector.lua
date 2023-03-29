------------------------------------------------------------------------------------------------------------------------

local ATTR_CONTROLS_VISIBLE = NI.UTILS.Symbol("ControlsVisible")
local ATTR_HAS_FOCUS = NI.UTILS.Symbol("HasFocus")
local ATTR_IS_ADD = NI.UTILS.Symbol("IsAdd")
local ATTR_IS_BYPASSED = NI.UTILS.Symbol("isBypassed")
local ATTR_IS_CLIPPING = NI.UTILS.Symbol("IsClipping")
local ATTR_IS_EMPTY = NI.UTILS.Symbol("IsEmpty")
local ATTR_IS_INSTRUMENT = NI.UTILS.Symbol("isInstrument")
local ATTR_IS_MUTED = NI.UTILS.Symbol("IsMuted")
local ATTR_IS_PAN_CONTROL_ENABLED = NI.UTILS.Symbol("IsPanControlEnabled")
local ATTR_IS_SELECTED = NI.UTILS.Symbol("IsSelected")
local ATTR_IS_SEPARATOR_VISIBLE = NI.UTILS.Symbol("IsSeparatorVisible")
local ATTR_IS_VOLUME_CONTROL_ENABLED = NI.UTILS.Symbol("IsVolumeControlEnabled")
local ATTR_SOUNDS_VISIBLE = NI.UTILS.Symbol("SoundsVisible")
local ATTR_TYPE = NI.UTILS.Symbol("Type")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MixerVector = class( 'MixerVector' )

MixerVector.MODE_VOLUME = 0
MixerVector.MODE_PAN = 1

MixerVector.GENERATOR_TYPE_AUDIO = 0
MixerVector.GENERATOR_TYPE_INSTRUMENT = 1
MixerVector.GENERATOR_TYPE_EFFECT = 2

------------------------------------------------------------------------------------------------------------------------
-- SizeFunc: returns size of vector
-- SetupItemFunc: initialises Item
-- ItemStateFunc:   must return a table with the following fields:
--                  Visible
--                  ControlsVisible
--                  IsAdd
--                  Color
--                  SeparatorColor (nil = disable widget)
--                  NameShort
--                  NameLong
--                  Focused
--                  Selected
--                  Mode (Volume/Pan)
--                  Muted
--                  Cue
--                  Volume
--                  PanParam
--                  Hold
--                  Decline
--                  GeneratorType
--                  NumSlots
--                  SoundsVisible
--                  SlotActive[]

------------------------------------------------------------------------------------------------------------------------

function MixerVector:__init(Page, Name, SizeFunc, SetupFunc, ItemStateFunc)

    self.Vector = NI.GUI.insertMixerBarVector(Page.Screen.RootBar, Name)
    self.Vector:style(true, '')
    self.SizeFunc = SizeFunc
    self.Page = Page

    NI.GUI.connectVector(self.Vector,
        SizeFunc,
        SetupFunc,
        function(MixerBar, Index) MixerVector.loadItem(MixerBar, ItemStateFunc(self.Page, Index)) end)

    self.Vector:getScrollbar():setAutohide(false)
    self.Vector:getScrollbar():setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector.loadItem(MixerBar, State)

    if not State then
        return
    end

     -- Separator.........................................................................

    MixerBar:getSeparator():setActive(State.SeparatorColor ~= nil)

    if State.SeparatorColor then
        MixerBar:getSeparator():setPaletteColorIndex(State.SeparatorColor)
    end

     -- Main..............................................................................

    MixerBar:getHeader():setVisible(State.Visible)
    MixerBar:getControlBar():setVisible(State.Visible)

    MixerBar:setAttribute(ATTR_IS_CLIPPING, MixerBar:getIsClipping() and "true" or "false")
    MixerBar:setAttribute(ATTR_IS_SEPARATOR_VISIBLE, State.SeparatorColor and "true" or "false")
    MixerBar:setAttribute(ATTR_IS_EMPTY, State.Visible and "false" or "true")
    MixerBar:setAttribute(ATTR_IS_ADD, State.IsAdd and "true" or "false")
    MixerBar:setAttribute(ATTR_HAS_FOCUS, State.Focused and "true" or "false")
    MixerBar:setAttribute(ATTR_IS_SELECTED, State.Selected and "true" or "false")
    MixerBar:setAttribute(ATTR_IS_MUTED, State.Muted and "true" or "false")
    MixerBar:setAttribute(ATTR_IS_VOLUME_CONTROL_ENABLED, State.Mode == MixerVector.MODE_VOLUME and "true" or "false")
    MixerBar:setAttribute(ATTR_IS_PAN_CONTROL_ENABLED, State.Mode == MixerVector.MODE_PAN and "true" or "false")
    MixerBar:setAttribute(ATTR_CONTROLS_VISIBLE, State.ControlsVisible and "true" or "false")
    MixerBar:setAttribute(ATTR_SOUNDS_VISIBLE, State.SoundsVisible and "true" or "false")

    if not State.Visible then
        return
    end

    -- Header.............................................................................

    MixerBar:getHeader():setPaletteColorIndex(State.Color)

    MixerBar:getControlBar():setVisible(State.ControlsVisible)

    MixerBar:getNameShort():setText(State.NameShort)
    MixerBar:getNameShort():setPaletteColorIndex(State.Color)

    MixerBar:getNameLong():setText(State.NameLong)
    MixerBar:getNameLong():setPaletteColorIndex(State.Color)
    -- @TODO Enable enableCropMode (NI.GUI.enableCropModeFor...) for the MixerBar:getNameLong() / MultilineTextEdit

    -- Controls.............................................................................

    if not State.ControlsVisible then
        return
    end

    -- Value
    MixerBar:getValueLabel():setText(State.Mode == MixerVector.MODE_VOLUME and
        State.Volume:getAsString(State.Volume:getValue()) or
        State.Pan:getAsString(State.Pan:getValue()))

    -- Volume and Pan
    MixerBar:setVolumeControlToValue(State.Volume:getValue())
    MixerBar:setPanControlToValue(State.Pan:getValue())

    -- level meters
    if State.Refresh then
        MixerBar:getLeftMeter():resetPeak()
        MixerBar:getRightMeter():resetPeak()
    end

    MixerBar:getLeftMeter():setPaletteColorIndex(State.Muted and 0 or State.Color)
    MixerBar:getRightMeter():setPaletteColorIndex(State.Muted and 0 or State.Color)
    MixerBar:getPanIndicator():setPaletteColorIndex(State.Color)

    -- Cue
    MixerBar:getCueIcon():setVisible(State.Cue)
    MixerBar:getCueIcon():setPaletteColorIndex(State.Color)

    -- Slot Icons
    for Index = 0, 6 do
        local SlotIcon = MixerBar:getSlotIcon(Index)
        if SlotIcon then
            SlotIcon:setVisible(Index < State.NumSlots)
            SlotIcon:setPaletteColorIndex(State.Color)
            SlotIcon:setAttribute(ATTR_IS_INSTRUMENT, (Index == 0 and State.IsInstrument) and "true" or "false")
            SlotIcon:setAttribute(ATTR_IS_BYPASSED, State.SlotActive[Index] and "false" or "true")
            SlotIcon:setAttribute(ATTR_TYPE, MixerVector.getSlotTypeAttribute(Index, State))
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector:focusOnItem(Index)

    local Offset = math.floor(Index / 8) * 8

    if self.Vector:getItemOffset() ~= Offset then
        self.Vector:setItemOffset(Offset, 0, 0)
        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector:setAlign()

    self.Vector:setAlign()

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector:getOffset()

    return self.Vector:getItemOffset()

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector:setOffset(Offset)

    return self.Vector:setItemOffset(Offset)

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector:getAt(Index)

    return self.Vector:getWidgetAt(Index)

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector:isMoving()

    return self.Vector:isMoving()

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector:getScaledMeterValue(VolValue)

	local fTargetPos = .85
    local fSlope1 = fTargetPos / .75;
    local fSlope2 = (1 - fTargetPos) / .25

    return (VolValue <= .75)
		and (VolValue * fSlope1)
		or  ((fSlope2 * VolValue) + (1 - fSlope2))

end

------------------------------------------------------------------------------------------------------------------------

function MixerVector.getSlotTypeAttribute(SlotIndex, State)

    if SlotIndex ~= 0 then
        return "effect"
    end

    if State.GeneratorType == MixerVector.GENERATOR_TYPE_AUDIO then
        return "audio"
    elseif State.GeneratorType == MixerVector.GENERATOR_TYPE_INSTRUMENT then
        return "instrument"
    else
        return "effect"
    end

end

------------------------------------------------------------------------------------------------------------------------
