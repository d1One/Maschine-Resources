------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/ForwardPageMaschine"
require "Scripts/Maschine/Maschine/Pages/SelectPageQuiet"
require "Scripts/Maschine/Maschine/Pages/SelectPageEvents"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SelectPage = class( 'SelectPage', ForwardPageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

SelectPage.QUIET	= 1
SelectPage.EVENTS	= 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SelectPage:__init(Controller)

    -- init base class
    ForwardPageMaschine.__init(self, "SelectPage", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SELECT }

    -- since we have to change the whole display, we use multiple sub-pages here
    ForwardPageMaschine.addSubPage(self, SelectPage.QUIET, SelectPageQuiet(self, Controller))
    ForwardPageMaschine.addSubPage(self, SelectPage.EVENTS, SelectPageEvents(self, Controller))
    ForwardPageMaschine.setDefaultSubPage(self, SelectPage.QUIET)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPage:setupScreen()

    self.Screen.ScreenButton[1]:style("SELECT", "HeadPin");

end

------------------------------------------------------------------------------------------------------------------------


