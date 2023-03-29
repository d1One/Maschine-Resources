------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Components/CustomEncoderHandler"
require "Scripts/Shared/Components/Events4DWheel"
require "Scripts/Maschine/Helper/NavigationHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/EventsHelper"

local ATTR_ZOOM_Y = NI.UTILS.Symbol("zoom-y")
local ATTR_VELOCITY_SCALE_VISIBLE = NI.UTILS.Symbol("VelocityScaleVisible")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
EventsPageBase = class( 'EventsPageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function EventsPageBase:__init(Name, Controller)

    PageMaschine.__init(self, Name, Controller)
    self:setupScreen()
end

------------------------------------------------------------------------------------------------------------------------

local function setupSoundsVector(SoundVector, ShowAllSounds)

    local Size  =    function() return ShowAllSounds and 16 or 1 end

    local Setup =    function(Label) Label:style("", "SoundListItem") end

    local Load  =    function(Label, Index)

                        if not ShowAllSounds then
                            Index = NI.DATA.StateHelper.getFocusSoundIndex(App)
                        end

                        Label:setText(Index == NPOS and "" or tostring(Index+1))
                        ColorPaletteHelper.setSoundColor(Label, Index+1)
                        Label:setSelected(Index == NI.DATA.StateHelper.getFocusSoundIndex(App))

                        local Group = NI.DATA.StateHelper.getFocusGroup(App)
                        local ZoomedY = Group and Group:getPatternEditorVerticalZoomParameterHW():getValue() ~= 0
                        Label:setAttribute(ATTR_ZOOM_Y, ZoomedY and "true" or "false")
                    end

    NI.GUI.connectVector(SoundVector, Size, Setup, Load)

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageBase:setupScreen(ShowAllSounds)

    self.PatternInfoBar = NI.GUI.insertLabel(self.Screen.ScreenRight, "PatternInfoBar")
    self.PatternInfoBar:style("NO PATTERN", "PatternInfoBar")

    -- Main Display
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")
        :style(NI.GUI.ALIGN_WIDGET_RIGHT, "StudioDisplay")
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.SoundList = NI.GUI.insertLabelVector(self.Screen.ScreenRight.DisplayBar,"SoundList")
    self.SoundList:style(false, '')
    self.SoundList:getScrollbar():setVisible(false)

    setupSoundsVector(self.SoundList, ShowAllSounds)

    self.Keyboard = NI.GUI.insertPianorollKeyboard(self.Screen.ScreenRight.DisplayBar, App, "Keyboard")
    self.Keyboard:setHWScreen()

    -- Setup Arranger Widgets
    self.Arranger = self.Controller.SharedObjects.PatternEditor
    self.ArrangerOV = self.Controller.SharedObjects.PatternEditorOverview

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageBase:onShow(Show)

    if Show then
        self.Controller.CapacitiveList:assignParametersToCaps({})

        self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.Arranger:insertInto(self.Screen.ScreenRight.DisplayBar, true)
        self.ArrangerOV.Editor:setOverviewSource(self.Arranger.Editor)
        Events4DWheel.updateAccessibilityPatternState(false)
    end

    -- call base
    PageMaschine.onShow(self, Show)

    if Show then
        NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, 5, 0, 0, 0, "Visual Zoom")
        NHLController:setAccessibilityControlState(NI.HW.ZONE_ERPS, 5, 0, NI.HW.CNTRL_NO_STATE)
        NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, 6, 0, 0, 0, "Visual scroll")
        NHLController:setAccessibilityControlState(NI.HW.ZONE_ERPS, 6, 0, NI.HW.CNTRL_NO_STATE)
        NHLController:addAccessibilityControlData(NI.HW.ZONE_ERPS, 7, 0, 0, 0, "Visual lane size")
        NHLController:setAccessibilityControlState(NI.HW.ZONE_ERPS, 7, 0, NI.HW.CNTRL_NO_STATE)
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageBase:updateScreens(ForceUpdate)

    ForceUpdate = ForceUpdate or PadModeHelper.isKeyboardModeChanged()

    local KeyboardOn = PadModeHelper.getKeyboardMode()
    local IsGroupFocused = NI.DATA.StateHelper.getFocusGroup(App) ~= nil

    -- update Sounds/Keyboard
    self.SoundList:setActive(not KeyboardOn)
    self.Keyboard:setActive(KeyboardOn)

    -- update info bars
    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)
    self:updatePatternInfoBar(ForceUpdate)

    -- update arrangers
    self.Arranger:update(ForceUpdate)
    self.ArrangerOV:update(ForceUpdate)

    -- update vector
    local FocusedSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)
    self.SoundList:setFocusItem(FocusedSoundIndex)
    self.Arranger.Editor:getVector():setFocusItem(FocusedSoundIndex)
    self.SoundList:setAlign()
    self.SoundList:setVisible(IsGroupFocused)

    -- Do not show the velocity scale for audio loops
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    self.SoundList:setAttribute(ATTR_VELOCITY_SCALE_VISIBLE, AudioLoop and "false" or "true")

    EventsHelper.updateLeftRightLEDs(self.Controller)

    -- update overlay icons
    self:updateCapacitiveNavIcons()

    -- Update parent
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageBase:updatePatternInfoBar(ForceUpdate)

    local StateCache = App:getStateCache()

    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

    local FocusPattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local NoPatternLabel = SongClipView and "NO CLIP" or "NO PATTERN"

    local IsFocusChanged = ArrangerHelper.isSongFocusEntityChanged() or StateCache:isFocusPatternChanged()
    local IsNameChanged = FocusPattern and FocusPattern:getNameParameter():isChanged()
    local IsColorChanged = FocusPattern and FocusPattern:getColorParameter():isChanged()

    if ForceUpdate or IsFocusChanged or IsNameChanged or IsColorChanged then

        self.PatternInfoBar:setText(FocusPattern and FocusPattern:getNameParameter():getValue() or NoPatternLabel)
        self.PatternInfoBar:setPaletteColorIndex(FocusPattern and (FocusPattern:getColorParameter():getValue()+1) or 0)
        self.PatternInfoBar:setInvalid(0)
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsPageBase:onLeftRightButton(Right, Pressed)

    if Pressed then
        EventsHelper.selectPrevNextEvent(Right)
    end

    self:updateScreens()
end

------------------------------------------------------------------------------------------------------------------------

function EventsPageBase:onZoomScrollEncoder(Idx, Inc)

    if Idx == 5 then -- ZOOM (HORZ)

        self.Arranger:zoom(Inc)

    elseif Idx == 6 then -- SCROLL (HORZ)

        self.Arranger:scroll(Inc)

    elseif Idx == 7 then -- ZOOM (VERT)

        local HasPattern = NI.DATA.StateHelper.getFocusEventPattern(App) ~= nil
        if HasPattern and not PadModeHelper.getKeyboardMode() then
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

function EventsPageBase:updateCapacitiveNavIcons()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local VertZoomParam = Group and Group:getPatternEditorVerticalZoomParameterHW()

    if VertZoomParam then
        self.Controller.CapacitiveNavIcons:updateIconForVerticalZoom(VertZoomParam:getValue())
    end
end

------------------------------------------------------------------------------------------------------------------------
