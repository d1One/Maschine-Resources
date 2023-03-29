------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WidgetHelper = class( 'WidgetHelper' )

------------------------------------------------------------------------------------------------------------------------

function WidgetHelper.VectorCenterOnItem(Vector, Item)

	Vector:setItemOffset(math.max(Item - math.floor(Vector:getNumFullyVisibleItems() / 2), 0))

end

------------------------------------------------------------------------------------------------------------------------
