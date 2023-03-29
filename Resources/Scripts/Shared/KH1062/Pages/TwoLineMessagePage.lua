require "Scripts/Shared/Components/ScreenKH1062"
require "Scripts/Shared/KH1062/Pages/KH1062Page"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TwoLineMessagePage = class( 'TwoLineMessagePage', KH1062Page )

------------------------------------------------------------------------------------------------------------------------

function TwoLineMessagePage:__init(PageName, ScreenStack, SwitchHandler, TopLineMessage, BottomLineMessage)

    KH1062Page.__init(self, ScreenKH1062(self, PageName, ScreenStack), SwitchHandler)
    self:setMessage(TopLineMessage, BottomLineMessage)

end

------------------------------------------------------------------------------------------------------------------------

function TwoLineMessagePage:setupScreen()

    KH1062Page.setupScreen(self)

    self.TwoLineBar = NI.GUI.insertBar(self:getRootBar(), "twoLineBar")
    self.TwoLineBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "TwoLineMessagePageFullScreenBar")

    self.LabelTop = NI.GUI.insertLabel(self.TwoLineBar, "lineLabelTop")
    self.LabelTop:style("", "TwoLineMessageLabelStyle")
    self.LabelBottom = NI.GUI.insertLabel(self.TwoLineBar, "lineLabelBottom")
    self.LabelBottom:style("", "TwoLineMessageLabelStyle")

end

------------------------------------------------------------------------------------------------------------------------

function TwoLineMessagePage:setMessage(TopLineMessage, BottomLineMessage)

    self.LabelTop:setText(TopLineMessage or "")
    self.LabelBottom:setText(BottomLineMessage or "")

end
