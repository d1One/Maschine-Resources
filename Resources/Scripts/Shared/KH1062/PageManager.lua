require "Scripts/Shared/Components/DisplayStack"
require "Scripts/Shared/Components/Timer"
local ButtonHelper = require("Scripts/Shared/KH1062/ButtonHelper")
require "Scripts/Shared/KH1062/SwitchHandler"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/TimerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PageManager = class( 'PageManager' )

PageManager.PRIORITY_ROOT_PAGE = 0
PageManager.PRIORITY_SMART_PLAY_PAGE = 1
PageManager.PRIORITY_QUICK_EDIT_PAGE = 2
PageManager.PRIORITY_PARAMETER_PAGE = 3
PageManager.PRIORITY_OVERLAY_PAGE = 4
PageManager.PRIORITY_CONFIRM_ACTION = 5

------------------------------------------------------------------------------------------------------------------------

function PageManager:__init()

    self.PageList = {}
    self.DisplayStack = DisplayStack()
    self.ActiveRootPageID = nil


    local function ShowActivePage()

        self:withVisiblePage(function(Page) Page:onShow(true) end)
        if self.PageChangedCallback then
            self.PageChangedCallback()
        end

    end

    self.DisplayStack:setRemoveCallback(ShowActivePage)
    self.DisplayStack:setInsertCallback(ShowActivePage)

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:registerPages(Pages)

    self.PageList = Pages
    self:addDisplayStackModes()

end

------------------------------------------------------------------------------------------------------------------------

function PageManager.isOverlayPriority(Priority)

    return Priority >= PageManager.PRIORITY_PARAMETER_PAGE

end

------------------------------------------------------------------------------------------------------------------------

function PageManager.isNonOverlayPriority(Priority)

    return not PageManager.isOverlayPriority(Priority)

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:addDisplayStackModes()

    for PageID, PageDefinition in pairs(self.PageList) do
        if PageDefinition.Priority == nil then
            error("Priority not defined for page " .. PageID)
        end
        self.DisplayStack:addMode(PageID, PageDefinition.Priority)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:getVisiblePage()

    local VisiblePageDetail = self:getVisiblePageDetail()
    return VisiblePageDetail and VisiblePageDetail.Page or nil

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:getVisiblePageDetail()

    local CurrentDisplayMode = self.DisplayStack:getCurrent()
    return CurrentDisplayMode ~= nil and self.PageList[CurrentDisplayMode] or nil

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:withVisiblePage(Fn)

    local VisiblePage = self:getVisiblePage()
    if VisiblePage then
        Fn(VisiblePage)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:withPage(PageID, Fn)

    if self.PageList[PageID] then
        Fn(self.PageList[PageID].Page)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:createParameterOwnerPageMap()

    self.ParameterOwnerToPageMap = {}

    local AddPageIfParameterOwnerExists = function(PageID, PageListEntry)
        if PageListEntry.ParameterOwnerID ~= nil then
            self.ParameterOwnerToPageMap[PageListEntry.ParameterOwnerID] = PageID
        end
    end

    for PageID, PageListEntry in pairs(self.PageList) do
        AddPageIfParameterOwnerExists(PageID, PageListEntry)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:changeRootPage(PageID, Refresh)

    local PageDetail = self.PageList[PageID]
    local NewPage = PageDetail and PageDetail.Page or nil
    if PageDetail == nil or NewPage == nil then
        return
    end

    if PageDetail.Priority ~= self.PRIORITY_ROOT_PAGE then
        error("Page "  .. PageID .. " is not a root page")
        return
    end

    if (self:getVisiblePage() == nil) or (PageID ~= self.ActiveRootPageID) or Refresh == true then
        self.ActiveRootPageID = PageID
        self.DisplayStack:removeIfPriorityMatches(function(Priority) return true end)
        self.DisplayStack:insert(PageID)
        self:onRootPageChanged()
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:setRootPageChangedCallback(Callback)

    self.RootPageChangedCallback = Callback

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:setPageChangedCallback(Callback)

    self.PageChangedCallback = Callback

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:onRootPageChanged()

    self.RootPageChangedCallback()

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:openOverlay(PageID, OptionalTicks)

    self.DisplayStack:removeIfPriorityMatches(
        function(Priority)
            return Priority == PageManager.PRIORITY_CONFIRM_ACTION
        end
    )
    local NewPage = self.PageList[PageID].Page
    if NewPage == nil then
        return
    end

    self.DisplayStack:insert(PageID)

    if OptionalTicks then
        self.DisplayStack:scheduleRemove(PageID, OptionalTicks)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:closeOverlay()

    self.DisplayStack:removeIfPriorityMatches(PageManager.isOverlayPriority)

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:closePageAndOverlaysAbove(PageID)

    local PageDefinition = self.PageList[PageID]
    self.DisplayStack:removeIfPriorityMatches(function(Priority)
        return Priority >= PageDefinition.Priority
    end)

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:isOverlayPageOpen(PageID)

    if not PageManager.isOverlayPriority(self.PageList[PageID].Priority) then
        error("PageManager:isOverlayPageOpen - supplied PageID must be an overlay page")
    end

    return self.DisplayStack:getTopPageIfPriorityMatches(PageManager.isOverlayPriority) == PageID

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:isNonOverlayPageOpen(PageID)

    if PageManager.isOverlayPriority(self.PageList[PageID].Priority) then
        error("PageManager:isNonOverlayPageOpen - supplied PageID must not be an overlay page")
    end

    return self.DisplayStack:getTopPageIfPriorityMatches(PageManager.isNonOverlayPriority) == PageID

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:closeSmartPlayPageAndOverlays()

    self.DisplayStack:removeIfPriorityMatches(function(Priority)
        return Priority >= PageManager.PRIORITY_SMART_PLAY_PAGE
    end)

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:getTopNonOverlayPage()

    local PageId = self.DisplayStack:getTopPageIfPriorityMatches(PageManager.isNonOverlayPriority)
    local PageDetail = nil
    if PageId ~= nil then
        PageDetail = self.PageList[PageId]
    end
    return PageDetail

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:withTopNonOverlayPage(Function)

    local PageDetail = self:getTopNonOverlayPage()
    if PageDetail then
        Function(PageDetail.Page)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:openEncoderOverlayForCurrentPage()

    local PageDetail = self:getTopNonOverlayPage()
    if PageDetail and PageDetail.EncoderOverlayPageID then
        self:openOverlay(PageDetail.EncoderOverlayPageID)
        self:withVisiblePage(function (ActivePage)
            ActivePage:updateScreen()
        end)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:isRootPageActive(PageID)

    return self.ActiveRootPageID == PageID

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:onTimer()

    self.DisplayStack:onTimer()

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:openPage(PageID)

    local NewPage = self.PageList[PageID].Page
    if NewPage == nil then
        error("Cannot open undefined page " .. PageID)
    end

    self.DisplayStack:insert(PageID)

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:scheduleRemove(PageID, Ticks)

    self.DisplayStack:scheduleRemove(PageID, Ticks)

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:getActiveSwitchEventTarget()

    local DisplayMode = self.DisplayStack:getTopPageIfMatches(function(DisplayMode)
        return self.PageList[DisplayMode].Page:isSwitchHandlingEnabled()
    end)
    return DisplayMode and self.PageList[DisplayMode].Page or nil

end
