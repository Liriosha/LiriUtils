--[[
LumenUI Library
=====================================

This module provides:

- Scope management with automatic cleanup
- Reactive signals and effects
- Declarative GUI creation via createElement (h)
- Mounting components to the player’s GUI

-------------------------------------
Scope
-------------------------------------
Scope.new(parent)
- Creates a new scope for a component
- Methods:
    - :onCleanup(fn) → run fn when scope is disposed
    - :dispose() → disposes scope and all child scopes

-------------------------------------
Signals & Effects
-------------------------------------
Helpers.createSignal(initialValue) → returns a signal
- signal() → read value
- signal(newValue) → write value and trigger effects

Helpers.useSignal(initialValue) → use inside a component scope
Helpers.createEffect(fn) → run fn reactively
Helpers.useEffect(fn) → run fn reactively inside component scope

Helpers.bind(instance, property, signal) → auto-update instance property

-------------------------------------
Elements / Components
-------------------------------------
Helpers.createElement(typeOrComponent, props, children)
- typeOrComponent: Roblox class or function component
- props: table of values/signals or functions
    - Keys starting with "@" connect to events
- children: array of child instances
Aliases: Helpers.h = Helpers.createElement

-------------------------------------
Mounting
-------------------------------------
mount(component, props, parent)
- Mount a component to a ScreenGui under `parent`
- Returns {instance = container, scope = rootScope, dispose = fn}

-------------------------------------
Example Component: Clock
-------------------------------------
local guilib = require('pkg/guilib')
local H = guilib.helpers
local h = H.h
local useSignal = H.useSignal
local useEffect = H.useEffect
local mount = guilib.mount

local function Clock(_, scope)
    -- Reactive signal to store current time as a string
    local time = useSignal("")

    -- Effect to update time every second
    useEffect(function()
        local running = true
        task.spawn(function()
            while running do
                local now = os.date("*t")
                local formatted = string.format("%02d:%02d:%02d", now.hour, now.min, now.sec)
                time(formatted)
                task.wait(1)
            end
        end)
        -- Cleanup when scope disposes
        scope:onCleanup(function()
            running = false
        end)
    end)

    -- GUI
    local frame = h("Frame", {
        Size = UDim2.new(0, 200, 0, 80),
        Position = UDim2.new(0.5, -100, 0.5, -40),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    }, {
        h("UICorner", { CornerRadius = UDim.new(0, 12) }),
        h("TextLabel", {
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(0, 255, 0),
            Font = Enum.Font.Code,
            TextSize = 28,
            Text = function() return time() end -- reactive binding
        })
    })

    scope:onCleanup(function()
        frame:Destroy()
    end)

    return frame
end

mount(Clock, {}, game.Players.LocalPlayer:WaitForChild("PlayerGui"))

-------------------------------------
Notes:
- Signals and effects only work inside a component scope.
- Use scope:onCleanup to automatically clean GUI or connections.
- Properties can be functions/signals for reactive updates.
- Events are prefixed with '@' in props table.
]]
local Scope = {}
Scope.__index = Scope
function Scope.new(parent)
    local self = setmetatable({}, Scope)
    self.parent = parent
    self.cleanups = {}
    self.children = {}
    self.disposed = false
    if parent then
        table.insert(parent.children, self)
    end
    return self
end
function Scope:onCleanup(fn)
    table.insert(self.cleanups, fn)
end
function Scope:dispose()
    if self.disposed then return end
    self.disposed = true
    for _, child in ipairs(self.children) do
        child:dispose()
    end
    for _, fn in ipairs(self.cleanups) do
        fn()
    end
    self.cleanups = {}
    self.children = {}
end
local Helpers = {}
Helpers._CURRENT_EFFECT = nil
Helpers._CURRENT_SCOPE = nil
function Helpers.createSignal(initialValue)
    local value = initialValue
    local observers = {}
    local function signal(newValue)
        if newValue ~= nil then
            if newValue == value then return end
            value = newValue
            local snapshot = {}
            for obs in pairs(observers) do snapshot[obs] = true end
            for effect in pairs(snapshot) do
                local success, err = pcall(effect)
                if not success then warn("Effect error:", err) end
            end
        else
            if Helpers._CURRENT_EFFECT then
                observers[Helpers._CURRENT_EFFECT] = true
            end
            return value
        end
    end
    return signal
end
function Helpers.createEffect(fn)
    local function run()
        Helpers._CURRENT_EFFECT = run
        local success, err = pcall(fn)
        if not success then warn("Effect error:", err) end
        Helpers._CURRENT_EFFECT = nil
    end
    run()
end
function Helpers.useSignal(initial)
    local scope = Helpers._CURRENT_SCOPE
    assert(scope, "useSignal must be called inside a component")
    local sig = Helpers.createSignal(initial)
    return sig
end
function Helpers.useEffect(fn)
    local scope = Helpers._CURRENT_SCOPE
    assert(scope, "useEffect must be called inside a component")
    local function wrapped()
        Helpers._CURRENT_EFFECT = wrapped
        local success, err = pcall(fn)
        if not success then warn("Effect error:", err) end
        Helpers._CURRENT_EFFECT = nil
    end
    wrapped()
end
function Helpers.bind(instance, property, signal)
    Helpers.createEffect(function()
        instance[property] = signal()
    end)
end
local function createInstance(typeOrComponent, props, children)
    props = props or {}
    children = children or {}
    if type(typeOrComponent) == "function" then
        local parentScope = Helpers._CURRENT_SCOPE
        local childScope = Scope.new(parentScope)
        table.insert(parentScope.children, childScope)

        Helpers._CURRENT_SCOPE = childScope
        local instance = typeOrComponent(props, childScope)
        Helpers._CURRENT_SCOPE = parentScope
        return instance
    end
    local instance = Instance.new(typeOrComponent)
    for key, value in pairs(props) do
        if type(key) == "string" and key:sub(1,1) == "@" then
            local name = key:sub(2)
            local ok, prop = pcall(function() return instance[name] end)
            if ok and typeof(prop) == "RBXScriptSignal" then
                instance[name]:Connect(value)
            else
                Helpers.bind(instance, name, value)
                local success, signalEvent = pcall(function()
                    return instance:GetPropertyChangedSignal(name)
                end)
                if success and signalEvent then
                    signalEvent:Connect(function()
                        value(instance[name])
                    end)
                end
            end
        elseif type(value) == "function" then
            Helpers.bind(instance, key, value)
        else
            instance[key] = value
        end
    end
    for _, child in ipairs(children) do
        child.Parent = instance
    end
    return instance
end
Helpers.createElement = createInstance
Helpers.h = createInstance
local function mount(component, props, parent)
    local rootScope = Scope.new(nil)
    local container = Instance.new("ScreenGui")
    container.Name = "App"
    container.ResetOnSpawn = false
    container.Parent = parent
    Helpers._CURRENT_SCOPE = rootScope
    local instance = component(props or {}, rootScope)
    Helpers._CURRENT_SCOPE = nil
    instance.Parent = container
    return {
        instance = container,
        scope = rootScope,
        dispose = function()
            rootScope:dispose()
            container:Destroy()
        end
    }
end
return {
    scope = Scope,
    helpers = Helpers,
    mount = mount
}
