
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"

------------------------------------------------------------------------------------------------------------------------
-- File type / User mode unit ("Page < >" buttons and "Page/Preset" text displays).
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_UserModeAndFileType = class( 'BPU_UserModeAndFileType', BrowsePageUnitBase )

function BPU_UserModeAndFileType:__init(Index, Page)

    self.Index = 0
    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_UserModeAndFileType:draw()

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, self.BrowserModel:getUserMode() and "USER" or "FACTORY")

    local FileTypeString = self.BrowserModel:getFileTypeSelection() .. "s"

    if FileTypeString == "Instruments" then
        FileTypeString = "Inst"
    end

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, FileTypeString)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_UserModeAndFileType:onPageButton(Pressed, Next)

    if Pressed then

        local DatabaseFrontend = App:getDatabaseFrontend()

        if self.Controller:isShiftPressed() then
            local BrowserControllerDeferredSearch = App:getBrowserControllerDeferredSearch()
            BrowserControllerDeferredSearch:selectPrevOrNextVisibleFileType(Next)
        else
            local DatabaseFrontend = App:getDatabaseFrontend()
            self.BrowserController:setUserMode(Next, nil, true, false)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function BPU_UserModeAndFileType:updateLEDs()

    if not self.DB3Frontend then
        return
    end

    if self.Controller:isShiftPressed() then

        local FileType = self.BrowserModel:getSelectedFileType()
        LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_LEFT,
            FileType ~= NI.DB3.FILE_TYPE_PROJECT and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_RIGHT,
            FileType ~= NI.DB3.FILE_TYPE_ONESHOT_SAMPLE and LEDHelper.LS_DIM or LEDHelper.LS_OFF)

    else

        local UserMode = self.BrowserModel:getUserMode()
        LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_LEFT, UserMode and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(HW.LED_DISPLAY_ARROW_RIGHT, not UserMode and LEDHelper.LS_DIM or LEDHelper.LS_OFF)

    end

end
