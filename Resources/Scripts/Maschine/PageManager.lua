------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PageManager = class( 'PageManager' )

------------------------------------------------------------------------------------------------------------------------

function PageManager:__init(Controller)

    self.Pages = {}
	self.Controller = Controller

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:register(PageID, Module, ClassName, Preload)

    -- load module
    require(Module)

	self.Pages[PageID] = { Page = nil, Module = Module, ClassName = ClassName }

	if Preload then
        self:getPage(PageID)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:getPage(PageID)

	local PageEntry = self.Pages[PageID]

	if PageEntry then

		local Page = PageEntry.Page
		if Page then -- page already created
			return Page
		end

		-- construct page
		if _VERSION == "Lua 5.1" then
			PageEntry.Page = loadstring("local Controller = ...; return " .. PageEntry.ClassName .."(Controller)")(self.Controller)
		else
			PageEntry.Page = load("local Controller = ...; return " .. PageEntry.ClassName .."(Controller)")(self.Controller)
		end

		--print("Page loaded - ".. PageEntry.Page.Name.." ("..PageID..")")

        -- restore saved pin state
        if PageID >= NI.HW.PAGE__FIRST_MODIFIER and PageID <= NI.HW.PAGE__LAST_MODIFIER then
            if PageEntry.Page and PageEntry.Page.setPinned then
                PageEntry.Page:setPinned(NHLController:getPageStack():getPagePinState(PageID))
            end
        end

		return PageEntry.Page

	end

	return nil -- unregistered PageID

end

------------------------------------------------------------------------------------------------------------------------

function PageManager:getPageID(Page)

	if Page and Page.Name then

		for id, PageEntry in pairs(self.Pages) do

			--print("PageManager:getPageID: id: "..id)
			if PageEntry.Page and PageEntry.Page.Name == Page.Name then
				return id
			end

		end

	end

	return nil

end

------------------------------------------------------------------------------------------------------------------------
