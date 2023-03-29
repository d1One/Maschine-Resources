------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/MaschineMikro/ScreenMikro"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SaveDialogPageMikro = class( 'SaveDialogPageMikro', PageMikro )

local MAPPED_CANCEL_INDEX = 0
local MAPPED_DISCARD_INDEX = 2
local MAPPED_SAVE_INDEX = 3


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageMikro:__init(Controller)

    PageMikro.__init(self, "SaveDialogPageMikro", Controller)

    -- setup screen
    self:setupScreen()

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageMikro:setupScreen()

    self.Screen = ScreenMikro(self, ScreenMikro.SIMPLE_BAR)

    self.ScreenButtonBar = ScreenHelper.createBarWithButtons(
        self.Screen.RootBar, self.Screen.ScreenButton, {"CANCEL", "DISCARD", "SAVE"}, "HeadButtonRow", "HeadButton")

    self.Title = NI.GUI.insertLabel(self.Screen.RootBar, "Title")
    self.Title:style("Title", "Title")
    self.Title:setText("Save project")

    self.Text = NI.GUI.insertMultilineTextEdit(self.Screen.RootBar, "Text")
    self.Text:style("Text")
    self.Text:setText("Do you want to save?")

    self.Screen.RootBar:setFlex(self.Text)

end


------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageMikro:onShow(Show)

    -- call base class
    Page.onShow(self, Show)

    if Show == true then

        self.Controller:turnOffAllPageLEDs()
        LEDHelper.turnOffLEDs(self.Controller.SCREEN_BUTTON_LEDS)
        self:updateScreens(true)

    end

end


------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageMikro:onPadEvent(PadIndex, Trigger)
end


------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageMikro:onWheel(Value)
end


------------------------------------------------------------------------------------------------------------------------

function SaveDialogPageMikro:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == 1 then

            App:getHardwareInputManager():onButton(MAPPED_CANCEL_INDEX)

        elseif Idx == 2  then

            App:getHardwareInputManager():onButton(MAPPED_DISCARD_INDEX)

        elseif Idx == 3 then

            App:getHardwareInputManager():onButton(MAPPED_SAVE_INDEX)

        end

    end

end


------------------------------------------------------------------------------------------------------------------------
