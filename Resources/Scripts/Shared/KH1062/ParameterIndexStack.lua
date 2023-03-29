local class = require 'Scripts/Shared/Helpers/classy'
ParameterIndexStack = class( 'ParameterIndexStack' )

function ParameterIndexStack:__init()

    self:clear()

end

function ParameterIndexStack:clear()

    self.ParameterStack = {}
    self.ParameterTurnedWithoutTouch = nil

end

function ParameterIndexStack:setParameterTurnedWithoutTouch(Index)

    -- Parameters are usually tracked with touch/release events, but in exceptional cases turn events
    -- may be received for parameters for which no touch event is received
    self.ParameterTurnedWithoutTouch = Index

end

function ParameterIndexStack:bringToTop(ParameterIndex)

    self:remove(ParameterIndex)
    table.insert(self.ParameterStack, ParameterIndex)
    self.ParameterTurnedWithoutTouch = nil

end

function ParameterIndexStack:addAtBottom(ParameterIndex)

    self:remove(ParameterIndex)
    table.insert(self.ParameterStack, 1, ParameterIndex)
    self.ParameterTurnedWithoutTouch = nil

end

function ParameterIndexStack:remove(ParameterIndex)

    for StackIndex = 1, #self.ParameterStack do
        if self.ParameterStack[StackIndex] == ParameterIndex then
            table.remove(self.ParameterStack, StackIndex)
            break
        end
    end
    self.ParameterTurnedWithoutTouch = nil

end

function ParameterIndexStack:getTopIndex()

    return #self.ParameterStack == 0 and self.ParameterTurnedWithoutTouch or self.ParameterStack[#self.ParameterStack]

end

function ParameterIndexStack:getSize()

    return #self.ParameterStack

end

function ParameterIndexStack:contains(ParameterIndex)

    for StackIndex = 1, #self.ParameterStack do
        if self.ParameterStack[StackIndex] == ParameterIndex then
            return true
        end
    end

    return false

end
