------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DisplayStack = class( 'DisplayStack' )

------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function DisplayStack:__init(DefaultMode)

    self.Stack = {}
    self.Priorities = {}
    self.Timers = {}
    self.RemoveCallback = nil -- Called when element is removed
    self.InsertCallback = nil -- Called when element is inserted
    self.DefaultMode = DefaultMode

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:onTimer()

    for DisplayMode,Time in pairs(self.Timers) do

        if Time > 0 then

            self.Timers[DisplayMode] = Time - 1

            if self.Timers[DisplayMode] == 0 then
                self:remove(DisplayMode)
            end

        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:insert(DisplayMode)

    if DisplayMode == self.DefaultMode then
        return
    end

    for Index,Display in ipairs(self.Stack) do
        if Display == DisplayMode then
            self.Timers[Display] = 0
            return
        end
    end

    local Priority = self.Priorities[DisplayMode]
    local Index = 1

    local StackSize = #self.Stack
    while Index <= StackSize and Priority >= self.Priorities[self.Stack[Index]] do
        Index = Index + 1
    end

    table.insert(self.Stack, Index, DisplayMode)

    if self.InsertCallback then
        self.InsertCallback()
    end

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:remove(DisplayMode)

    for Index,Display in ipairs(self.Stack) do
        if Display == DisplayMode then

            self.Timers[Display] = 0
            table.remove(self.Stack, Index)

            if self.RemoveCallback then
                self.RemoveCallback()
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:removeIfPriorityMatches(PriorityPredicate)

    for Index = #self.Stack, 1, -1 do
        local DisplayMode = self.Stack[Index]
        local Priority = self.Priorities[DisplayMode]
        if PriorityPredicate(Priority) then
            self.Timers[DisplayMode] = 0
            table.remove(self.Stack, Index)
            if self.RemoveCallback then
                self.RemoveCallback()
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:removeIfScheduled(DisplayMode)

    for Index,Display in ipairs(self.Stack) do
        if Display == DisplayMode and self.Timers[Display] ~= 0 then
            self.Timers[Display] = 0

            table.remove(self.Stack, Index)

            if self.RemoveCallback then
                self.RemoveCallback()
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:scheduleRemove(DisplayMode, Time)

    for Index,Display in ipairs(self.Stack) do

        if Display == DisplayMode and self.Timers[Display] == 0 then
            self.Timers[DisplayMode] = Time
            break
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:getCurrent()

    local Size = #self.Stack

    if Size == 0 then
        return self.DefaultMode
    end

    return self.Stack[Size]

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:addMode(DisplayMode, Priority)

    self.Priorities[DisplayMode] = Priority
    self.Timers[DisplayMode] = 0

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:getTopPageIfPriorityMatches(PriorityPredicate)

    for i = #self.Stack, 1, -1 do
        DisplayMode = self.Stack[i]

        if PriorityPredicate(self.Priorities[DisplayMode]) then
            return DisplayMode
        end
    end
    return self.DefaultMode

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:getTopPageIfMatches(Predicate)

    for i = #self.Stack, 1, -1 do
        DisplayMode = self.Stack[i]

        if Predicate(DisplayMode) then
            return DisplayMode
        end
    end
    return self.DefaultMode

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:setRemoveCallback(Func)

    self.RemoveCallback = Func

end

------------------------------------------------------------------------------------------------------------------------

function DisplayStack:setInsertCallback(Func)

    self.InsertCallback = Func

end