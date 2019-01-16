ac.event = {}

function ac.eventDispatch(obj, name, ...)
    local events = obj._events
    if not events then
        return
    end
    local event = events[name]
    if not event then
        return
    end
    for i = #event, 1, -1 do
        local res, arg = event[i](...)
        if res ~= nil then
            return res, arg
        end
    end
end

function ac.eventNotify(obj, name, ...)
    local events = obj._events
    if not events then
        return
    end
    local event = events[name]
    if not event then
        return
    end
    for i = #event, 1, -1 do
        event[i](...)
    end
end

function ac.eventRegister(obj, name, f)
    local events = obj._events
    if not events then
        events = {}
        obj._events = events
    end
    local event = events[name]
    if not event then
        event = {}
        events[name] = event
        function event:remove()
            events[name] = nil
        end
    end
    return ac.trigger(event, f)
end

function ac.game:eventDispatch(name, ...)
    return ac.eventDispatch(self, name, ...)
end

function ac.game:eventNotify(name, ...)
    return ac.eventNotify(self, name, ...)
end

function ac.game:event(name, f)
    return ac.eventRegister(self, name, f)
end
