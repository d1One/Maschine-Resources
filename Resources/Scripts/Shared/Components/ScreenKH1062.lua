------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/ScreenBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScreenKH1062 = class( 'ScreenKH1062', ScreenBase )

------------------------------------------------------------------------------------------------------------------------

function ScreenKH1062:__init(Page, PageName, ScreenStack)

    self.ScreenStack = ScreenStack
    self.PageName = PageName
    ScreenBase.__init(self, Page)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenKH1062:setupScreen()

    self.RootBar = NI.GUI.createBar()
    self.RootBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ScreenKH1062")
    NI.GUI.insertPage(self.ScreenStack, self.RootBar, self.PageName)

end

------------------------------------------------------------------------------------------------------------------------

function ScreenKH1062:update(ForceUpdate)
end

