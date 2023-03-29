local class = require 'Scripts/Shared/Helpers/classy'
BrowserNavigationTracker = class( 'BrowserNavigationTracker' )

------------------------------------------------------------------------------------------------------------------------

function BrowserNavigationTracker:__init(InitialPageID, InitialFilter)

    self.PageID = InitialPageID
    self.Filter = InitialFilter

end

------------------------------------------------------------------------------------------------------------------------

function BrowserNavigationTracker:setAvailableFilters(Filters)

    self.Filters = Filters

end

------------------------------------------------------------------------------------------------------------------------

function BrowserNavigationTracker:setCurrentPageAndFilter(PageID, Filter)

    self.PageID = PageID
    self.Filter = Filter

end

------------------------------------------------------------------------------------------------------------------------

function BrowserNavigationTracker:getCurrentFilterPageAndFilter()

    return {
        PageID = self.PageID,
        Filter = self.Filter
    }

end
