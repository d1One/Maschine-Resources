------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Shared/Components/InfoBarStudio"
require "Scripts/Shared/Components/ScreenMaschineStudio"
require "Scripts/Shared/Helpers/ColorPaletteHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Maschine/Helper/PatternHelper"

local ATTR_ZOOM_Y = NI.UTILS.Symbol("zoom-y")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArrangerPageClipsStudio = class( 'ArrangerPageClipsStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:__init(ParentPage, Controller)

    PageMaschine.__init(self, "ArrangerPageClipsStudio", Controller)

    self.ParentPage = ParentPage
    self.TransactionSequenceMarker = TransactionSequenceMarker()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_ARRANGE }

    -- This is used to make the encoder use for Scene Clip changing less hyper-sensitive
    self.SceneClipEncoderCounter = 0

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

local function setupSoundsVector(SoundVector)

    local Size  =    function() return 16 end

    local Setup =    function(Label) Label:style("", "SoundListItem") end

    local Load  =    function(Label, Index)

                        Label:setText(tostring(Index+1))
                        ColorPaletteHelper.setSoundColor(Label, Index+1)
                        Label:setSelected(Index == NI.DATA.StateHelper.getFocusSoundIndex(App))

                        local Group = NI.DATA.StateHelper.getFocusGroup(App)
                        local ZoomedY = Group and Group:getPatternEditorVerticalZoomParameterHW():getValue() ~= 0
                        Label:setAttribute(ATTR_ZOOM_Y, ZoomedY and "true" or "false")
                    end

    NI.GUI.connectVector(SoundVector, Size, Setup, Load)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"SECTION", "CLIP", "", ""},
        {"HeadTabLeft", "HeadTabRight", "HeadButton", "HeadButton"}, false)

    self.Screen:styleScreen(self.Screen.ScreenRight, {"CREATE", "DELETE", "<<", ">>"}, "HeadButton", false, false)

    self.SoundList = NI.GUI.insertLabelVector(self.Screen.ScreenRight.DisplayBar,"SoundList")
    self.SoundList:style(false, '')
    self.SoundList:getScrollbar():setVisible(false)
    setupSoundsVector(self.SoundList)

    self.Keyboard = NI.GUI.insertPianorollKeyboard(self.Screen.ScreenRight.DisplayBar, App, "Keyboard")
    self.Keyboard:setHWScreen()

    self.ClipEditor = self.Controller.SharedObjects.ClipEditor
    self.ArrangerOV = self.Controller.SharedObjects.ArrangerOverview

    MaschineHelper.resetScreenEncoderSmoother()

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:updateScreens(ForceUpdate)

    ForceUpdate = ForceUpdate or PadModeHelper.isKeyboardModeChanged()
    local KeyboardOn = PadModeHelper.getKeyboardMode()

    -- update Sounds/Keyboard
    self.SoundList:setActive(not KeyboardOn)
    self.Keyboard:setActive(KeyboardOn)

    -- update info bars
    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    -- update arrangers
    self.ArrangerOV:update(ForceUpdate)

    -- scroll SoundList
    local FocusedSoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)
    self.SoundList:setFocusItem(FocusedSoundIndex)
    self.SoundList:setAlign()

    -- update overlay icons (Enable, ShowScrollV, ShowZoomH, ShowZoomV)
    local KeyboardMode = PadModeHelper.getKeyboardMode()
    self.Controller.CapacitiveNavIcons:Enable(true, KeyboardMode, true, not KeyboardMode)

    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:updateScreenButtons(ForceUpdate)

    if self.Controller:getShiftPressed() then

        self.Screen.ScreenButton[1]:setText("IDEAS")
        self.Screen.ScreenButton[1]:setVisible(true)
        self.Screen.ScreenButton[1]:setSelected(false)
        self.Screen.ScreenButton[2]:setText("SONG")
        self.Screen.ScreenButton[2]:setVisible(true)
        self.Screen.ScreenButton[2]:setSelected(true)

        for Index = 3, 8 do
            self.Screen.ScreenButton[Index]:setVisible(false)
        end

        self.Screen:unsetArrowText(1)

    else

        self.Screen.ScreenButton[1]:setText("SECTION")
        self.Screen.ScreenButton[1]:setSelected(false)
        self.Screen.ScreenButton[2]:setText("CLIP")
        self.Screen.ScreenButton[2]:setSelected(true)

        ClipHelper.updateClipPageScreenButtons(self.Screen, false, false)

    end

    -- call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:updateParameters(ForceUpdate)

    ClipHelper.updateParameters(self.ParameterHandler)
    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:updateLeftRightLEDs()

    local HasPrev = NI.DATA.GroupAccess.hasPrevNextClipEvent(App, false)
    local HasNext = NI.DATA.GroupAccess.hasPrevNextClipEvent(App, true)

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, HasPrev)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, HasNext)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_ENTER, NI.HW.BUTTON_ENTER, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_BACK, NI.HW.BUTTON_BACK, false)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()

        self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.ClipEditor:insertInto(self.Screen.ScreenRight.DisplayBar, true)
        self.ArrangerOV:setVisible(true)
        self.ArrangerOV.Arranger:setClipEditorViewport(self.ClipEditor.Editor)
    else
        LEDHelper.resetButtonLEDs({NI.HW.LED_ENTER, NI.HW.LED_BACK})
        self.Controller.CapacitiveNavIcons:Enable(false)
    end

    -- call base class
    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:onScreenButton(Idx, Pressed)

    local ShowRename = NI.APP.isHeadless()
    local FocusClip = NI.DATA.StateHelper.getFocusClipEvent(App)
    local Pattern = FocusClip and FocusClip:getEventPattern() or nil

    if Pressed then
        if self.Controller:getShiftPressed() then
            local Song = NI.DATA.StateHelper.getFocusSong(App)

            if Idx == 1 then
                NI.DATA.SongAccess.focusIdeas(App, Song)
            elseif Idx == 2 then
                NI.DATA.SongAccess.focusSongTimeline(App, Song)

            elseif Idx == 5 and ShowRename and Pattern then
                local NameParam = Pattern:getNameParameter()
                MaschineHelper.openRenameDialog(NameParam:getValue(), NameParam)
            end
        else
            if Idx == 1 then
                NI.DATA.ArrangerAccess.toggleSongFocusEntity(App)

            elseif Idx == 3 and FocusClip then
                NI.DATA.GroupAccess.doubleClipEvent(App, FocusClip)

            elseif Idx == 4 then
                NI.DATA.GroupAccess.duplicateFocusClipEvent(App)

            elseif Idx == 5 then
                local PlayheadPos = NI.DATA.TransportAccess.getPlayPosition(App)
                ClipHelper.createClipAtNextFreeTick(PlayheadPos)

            elseif Idx == 6 then
                ClipHelper.deleteFocusClip()
            end
        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:onScreenEncoder(Idx, Inc)

    if Idx == 5 then -- ZOOM (HORZ)
        self.ClipEditor:zoom(Inc)

    elseif Idx == 6 then -- SCROLL
        self.ClipEditor:scroll(Inc)

    elseif Idx == 7 then -- ZOOM (VERT)
        if not PadModeHelper.getKeyboardMode() then
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local VertZoomParam = Group and Group:getPatternEditorVerticalZoomParameterHW()
            NavigationHelper.incrementEnumParameter(VertZoomParam, Inc >= 0 and 1 or -1)
            self:updateCapacitiveNavIcons()
        end

    elseif Idx == 8 then -- SCROLL (VERT)

        if PadModeHelper.getKeyboardMode() then
           self.ClipEditor:scrollPianoroll(Inc)
        end

    else
        ClipHelper.onClipPageScreenEncoder(Idx, Inc, self.TransactionSequenceMarker, self.Controller:getShiftPressed())
    end

end


------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:updateCapacitiveNavIcons()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local VertZoomParam = Group and Group:getPatternEditorVerticalZoomParameterHW()

    if VertZoomParam then
        self.Controller.CapacitiveNavIcons:updateIconForVerticalZoom(VertZoomParam:getValue())
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArrangerPageClipsStudio:onLeftRightButton(Right, Pressed)

    ClipHelper.onClipPageLeftRightButton(Right, Pressed)
    self:updateLeftRightLEDs()

end

------------------------------------------------------------------------------------------------------------------------
