------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/LoopPageBase"
require "Scripts/Maschine/Maschine/Screens/SceneBackground"
require "Scripts/Maschine/Maschine/Screens/SceneHeader"
require "Scripts/Shared/Components/ScreenMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LoopPage = class( 'LoopPage', LoopPageBase )

------------------------------------------------------------------------------------------------------------------------

function LoopPage:__init(Controller)

    -- init base class
    LoopPageBase.__init(self, "LoopPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = {}

end

------------------------------------------------------------------------------------------------------------------------

function LoopPage:setupScreen()

    self.Screen = ScreenMaschine(self)

    -- screen buttons
    self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", "ALL"}, "HeadButton")

    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"LOOP", "", "", "AUTO"}, "HeadButton")

    -- insert left transport bar (focused item #. name, bpm, song position)
    self.Screen.InfoBar = InfoBar(self.Controller, self.Screen.ScreenLeft)

    -- insert focus object bar
    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "RightScreenDefault")

    -- Parameter page names
    self.Screen:addParameterBar(self.Screen.ScreenLeft)

    -- Scene Header
    self.SceneHeader = SceneHeader()
    self.SceneHeader:setup(self.Screen.ScreenRight)

    -- Scene Background Widget
    self.SceneBackground = SceneBackground()
    self.SceneBackground:setup(self.Screen.ScreenRight)
    self.SceneHeader:setSceneBackgroundWidget(self.SceneBackground)

    -- call base
    LoopPageBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPage:updateScreens(ForceUpdate)

    -- update info bar
    self.Screen.InfoBar:update(ForceUpdate)

    -- update scene header
    self.SceneHeader:update(ForceUpdate)

    -- call base class
    LoopPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPage:onShow(Show)

    if Show then
        self.SceneHeader:onShow()
       	self.Controller:setTimer(self, 1)

        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
    else
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    -- call base class
    LoopPageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPage:onZoom(Inc)

    self.SceneHeader:onZoom(Inc)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPage:onScroll(Inc)

    self.SceneHeader:onScroll(Inc)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPage:onTimer()

    self.SceneHeader:onTimer()

    if self.IsVisible then
       	self.Controller:setTimer(self, 1)
    end

end

------------------------------------------------------------------------------------------------------------------------
