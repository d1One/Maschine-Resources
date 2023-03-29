------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Components/CapacitiveOverlayBase"

local ATTR_ZOOM_FACTOR = NI.UTILS.Symbol("ZoomFactor")

------------------------------------------------------------------------------------------------------------------------


local class = require 'Scripts/Shared/Helpers/classy'
CapacitiveOverlayNavIcons = class( 'CapacitiveOverlayNavIcons', CapacitiveOverlayBase )

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayNavIcons:__init(Controller)

    CapacitiveOverlayBase.__init(self, Controller)
    local OverlayRoot = NHLController:getHardwareDisplay():getOverlayRoot()

    self.ZoomHIcon = NI.GUI.insertLabel(OverlayRoot, "OverlayZoomHIcon")
    self.ZoomHIcon:style("", "OverlayZoomHIcon")
    self.ZoomHIcon:setVisible(false)

    self.ScrollHIcon = NI.GUI.insertLabel(OverlayRoot, "OverlayScrollHIcon")
    self.ScrollHIcon:style("", "OverlayScrollHIcon")
    self.ScrollHIcon:setVisible(false)

    self.ZoomVIcon = NI.GUI.insertLabel(OverlayRoot, "OverlayZoomVIcon")
    self.ZoomVIcon:style("", "OverlayZoomVIcon")
    self.ZoomVIcon:setVisible(false)

    self.ScrollVIcon = NI.GUI.insertLabel(OverlayRoot, "OverlayScrollVIcon")
    self.ScrollVIcon:style("", "OverlayScrollVIcon")
    self.ScrollVIcon:setVisible(false)

    self.Enabled = false
    self.ShowScrollV = false
    self.ShowZoomH = true
    self.ShowZoomV = true

end

------------------------------------------------------------------------------------------------------------------------
-- Interface
------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayNavIcons:Enable(Enable, ShowScrollV, ShowZoomH, ShowZoomV)

    self.Enabled = Enable
    self.ShowScrollV = ShowScrollV
    self.ShowZoomH = ShowZoomH == nil and true or ShowZoomH
    self.ShowZoomV = ShowZoomV == nil and false or ShowZoomV

end

------------------------------------------------------------------------------------------------------------------------
-- 'Virtuals'
------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayNavIcons:reset()

    self:Enable(false)
    CapacitiveOverlayBase.reset(self)

end

------------------------------------------------------------------------------------------------------------------------

-- All 2nd screen caps are enabled
function CapacitiveOverlayNavIcons:isCapEnabled(Cap)

    return self.Enabled and Cap >= 5

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayNavIcons:isVisible()
    return self.ScrollHIcon:isVisible()
end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayNavIcons:setVisible(Show)

    Show = Show and self.Enabled

    self.ZoomHIcon:setVisible(Show and self.ShowZoomH and true or false)
    self.ScrollHIcon:setVisible(Show)
    self.ScrollVIcon:setVisible(Show and self.ShowScrollV and true or false)
    self.ZoomVIcon:setVisible(Show and self.ShowZoomV and true or false)

end

------------------------------------------------------------------------------------------------------------------------

function CapacitiveOverlayNavIcons:updateIconForVerticalZoom(Zoom)
    if Zoom == NI.DATA.Workspace.PATTERN_EDITOR_VERTICAL_ZOOM_TIMES_ONE then
        self.ZoomVIcon:setAttribute(ATTR_ZOOM_FACTOR, "x1")
    elseif Zoom == NI.DATA.Workspace.PATTERN_EDITOR_VERTICAL_ZOOM_TIMES_TWO then
        self.ZoomVIcon:setAttribute(ATTR_ZOOM_FACTOR, "x2")
    end
end
