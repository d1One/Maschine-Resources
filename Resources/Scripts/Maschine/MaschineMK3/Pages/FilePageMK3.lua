------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
FilePageMK3 = class( 'FilePageMK3', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:__init(Controller)

    PageMaschine.__init(self, "FilePageMK3", Controller)

    self.PageLEDs = { NI.HW.LED_FILE }

    self:setupScreen()
    self:setPinned()

    self.ParameterHandler.UseCache = false

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:setPinned(Pin)

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    local SaveAsText = NI.APP.isHeadless() and "SAVE AS" or "SAVE"
    self.Screen:styleScreen(self.Screen.ScreenLeft, {"FILE", "NEW", SaveAsText, "SAVE COPY"}, "HeadButton", false, true)
    self.Screen:styleScreen(self.Screen.ScreenRight, {"EXPORT AUDIO", "", "RECENT", "LOAD"}, "HeadButton", "HeadButton", false, false)
    self.Screen.ScreenButton[1]:style("FILE", "HeadPin")

    self.Screen.ScreenLeft.InfoBar:setMode("FilePageProjectName")

    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "StudioDisplay")

    self.PictureBar = NI.GUI.insertBar(self.Screen.ScreenRight.DisplayBar, "PictureBar")
    self.PictureBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "PictureBar")
    self.PictureBar:setWidth(240)

    -- Recent files list
    self.RecentFiles = NI.GUI.insertLabelVector(self.Screen.ScreenRight.DisplayBar, "ResultList")
    self.RecentFiles:style(false, '')
    self.Screen.ScreenRight.DisplayBar:setFlex(self.RecentFiles)

    self.RecentFiles:getScrollbar():setAutohide(true)
    self.RecentFiles:getScrollbar():setShowIncDecButtons(false)

    -- Connect vector to functions
   local setupRecentsFn = function(ListItem)
        ListItem:style("", "RecentFileListItem")
        NI.GUI.enableCropModeForLabel(ListItem)
    end

    local loadRecentsFn = function(ListItem, Index)
        ListItem:setText(NI.APP.getRecentFilenameAt(Index))
    end

    NI.GUI.connectVector(self.RecentFiles, function() return NI.APP.getRecentFilesSize() end, setupRecentsFn, loadRecentsFn)

    self:setRecentsEnabled(true)

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:onShow(Show)

    if Show then
        self.RecentFiles:setFocusItem(0)
        self.RecentFiles:setAlign()
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:updateScreenButtons()

    local RecentsAvailable = NI.APP.getRecentFilesSize() > 0

    self.Screen.ScreenButton[6]:setEnabled(NI.APP.isNativeOS())
    self.Screen.ScreenButton[6]:setVisible(NI.APP.isNativeOS())
    self.Screen.ScreenButton[6]:setText("STORAGE")

    self.Screen.ScreenButton[7]:setEnabled(RecentsAvailable)
    self.Screen.ScreenButton[7]:setSelected(RecentsAvailable and self:getRecentsEnabled())
    self.Screen.ScreenButton[8]:setVisible(self:getRecentsEnabled())
    self.Screen.ScreenButton[8]:setEnabled(RecentsAvailable)

    PageMaschine.updateScreenButtons(self)

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:onScreenButton(Button, Pressed)

    if Pressed then

        if Button == 1 then

            return -- do nothing

        elseif Button == 2 then

            -- New
            NI.HW.ProjectFileCommands.newProject(App)

        elseif Button == 3 then

            -- Save As
            NHLController:getPageStack():popToBottomPage()
            NHLController:getPageStack():pushPage(NI.HW.PAGE_SAVE_AS)

        elseif Button == 4 then

            -- Save Copy
            if NI.HW.ProjectFileCommands.saveProjectCopy(App) then
                NHLController:getPageStack():popToBottomPage()
            end

        elseif Button == 5 then

            -- Export
            NHLController:getPageStack():popToBottomPage()
            NI.GUI.DialogAccess.openAudioExport(App)

        elseif Button == 6 and self.Screen.ScreenButton[6]:isEnabled() then

            -- STORAGE
            NHLController:getPageStack():popToBottomPage()
            NHLController:getPageStack():pushPage(NI.HW.PAGE_MANAGE_STORAGE)

        elseif Button == 8 then

            -- Load Recent
            self:loadSelectedRecentFile()

        end

    end

    PageMaschine.onScreenButton(self, Button, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:setRecentsEnabled(Enable)

    self.RecentFiles:setVisible(Enable)

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:getRecentsEnabled()

    return self.RecentFiles:isVisible()

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:loadSelectedRecentFile()

    if self:getRecentsEnabled() and NI.APP.getRecentFilesSize() > 0 then
        NI.HW.ProjectFileCommands.loadRecentProject(App, self.RecentFiles:getFocusItem())
    end

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:onScreenEncoder(Index, Inc)

    if Index == 8 and self:getRecentsEnabled() then

        Inc = MaschineHelper.onScreenEncoderSmoother(Index, Inc, .05)
        if Inc ~= 0 then
            self.RecentFiles:shiftFocusItem(Inc)
        end

    end

    self:refreshAccessibleEncoderInfo()

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:onWheelButton(Pressed)

    if Pressed then

        self:loadSelectedRecentFile()

    end

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:onWheel(Inc)

    if self:getRecentsEnabled() then
        self.RecentFiles:shiftFocusItem(Inc)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:getAccessiblePageInfo()

    return "File"

end

------------------------------------------------------------------------------------------------------------------------

function FilePageMK3:getAccessibleParamDescriptionByIndex(EncoderIdx)
    
    local FileName = (EncoderIdx == 8 and self:getRecentsEnabled())
        and NI.APP.getRecentFilenameAt(self.RecentFiles:getFocusItem())
        or ""
    return FileName, "", "", ""

end

------------------------------------------------------------------------------------------------------------------------
