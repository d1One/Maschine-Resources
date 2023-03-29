------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/LoopPageBase"
require "Scripts/Shared/Components/ScreenMaschineStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LoopPageColorDisplayBase = class( 'LoopPageColorDisplayBase', LoopPageBase )

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:__init(Page, Controller)

    -- init base class
    LoopPageBase.__init(self, Page, Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:setupScreen()

	self.Screen = ScreenMaschineStudio(self)

    -- screen buttons
    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"", "", "CONVERT", "ALL"}, "HeadButton", true)

    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"LOOP", "", "", "AUTO"}, "HeadButton")

    -- display bar
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")
        :style(NI.GUI.ALIGN_WIDGET_RIGHT, "StudioDisplay")
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.GroupList = NI.GUI.insertLabelVector(self.Screen.ScreenRight.DisplayBar,"GroupList")
    self.GroupList:style(false, '')
    NI.GUI.connectVector(self.GroupList,
        ArrangerHelper.getGroupListCount, ArrangerHelper.setupGroupLabel, ArrangerHelper.loadGroupLabel)
    self.GroupList:getScrollbar():setVisible(false)

    -- Arrangers
    self.Arranger = self.Controller.SharedObjects.Arranger
    self.ArrangerOV = self.Controller.SharedObjects.ArrangerOverview

    -- call base
    LoopPageBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:updateScreens(ForceUpdate)

    -- update arrangers
    self.Arranger:update(ForceUpdate)
    self.ArrangerOV:update(ForceUpdate)

    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        -- scroll GroupList
        if StateCache:isGroupsChanged() or ForceUpdate then
            local GroupBank = math.floor(NI.DATA.StateHelper.getFocusGroupIndex(App) / 8)
            self.GroupList:setItemOffset(GroupBank * 8)
        end
    end

    -- call base class
    LoopPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:updateScreenButtons(ForceUpdate)

    local CanConvertLoopToClips = ArrangerHelper.canConvertLoopToClips()
    self.Screen.ScreenButton[3]:setEnabled(CanConvertLoopToClips)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == 3 then
            ArrangerHelper.convertLoopToClips()
            return PageMaschine.onScreenButton(self, Idx, Pressed)
        end
    end

    LoopPageBase.onScreenButton(self, Idx, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:onShow(Show)

    if Show then
    	self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
    	self.Arranger:insertInto(self.Screen.ScreenRight.DisplayBar, true)
        self.ArrangerOV:setVisible(true)

    	self.ArrangerOV.Arranger:setArrangerViewport(self.Arranger.Arranger)

        JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)

        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    self.Controller.CapacitiveNavIcons:Enable(Show)

    -- call base class
    LoopPageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:onZoom(Inc)

    self.Arranger:zoom(Inc)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageColorDisplayBase:onScroll(Inc)

    self.Arranger:scroll(Inc)

end

------------------------------------------------------------------------------------------------------------------------
