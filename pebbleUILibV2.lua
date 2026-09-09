--[[
    Pebble UI Library
    Version 0.6.0

    Single-file Roblox/Luau UI library.

    Core:
    - Window / Topbar / Sidebar / Tabs
    - Collapsible sidebar with attached toggle
    - Per-window theme overrides + runtime theme updates
    - Background/select transparency and color controls
    - Drag / resize / minimize / maximize / close
    - Lucide icons
    - Player headshot panel

    Layout engine:
    - Free / Vertical / Horizontal / Grid
    - Nested layouts and panels
    - Per-element Size / Position / AnchorPoint / Alignment / Color / Transparency / Radius / Stroke / ZIndex

    Elements:
    - Panel
    - Text / Paragraph
    - Button
    - Toggle
    - Slider
    - ProgressBar
    - Input
    - Dropdown
    - Keybind
    - Code
    - ColorPicker
    - Section
    - Divider
    - Space
    - Image

    Window extras:
    - Notify
    - Dialog

    Everything is implemented from scratch for Pebble.
]]

local Pebble = {
    Version = "0.6.0",
}

--============================================================
-- Services
--============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--============================================================
-- Lucide icons
--============================================================

local LucideIcons = {}

do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
        ))()
    end)

    if ok and typeof(result) == "table" then
        LucideIcons = result
    else
        warn("[Pebble] Failed to load Lucide icons:", result)
    end
end

local function GetIcon(name)
    if typeof(name) ~= "string" then
        return ""
    end

    if string.match(name, "^rbxassetid://") then
        return name
    end

    local icon = LucideIcons[name]
    if not icon then
        warn("[Pebble] Lucide icon not found:", name)
        return ""
    end

    return icon
end

--============================================================
-- Theme
--============================================================

local DefaultTheme = {
    Background = Color3.fromRGB(16, 17, 19),
    BackgroundTop = Color3.fromRGB(24, 25, 28),
    BackgroundBottom = Color3.fromRGB(13, 14, 16),

    Sidebar = Color3.fromRGB(17, 18, 20),
    Surface = Color3.fromRGB(25, 26, 29),
    Surface2 = Color3.fromRGB(30, 31, 35),
    SurfaceHover = Color3.fromRGB(35, 36, 40),
    Input = Color3.fromRGB(29, 30, 34),

    Stroke = Color3.fromRGB(255, 255, 255),

    Text = Color3.fromRGB(244, 244, 247),
    SubText = Color3.fromRGB(148, 149, 158),
    MutedText = Color3.fromRGB(103, 104, 113),

    Accent = Color3.fromRGB(103, 76, 255),
    AccentText = Color3.fromRGB(255, 255, 255),

    Icon = Color3.fromRGB(183, 184, 194),
    IconSelected = Color3.fromRGB(245, 245, 247),

    Success = Color3.fromRGB(72, 199, 116),
    Warning = Color3.fromRGB(245, 184, 69),
    Danger = Color3.fromRGB(235, 76, 76),
}

Pebble.Theme = DefaultTheme

local Defaults = {
    Title = "Pebble",
    Version = "v0.6",
    Icon = "sparkles",
    Tags = {},

    Size = UDim2.fromOffset(820, 540),
    Position = UDim2.fromScale(0.5, 0.5),
    MinSize = Vector2.new(560, 360),
    MaxSize = Vector2.new(1300, 900),

    TopbarHeight = 56,
    SidebarWidth = 218,
    CollapsedSidebarWidth = 62,
    CornerRadius = 12,

    BackgroundTransparency = 0.28,
    SidebarTransparency = 0.28,
    SelectTransparency = 0.82,

    Draggable = true,
    Resizable = true,
}

--============================================================
-- Classes
--============================================================

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Container = {}
Container.__index = Container

local Element = {}
Element.__index = Element

local Section = {}
Section.__index = Section

--============================================================
-- Utilities
--============================================================

local function ShallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do
        copy[key] = value
    end
    return copy
end

local function Merge(base, overrides)
    local result = ShallowCopy(base)
    for key, value in pairs(overrides or {}) do
        result[key] = value
    end
    return result
end

local function Clamp01(value)
    return math.clamp(tonumber(value) or 0, 0, 1)
end

local function New(className, props)
    local object = Instance.new(className)
    for property, value in pairs(props or {}) do
        object[property] = value
    end
    return object
end

local function Corner(parent, radius)
    local corner = New("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    })
    corner.Parent = parent
    return corner
end

local function AddStroke(parent, color, transparency, thickness)
    local stroke = New("UIStroke", {
        Color = color or Color3.new(1, 1, 1),
        Transparency = transparency == nil and 0.9 or transparency,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    stroke.Parent = parent
    return stroke
end

local function Tween(object, duration, props, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.2,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        props
    )
    tween:Play()
    return tween
end

local function SafeCallback(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[Pebble] Callback error:", err)
    end
end

local function ResolveTextX(value)
    if value == "Center" or value == Enum.TextXAlignment.Center then
        return Enum.TextXAlignment.Center
    elseif value == "Right" or value == Enum.TextXAlignment.Right then
        return Enum.TextXAlignment.Right
    end
    return Enum.TextXAlignment.Left
end

local function ResolveTextY(value)
    if value == "Center" or value == Enum.TextYAlignment.Center then
        return Enum.TextYAlignment.Center
    elseif value == "Bottom" or value == Enum.TextYAlignment.Bottom then
        return Enum.TextYAlignment.Bottom
    end
    return Enum.TextYAlignment.Top
end

local function ResolveHorizontal(value)
    if value == "Center" or value == Enum.HorizontalAlignment.Center then
        return Enum.HorizontalAlignment.Center
    elseif value == "Right" or value == Enum.HorizontalAlignment.Right then
        return Enum.HorizontalAlignment.Right
    end
    return Enum.HorizontalAlignment.Left
end

local function ResolveVertical(value)
    if value == "Center" or value == Enum.VerticalAlignment.Center then
        return Enum.VerticalAlignment.Center
    elseif value == "Bottom" or value == Enum.VerticalAlignment.Bottom then
        return Enum.VerticalAlignment.Bottom
    end
    return Enum.VerticalAlignment.Top
end

local function RoundToStep(value, step)
    if not step or step <= 0 then
        return value
    end
    return math.floor((value / step) + 0.5) * step
end

local function FormatNumber(value)
    if math.abs(value - math.floor(value)) < 0.0001 then
        return tostring(math.floor(value))
    end
    return string.format("%.2f", value)
end

local function CreateIcon(name, size)
    return New("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size or 18, size or 18),
        Image = GetIcon(name),
        ImageColor3 = DefaultTheme.Icon,
        ScaleType = Enum.ScaleType.Fit,
    })
end

local function CreateHitbox(parent, zIndex)
    local button = New("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = zIndex or ((parent.ZIndex or 1) + 10),
    })
    button.Parent = parent
    return button
end

--============================================================
-- Theme binding
--============================================================

local function ThemeValue(window, key)
    return window.Theme[key] or DefaultTheme[key]
end

local function BindTheme(window, instance, property, key, override)
    if override ~= nil then
        instance[property] = override
        return
    end

    instance[property] = ThemeValue(window, key)
    table.insert(window._themeBindings, {
        Instance = instance,
        Property = property,
        Key = key,
    })
end

function Window:_RefreshTheme()
    for index = #self._themeBindings, 1, -1 do
        local binding = self._themeBindings[index]
        local instance = binding.Instance

        if instance and instance.Parent then
            local value = ThemeValue(self, binding.Key)
            if value ~= nil then
                instance[binding.Property] = value
            end
        else
            table.remove(self._themeBindings, index)
        end
    end
end

--============================================================
-- Common visual configuration
--============================================================

local function ApplyFrameConfig(frame, config)
    config = config or {}

    if config.Size then frame.Size = config.Size end
    if config.Position then frame.Position = config.Position end
    if config.AnchorPoint then frame.AnchorPoint = config.AnchorPoint end
    if config.LayoutOrder ~= nil then frame.LayoutOrder = config.LayoutOrder end
    if config.ZIndex ~= nil then frame.ZIndex = config.ZIndex end
    if config.Visible ~= nil then frame.Visible = config.Visible end
    if config.ClipsDescendants ~= nil then frame.ClipsDescendants = config.ClipsDescendants end
end

local function MakeElement(window, instance)
    return setmetatable({
        Window = window,
        Instance = instance,
        Container = instance,
    }, Element)
end

function Element:Set(property, value)
    if self.Instance then
        self.Instance[property] = value
    end
    return self
end

function Element:Get(property)
    if not self.Instance then
        return nil
    end
    return self.Instance[property]
end

function Element:Tween(props, duration)
    if self.Instance then
        Tween(self.Instance, duration or 0.2, props)
    end
    return self
end

function Element:Show()
    if self.Instance then self.Instance.Visible = true end
    return self
end

function Element:Hide()
    if self.Instance then self.Instance.Visible = false end
    return self
end

function Element:SetVisible(value)
    if self.Instance then self.Instance.Visible = value == true end
    return self
end

function Element:SetSize(size)
    if self.Instance then self.Instance.Size = size end
    return self
end

function Element:SetPosition(position)
    if self.Instance then self.Instance.Position = position end
    return self
end

function Element:Destroy()
    if self.Instance then
        self.Instance:Destroy()
        self.Instance = nil
    end
end

--============================================================
-- Container creation
--============================================================

local function CreateContainer(window, parent, config)
    config = config or {}

    local mode = config.Type or "Free"
    local scrolling = config.Scrolling == true
    local className = scrolling and "ScrollingFrame" or "Frame"

    local frameProps = {
        Name = config.Name or (mode .. "Layout"),
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.fromScale(1, 1),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 1 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder or 0,
        ZIndex = config.ZIndex or 10,
        Visible = config.Visible ~= false,
        ClipsDescendants = config.ClipsDescendants == true,
        AutomaticSize = config.AutomaticSize or Enum.AutomaticSize.None,
    }

    if scrolling then
        frameProps.CanvasSize = config.CanvasSize or UDim2.fromOffset(0, 0)
        frameProps.AutomaticCanvasSize = config.AutomaticCanvasSize or Enum.AutomaticSize.Y
        frameProps.ScrollBarThickness = config.ScrollBarThickness or 2
        frameProps.ScrollBarImageTransparency = config.ScrollBarImageTransparency == nil and 0.72 or config.ScrollBarImageTransparency
        frameProps.ScrollingDirection = config.ScrollingDirection or Enum.ScrollingDirection.Y
    end

    local frame = New(className, frameProps)
    BindTheme(window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    frame.Parent = parent

    if config.CornerRadius then
        Corner(frame, config.CornerRadius)
    end

    if config.Stroke == true then
        local stroke = AddStroke(
            frame,
            ThemeValue(window, "Stroke"),
            config.StrokeTransparency == nil and 0.92 or config.StrokeTransparency,
            config.StrokeThickness or 1
        )
        if config.StrokeColor == nil then
            BindTheme(window, stroke, "Color", "Stroke")
        else
            stroke.Color = config.StrokeColor
        end
    end

    if typeof(config.Padding) == "number" and config.Padding > 0 then
        local padding = config.Padding
        New("UIPadding", {
            PaddingTop = UDim.new(0, padding),
            PaddingBottom = UDim.new(0, padding),
            PaddingLeft = UDim.new(0, padding),
            PaddingRight = UDim.new(0, padding),
            Parent = frame,
        })
    elseif typeof(config.Padding) == "table" then
        New("UIPadding", {
            PaddingTop = UDim.new(0, config.Padding.Top or 0),
            PaddingBottom = UDim.new(0, config.Padding.Bottom or 0),
            PaddingLeft = UDim.new(0, config.Padding.Left or 0),
            PaddingRight = UDim.new(0, config.Padding.Right or 0),
            Parent = frame,
        })
    end

    local layoutObject

    if mode == "Vertical" or mode == "Horizontal" then
        layoutObject = New("UIListLayout", {
            FillDirection = mode == "Vertical" and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, config.Gap or 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = ResolveHorizontal(config.HorizontalAlignment),
            VerticalAlignment = ResolveVertical(config.VerticalAlignment),
        })
        layoutObject.Parent = frame
    elseif mode == "Grid" then
        local columns = math.max(1, config.Columns or 2)
        local gap = config.Gap or 10

        layoutObject = New("UIGridLayout", {
            CellPadding = config.CellPadding or UDim2.fromOffset(gap, gap),
            CellSize = config.CellSize or UDim2.new(
                1 / columns,
                -math.floor(gap * (columns - 1) / columns),
                0,
                config.CellHeight or 120
            ),
            SortOrder = Enum.SortOrder.LayoutOrder,
            FillDirection = Enum.FillDirection.Horizontal,
            FillDirectionMaxCells = columns,
            HorizontalAlignment = ResolveHorizontal(config.HorizontalAlignment),
            VerticalAlignment = ResolveVertical(config.VerticalAlignment),
        })
        layoutObject.Parent = frame
    end

    local object = setmetatable({
        Window = window,
        Frame = frame,
        Container = frame,
        Type = mode,
        LayoutObject = layoutObject,
        Children = {},
        _Order = 0,
    }, Container)

    return object
end

function Container:_NextOrder(config)
    self._Order = self._Order + 1
    if config.LayoutOrder == nil then
        config.LayoutOrder = self._Order
    end
end

function Container:Layout(config)
    config = config or {}
    self:_NextOrder(config)

    local layout = CreateContainer(self.Window, self.Container, config)
    table.insert(self.Children, layout)
    return layout
end

function Container:Free(config)
    config = config or {}
    config.Type = "Free"
    return self:Layout(config)
end

function Container:Vertical(config)
    config = config or {}
    config.Type = "Vertical"
    return self:Layout(config)
end

function Container:Horizontal(config)
    config = config or {}
    config.Type = "Horizontal"
    return self:Layout(config)
end

function Container:Grid(config)
    config = config or {}
    config.Type = "Grid"
    return self:Layout(config)
end


--============================================================
-- Wind-style element defaults
--============================================================

local function WindRowHeight(config, base)
    if config.Size then
        return nil
    end
    if config.Height then
        return config.Height
    end
    if config.Desc or config.Description then
        return math.max(base or 46, 54)
    end
    return base or 46
end

local function CreateWindTextBlock(window, parent, config, rightOffset, zIndex)
    local padding = config.Padding or 12
    local descText = config.Desc or config.Description
    local hasDesc = descText ~= nil and tostring(descText) ~= ""

    local title = New("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(padding, hasDesc and 7 or 0),
        Size = UDim2.new(1, -(padding * 2) - (rightOffset or 0), hasDesc and 0 or 1, hasDesc and 20 or 0),
        Font = config.TitleFont or config.Font or Enum.Font.GothamMedium,
        Text = config.Title or config.Text or "Element",
        TextSize = config.TitleSize or config.TextSize or 12,
        TextXAlignment = ResolveTextX(config.Alignment or "Left"),
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = zIndex,
    })
    BindTheme(window, title, "TextColor3", config.Locked and "MutedText" or "Text", config.TitleColor or config.TextColor)
    title.Parent = parent

    local desc
    if hasDesc then
        desc = New("TextLabel", {
            Name = "Desc",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(padding, 27),
            Size = UDim2.new(1, -(padding * 2) - (rightOffset or 0), 0, 18),
            Font = config.DescFont or Enum.Font.Gotham,
            Text = tostring(descText),
            TextSize = config.DescSize or 10,
            TextWrapped = false,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = ResolveTextX(config.Alignment or "Left"),
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = zIndex,
        })
        BindTheme(window, desc, "TextColor3", "SubText", config.DescColor)
        desc.Parent = parent
    end

    return title, desc
end

local function AttachLockAPI(element, config, render)
    element.Locked = config.Locked == true

    function element:Lock()
        element.Locked = true
        if render then render() end
        return element
    end

    function element:Unlock()
        element.Locked = false
        if render then render() end
        return element
    end

    function element:SetLocked(value)
        element.Locked = value == true
        if render then render() end
        return element
    end

    return element
end

--============================================================
-- Panel
--============================================================

function Container:Panel(config)
    config = config or {}
    self:_NextOrder(config)

    local frame = New("Frame", {
        Name = config.Name or "Panel",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, 100),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.14 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 15,
        Visible = config.Visible ~= false,
        ClipsDescendants = config.ClipsDescendants == true,
    })

    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 10)

    if config.Stroke ~= false then
        local stroke = AddStroke(
            frame,
            ThemeValue(self.Window, "Stroke"),
            config.StrokeTransparency == nil and 0.93 or config.StrokeTransparency,
            config.StrokeThickness or 1
        )
        BindTheme(self.Window, stroke, "Color", "Stroke", config.StrokeColor)
    end

    frame.Parent = self.Container

    local wrapper = MakeElement(self.Window, frame)
    wrapper._container = setmetatable({
        Window = self.Window,
        Frame = frame,
        Container = frame,
        Type = "Free",
        LayoutObject = nil,
        Children = {},
        _Order = 0,
    }, Container)

    local proxies = {
        "Layout", "Free", "Vertical", "Horizontal", "Grid",
        "Panel", "Text", "Paragraph", "Icon", "Button", "Toggle", "Slider",
        "ProgressBar", "Input", "Dropdown", "Keybind", "Code",
        "Colorpicker", "ColorPicker", "Section", "Divider", "Space", "Image",
    }

    for _, method in ipairs(proxies) do
        wrapper[method] = function(_, childConfig)
            return wrapper._container[method](wrapper._container, childConfig)
        end
    end

    table.insert(self.Children, wrapper)
    return wrapper
end

--============================================================
-- Text
--============================================================

function Container:Text(config)
    config = config or {}
    self:_NextOrder(config)

    local label = New("TextLabel", {
        Name = config.Name or "Text",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, 22),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 1 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        Text = config.Text or "Text",
        Font = config.Font or Enum.Font.Gotham,
        TextSize = config.TextSize or 12,
        TextTransparency = config.TextTransparency or 0,
        TextXAlignment = ResolveTextX(config.Alignment),
        TextYAlignment = ResolveTextY(config.VerticalAlignment),
        TextWrapped = config.TextWrapped ~= false,
        RichText = config.RichText == true,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })

    BindTheme(self.Window, label, "TextColor3", "Text", config.TextColor)
    BindTheme(self.Window, label, "BackgroundColor3", "Surface", config.BackgroundColor)

    if config.CornerRadius then
        Corner(label, config.CornerRadius)
    end

    label.Parent = self.Container

    local element = MakeElement(self.Window, label)
    function element:SetText(text)
        label.Text = tostring(text)
        return element
    end

    return element
end


--============================================================
-- Icon
--============================================================

function Container:Icon(config)
    config = config or {}
    self:_NextOrder(config)

    local size = config.Size or UDim2.fromOffset(config.IconSize or 20, config.IconSize or 20)
    local icon = CreateIcon(config.Icon or config.Name or "circle", config.IconSize or math.max(size.X.Offset, size.Y.Offset, 20))
    icon.Name = config.Name or "Icon"
    icon.Position = config.Position or UDim2.fromOffset(0, 0)
    icon.Size = size
    icon.AnchorPoint = config.AnchorPoint or Vector2.zero
    icon.BackgroundTransparency = config.BackgroundTransparency == nil and 1 or config.BackgroundTransparency
    icon.LayoutOrder = config.LayoutOrder
    icon.ZIndex = config.ZIndex or 20
    icon.Visible = config.Visible ~= false
    BindTheme(self.Window, icon, "ImageColor3", "Icon", config.Color or config.IconColor or config.ImageColor)
    icon.Parent = self.Container

    local element = MakeElement(self.Window, icon)
    element.Image = icon

    function element:SetIcon(name)
        icon.Image = GetIcon(name)
        return element
    end

    return element
end

--============================================================
-- Paragraph
--============================================================

function Container:Paragraph(config)
    config = config or {}
    self:_NextOrder(config)

    local height = config.Height or 70
    local frame = New("Frame", {
        Name = config.Name or "Paragraph",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, height),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.12 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 15,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 9)

    if config.Stroke ~= false then
        local stroke = AddStroke(frame, ThemeValue(self.Window, "Stroke"), config.StrokeTransparency == nil and 0.94 or config.StrokeTransparency, 1)
        BindTheme(self.Window, stroke, "Color", "Stroke", config.StrokeColor)
    end

    local iconSize = config.Icon and (config.IconSize or 18) or 0
    local left = config.Padding or 12
    local textLeft = left + (iconSize > 0 and iconSize + 10 or 0)

    if config.Icon then
        local icon = CreateIcon(config.Icon, iconSize)
        icon.Position = UDim2.fromOffset(left, 13)
        icon.ZIndex = frame.ZIndex + 2
        BindTheme(self.Window, icon, "ImageColor3", "Icon", config.IconColor)
        icon.Parent = frame
    end

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(textLeft, 10),
        Size = UDim2.new(1, -textLeft - left, 0, 20),
        Font = config.TitleFont or Enum.Font.GothamMedium,
        Text = config.Title or config.Text or "Paragraph",
        TextSize = config.TitleSize or 12,
        TextXAlignment = ResolveTextX(config.Alignment),
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, title, "TextColor3", "Text", config.TitleColor)
    title.Parent = frame

    local desc = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(textLeft, 31),
        Size = UDim2.new(1, -textLeft - left, 1, -39),
        Font = config.DescFont or Enum.Font.Gotham,
        Text = config.Desc or config.Description or "",
        TextSize = config.DescSize or 10,
        TextWrapped = true,
        TextXAlignment = ResolveTextX(config.Alignment),
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, desc, "TextColor3", "SubText", config.DescColor)
    desc.Parent = frame

    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.TitleLabel = title
    element.DescLabel = desc

    function element:SetTitle(value)
        title.Text = tostring(value)
        return element
    end

    function element:SetDesc(value)
        desc.Text = tostring(value)
        return element
    end

    return element
end

--============================================================
-- Button
--============================================================

function Container:Button(config)
    config = config or {}
    self:_NextOrder(config)

    local height = WindRowHeight(config, 46)
    local button = New("TextButton", {
        Name = config.Name or "Button",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, height),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, button, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(button, config.CornerRadius or 9)

    if config.Stroke ~= false then
        local stroke = AddStroke(button, ThemeValue(self.Window, "Stroke"),
            config.StrokeTransparency == nil and 0.94 or config.StrokeTransparency,
            config.StrokeThickness or 1)
        BindTheme(self.Window, stroke, "Color", "Stroke", config.StrokeColor)
    end

    local rightOffset = config.Icon == false and 0 or 34
    local title, desc = CreateWindTextBlock(self.Window, button, config, rightOffset, button.ZIndex + 2)

    local icon
    if config.Icon ~= false then
        icon = CreateIcon(config.Icon or "mouse-pointer-click", config.IconSize or 17)
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Position = UDim2.new(1, -(config.Padding or 12), 0.5, 0)
        icon.ZIndex = button.ZIndex + 2
        BindTheme(self.Window, icon, "ImageColor3", config.Locked and "MutedText" or "Icon", config.IconColor)
        icon.Parent = button
    end

    button.Parent = self.Container
    local element = MakeElement(self.Window, button)
    element.TitleLabel = title
    element.DescLabel = desc
    element.IconImage = icon

    local normalTransparency = button.BackgroundTransparency
    local hoverTransparency = config.HoverTransparency == nil and math.max(0, normalTransparency - 0.05) or config.HoverTransparency

    local function renderLock()
        local locked = element.Locked == true
        if title then
            title.TextColor3 = locked and ThemeValue(self.Window, "MutedText") or (config.TextColor or ThemeValue(self.Window, "Text"))
        end
        if icon then
            icon.ImageColor3 = locked and ThemeValue(self.Window, "MutedText") or (config.IconColor or ThemeValue(self.Window, "Icon"))
        end
        button.BackgroundTransparency = locked and math.min(1, normalTransparency + 0.04) or normalTransparency
    end

    AttachLockAPI(element, config, renderLock)

    button.MouseEnter:Connect(function()
        if element.Locked then return end
        Tween(button, 0.14, {BackgroundTransparency = hoverTransparency})
    end)

    button.MouseLeave:Connect(function()
        Tween(button, 0.14, {BackgroundTransparency = element.Locked and math.min(1, normalTransparency + 0.04) or normalTransparency})
    end)

    button.MouseButton1Click:Connect(function()
        if element.Locked then return end
        SafeCallback(config.Callback)
    end)

    function element:OnClick(callback)
        button.MouseButton1Click:Connect(function()
            if not element.Locked then SafeCallback(callback) end
        end)
        return element
    end

    function element:SetTitle(value)
        title.Text = tostring(value)
        return element
    end
    element.SetText = element.SetTitle

    function element:SetDesc(value)
        if desc then desc.Text = tostring(value) end
        return element
    end

    renderLock()
    return element
end

--============================================================
-- Toggle
--============================================================

function Container:Toggle(config)
    config = config or {}
    self:_NextOrder(config)

    local value = config.Value
    if value == nil then value = config.Default end
    value = value == true

    local height = WindRowHeight(config, 46)
    local frame = New("TextButton", {
        Name = config.Name or "Toggle",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, height),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 9)

    local title, desc = CreateWindTextBlock(self.Window, frame, config, 58, frame.ZIndex + 2)
    local padding = config.Padding or 12

    local track = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -padding, 0.5, 0),
        Size = config.SwitchSize or UDim2.fromOffset(38, 20),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 2,
    })
    Corner(track, 999)
    track.Parent = frame

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 3,
    })
    Corner(knob, 999)
    knob.Parent = track

    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.Value = value
    element.TitleLabel = title
    element.DescLabel = desc
    element.Track = track
    element.Knob = knob

    local function render(instant)
        local enabled = element.Value and not element.Locked
        local targetColor = enabled
            and (config.ActiveColor or ThemeValue(self.Window, "Accent"))
            or (config.InactiveColor or ThemeValue(self.Window, "Surface2"))
        local targetPosition = element.Value and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0)

        if instant then
            track.BackgroundColor3 = targetColor
            knob.Position = targetPosition
        else
            Tween(track, 0.18, {BackgroundColor3 = targetColor})
            Tween(knob, 0.18, {Position = targetPosition})
        end
        title.TextColor3 = element.Locked and ThemeValue(self.Window, "MutedText") or (config.TextColor or ThemeValue(self.Window, "Text"))
    end

    AttachLockAPI(element, config, function() render(true) end)

    function element:Set(newValue, fireCallback)
        if element.Locked then return element end
        element.Value = newValue == true
        render(false)
        if fireCallback ~= false then SafeCallback(config.Callback, element.Value) end
        return element
    end

    function element:GetValue()
        return element.Value
    end

    function element:SetTitle(value2)
        title.Text = tostring(value2)
        return element
    end

    function element:SetDesc(value2)
        if desc then desc.Text = tostring(value2) end
        return element
    end

    frame.MouseButton1Click:Connect(function()
        if not element.Locked then element:Set(not element.Value, true) end
    end)

    render(true)
    return element
end

--============================================================
-- Slider
--============================================================

function Container:Slider(config)
    config = config or {}
    self:_NextOrder(config)

    local valueTable = typeof(config.Value) == "table" and config.Value or nil
    local minValue = tonumber(config.Min) or tonumber(valueTable and valueTable.Min) or 0
    local maxValue = tonumber(config.Max) or tonumber(valueTable and valueTable.Max) or 100
    if maxValue <= minValue then maxValue = minValue + 1 end

    local step = tonumber(config.Step) or 1
    local value = valueTable and tonumber(valueTable.Default) or tonumber(config.Value)
    if value == nil then value = tonumber(config.Default) end
    if value == nil then value = minValue end
    value = math.clamp(RoundToStep(value, step), minValue, maxValue)

    local height = config.Size and nil or (config.Height or ((config.Desc or config.Description) and 66 or 58))
    local frame = New("Frame", {
        Name = config.Name or "Slider",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, height),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 9)

    local title, desc = CreateWindTextBlock(self.Window, frame, config, 148, frame.ZIndex + 2)
    local padding = config.Padding or 12
    local controlWidth = config.Width or 130

    local valueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -padding, 0, 7),
        Size = UDim2.fromOffset(44, 18),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = config.ValueTextSize or 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = frame.ZIndex + 3,
    })
    BindTheme(self.Window, valueLabel, "TextColor3", "SubText", config.ValueTextColor)
    valueLabel.Parent = frame

    local track = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -padding - 50, 0.5, 0),
        Size = UDim2.fromOffset(controlWidth, config.TrackHeight or 5),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, track, "BackgroundColor3", "Surface2", config.TrackColor)
    Corner(track, 999)
    track.Parent = frame

    local fill = New("Frame", {Size = UDim2.new(0,0,1,0), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = track.ZIndex + 1})
    BindTheme(self.Window, fill, "BackgroundColor3", "Accent", config.FillColor)
    Corner(fill, 999)
    fill.Parent = track

    local thumb = New("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0,0,0.5,0),
        Size = UDim2.fromOffset(config.ThumbSize or 13, config.ThumbSize or 13),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel = 0,
        ZIndex = track.ZIndex + 2,
    })
    Corner(thumb, 999)
    thumb.Parent = track

    local hitbox = New("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,-9),
        Size = UDim2.new(1,0,1,18),
        Text = "",
        AutoButtonColor = false,
        ZIndex = track.ZIndex + 5,
    })
    hitbox.Parent = track
    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.Value = value
    element.TitleLabel = title
    element.DescLabel = desc

    local function render()
        local alpha = (element.Value - minValue) / (maxValue - minValue)
        fill.Size = UDim2.new(alpha,0,1,0)
        thumb.Position = UDim2.new(alpha,0,0.5,0)
        valueLabel.Text = (config.Prefix or "") .. FormatNumber(element.Value) .. (config.Suffix or "")
        title.TextColor3 = element.Locked and ThemeValue(self.Window, "MutedText") or (config.TextColor or ThemeValue(self.Window, "Text"))
    end

    AttachLockAPI(element, config, render)

    function element:Set(newValue, fireCallback)
        if element.Locked then return element end
        local numeric = math.clamp(RoundToStep(tonumber(newValue) or minValue, step), minValue, maxValue)
        element.Value = numeric
        render()
        if fireCallback ~= false then SafeCallback(config.Callback, numeric) end
        return element
    end

    function element:GetValue() return element.Value end

    local dragging = false
    local function updateFromX(x)
        if element.Locked then return end
        local left = track.AbsolutePosition.X
        local width = math.max(track.AbsoluteSize.X,1)
        local alpha = math.clamp((x-left)/width,0,1)
        element:Set(minValue + ((maxValue-minValue)*alpha), true)
    end

    hitbox.InputBegan:Connect(function(input)
        if element.Locked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    render()
    return element
end

--============================================================
-- ProgressBar
--============================================================

function Container:ProgressBar(config)
    config = config or {}
    self:_NextOrder(config)

    local minValue = tonumber(config.Min) or 0
    local maxValue = tonumber(config.Max) or 100
    if maxValue <= minValue then maxValue = minValue + 1 end

    local value = tonumber(config.Value) or tonumber(config.Default) or minValue
    value = math.clamp(value, minValue, maxValue)

    local frame = New("Frame", {
        Name = config.Name or "ProgressBar",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 50),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 8)

    local padding = config.Padding or 12
    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(padding, 6),
        Size = UDim2.new(1, -90, 0, 18),
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Progress",
        TextSize = config.TextSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, title, "TextColor3", "Text", config.TextColor)
    title.Parent = frame

    local valueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -padding, 0, 6),
        Size = UDim2.fromOffset(68, 18),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, valueLabel, "TextColor3", "SubText", config.ValueTextColor)
    valueLabel.Parent = frame

    local track = New("Frame", {
        Position = UDim2.new(0, padding, 1, -14),
        Size = UDim2.new(1, -(padding * 2), 0, config.TrackHeight or 5),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, track, "BackgroundColor3", "Surface2", config.TrackColor)
    Corner(track, 999)
    track.Parent = frame

    local fill = New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = track.ZIndex + 1,
    })
    BindTheme(self.Window, fill, "BackgroundColor3", "Accent", config.FillColor)
    Corner(fill, 999)
    fill.Parent = track

    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.Value = value

    local function render(animated)
        local alpha = (element.Value - minValue) / (maxValue - minValue)
        if animated then
            Tween(fill, config.TweenTime or 0.22, { Size = UDim2.new(alpha, 0, 1, 0) })
        else
            fill.Size = UDim2.new(alpha, 0, 1, 0)
        end
        valueLabel.Text = (config.Prefix or "") .. FormatNumber(element.Value) .. (config.Suffix or "%")
    end

    function element:Set(newValue, animated)
        element.Value = math.clamp(tonumber(newValue) or minValue, minValue, maxValue)
        render(animated ~= false)
        return element
    end

    function element:GetValue()
        return element.Value
    end

    render(false)
    return element
end

--============================================================
-- Input
--============================================================

function Container:Input(config)
    config = config or {}
    self:_NextOrder(config)

    local frame = New("Frame", {
        Name = config.Name or "Input",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 64),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 8)

    local padding = config.Padding or 12
    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(padding, 6),
        Size = UDim2.new(1, -(padding * 2), 0, 17),
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Input",
        TextSize = config.TitleSize or 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, title, "TextColor3", "SubText", config.TitleColor)
    title.Parent = frame

    local boxFrame = New("Frame", {
        Position = UDim2.new(0, padding, 0, 28),
        Size = UDim2.new(1, -(padding * 2), 0, config.InputHeight or 27),
        BackgroundTransparency = config.InputTransparency == nil and 0.05 or config.InputTransparency,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, boxFrame, "BackgroundColor3", "Input", config.InputColor)
    Corner(boxFrame, config.InputCornerRadius or 7)
    boxFrame.Parent = frame

    local textBox = New("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(9, 0),
        Size = UDim2.new(1, -18, 1, 0),
        ClearTextOnFocus = config.ClearTextOnFocus == true,
        Text = tostring(config.Value or config.Default or ""),
        PlaceholderText = config.Placeholder or "Enter text...",
        Font = config.Font or Enum.Font.Gotham,
        TextSize = config.TextSize or 11,
        TextXAlignment = ResolveTextX(config.Alignment or "Left"),
        TextYAlignment = Enum.TextYAlignment.Center,
        MultiLine = config.MultiLine == true,
        TextWrapped = config.MultiLine == true,
        ZIndex = boxFrame.ZIndex + 2,
    })
    BindTheme(self.Window, textBox, "TextColor3", "Text", config.TextColor)
    BindTheme(self.Window, textBox, "PlaceholderColor3", "MutedText", config.PlaceholderColor)
    textBox.Parent = boxFrame

    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.TextBox = textBox
    element.Value = textBox.Text

    function element:Set(value, fireCallback)
        element.Value = tostring(value or "")
        textBox.Text = element.Value
        if fireCallback == true then
            SafeCallback(config.Callback, element.Value)
        end
        return element
    end

    function element:GetValue()
        return textBox.Text
    end

    textBox.FocusLost:Connect(function(enterPressed)
        element.Value = textBox.Text
        SafeCallback(config.Callback, element.Value, enterPressed)
    end)

    if config.LiveCallback == true then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            element.Value = textBox.Text
            SafeCallback(config.Callback, element.Value, false)
        end)
    end

    return element
end

--============================================================
-- Dropdown
--============================================================

function Container:Dropdown(config)
    config = config or {}
    self:_NextOrder(config)

    local values = config.Values or config.Options or {}
    local selected = config.Value or config.Default or values[1]
    local open = false

    local rowHeight = config.RowHeight or 30
    local maxVisible = config.MaxVisible or 5
    local closedHeight = config.Height or 42
    local listHeight = math.min(#values, maxVisible) * rowHeight + 8

    local holder = New("Frame", {
        Name = config.Name or "Dropdown",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, closedHeight),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 30,
        Visible = config.Visible ~= false,
        ClipsDescendants = false,
    })

    local main = New("TextButton", {
        Size = UDim2.new(1, 0, 0, closedHeight),
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.08 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = holder.ZIndex + 2,
    })
    BindTheme(self.Window, main, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(main, config.CornerRadius or 8)
    main.Parent = holder

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.5, -12, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Dropdown",
        TextSize = config.TextSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = main.ZIndex + 2,
    })
    BindTheme(self.Window, title, "TextColor3", "Text", config.TextColor)
    title.Parent = main

    local selectedLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -35, 0, 0),
        Size = UDim2.new(0.45, -6, 1, 0),
        Font = Enum.Font.Gotham,
        Text = selected == nil and (config.Placeholder or "Select") or tostring(selected),
        TextSize = config.ValueTextSize or 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = main.ZIndex + 2,
    })
    BindTheme(self.Window, selectedLabel, "TextColor3", "SubText", config.ValueTextColor)
    selectedLabel.Parent = main

    local arrow = CreateIcon("chevron-down", 14)
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -11, 0.5, 0)
    arrow.ZIndex = main.ZIndex + 3
    BindTheme(self.Window, arrow, "ImageColor3", "Icon", config.IconColor)
    arrow.Parent = main

    local popup = New("Frame", {
        Position = UDim2.new(0, 0, 0, closedHeight + 5),
        Size = UDim2.new(1, 0, 0, listHeight),
        BackgroundTransparency = config.PopupTransparency == nil and 0.03 or config.PopupTransparency,
        BorderSizePixel = 0,
        ZIndex = holder.ZIndex + 20,
        Visible = false,
        ClipsDescendants = true,
    })
    BindTheme(self.Window, popup, "BackgroundColor3", "Surface2", config.PopupColor)
    Corner(popup, config.PopupCornerRadius or 8)
    local popupStroke = AddStroke(popup, ThemeValue(self.Window, "Stroke"), 0.92, 1)
    BindTheme(self.Window, popupStroke, "Color", "Stroke", config.PopupStrokeColor)
    popup.Parent = holder

    local scroll = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageTransparency = 0.75,
        ZIndex = popup.ZIndex + 1,
    })
    scroll.Parent = popup

    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = scroll,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scroll,
    })

    holder.Parent = self.Container

    local element = MakeElement(self.Window, holder)
    element.Value = selected
    element.Popup = popup

    local function close()
        open = false
        popup.Visible = false
        Tween(arrow, 0.15, { Rotation = 0 })
    end

    local function choose(value, fireCallback)
        element.Value = value
        selectedLabel.Text = value == nil and (config.Placeholder or "Select") or tostring(value)
        close()
        if fireCallback ~= false then
            SafeCallback(config.Callback, value)
        end
    end

    local function rebuild()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        for index, option in ipairs(values) do
            local optionButton = New("TextButton", {
                Size = UDim2.new(1, 0, 0, rowHeight),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "  " .. tostring(option),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = index,
                ZIndex = scroll.ZIndex + 2,
            })
            BindTheme(self.Window, optionButton, "TextColor3", "Text", config.OptionTextColor)
            BindTheme(self.Window, optionButton, "BackgroundColor3", "SurfaceHover", config.OptionHoverColor)
            Corner(optionButton, 6)
            optionButton.Parent = scroll

            optionButton.MouseEnter:Connect(function()
                Tween(optionButton, 0.12, { BackgroundTransparency = 0.35 })
            end)

            optionButton.MouseLeave:Connect(function()
                Tween(optionButton, 0.12, { BackgroundTransparency = 1 })
            end)

            optionButton.MouseButton1Click:Connect(function()
                choose(option, true)
            end)
        end
    end

    function element:Set(value, fireCallback)
        choose(value, fireCallback)
        return element
    end

    function element:GetValue()
        return element.Value
    end

    function element:SetValues(newValues)
        values = newValues or {}
        listHeight = math.min(#values, maxVisible) * rowHeight + 8
        popup.Size = UDim2.new(1, 0, 0, listHeight)
        rebuild()
        return element
    end

    function element:Open()
        open = true
        popup.Visible = true
        Tween(arrow, 0.15, { Rotation = 180 })
        return element
    end

    function element:Close()
        close()
        return element
    end

    main.MouseButton1Click:Connect(function()
        if open then
            close()
        else
            element:Open()
        end
    end)

    rebuild()
    return element
end

--============================================================
-- Keybind
--============================================================

function Container:Keybind(config)
    config = config or {}
    self:_NextOrder(config)

    local value = config.Value or config.Default or "RightShift"
    local picking = false

    local frame = New("TextButton", {
        Name = config.Name or "Keybind",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 42),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 8)

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -120, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Keybind",
        TextSize = config.TextSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, title, "TextColor3", "Text", config.TextColor)
    title.Parent = frame

    local keyLabel = New("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(config.KeyWidth or 92, 26),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        Text = tostring(value),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, keyLabel, "BackgroundColor3", "Input", config.KeyBackgroundColor)
    BindTheme(self.Window, keyLabel, "TextColor3", "SubText", config.KeyTextColor)
    Corner(keyLabel, 6)
    keyLabel.Parent = frame

    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.Value = value

    function element:Set(newValue, fireCallback)
        element.Value = tostring(newValue)
        keyLabel.Text = element.Value
        if fireCallback == true then
            SafeCallback(config.Changed, element.Value)
        end
        return element
    end

    function element:GetValue()
        return element.Value
    end

    frame.MouseButton1Click:Connect(function()
        picking = true
        keyLabel.Text = "..."
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if picking then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                picking = false
                element:Set(input.KeyCode.Name, true)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                picking = false
                element:Set("MouseButton1", true)
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                picking = false
                element:Set("MouseButton2", true)
            end
            return
        end

        if gameProcessed or UserInputService:GetFocusedTextBox() then
            return
        end

        local matched = false
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == element.Value then
            matched = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 and element.Value == "MouseButton1" then
            matched = true
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 and element.Value == "MouseButton2" then
            matched = true
        end

        if matched then
            SafeCallback(config.Callback, element.Value)
        end
    end)

    return element
end

--============================================================
-- Code
--============================================================

function Container:Code(config)
    config = config or {}
    self:_NextOrder(config)

    local frame = New("Frame", {
        Name = config.Name or "Code",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 150),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.06 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
        ClipsDescendants = true,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Input", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 8)

    local titleHeight = config.Title and 28 or 0

    if config.Title then
        local title = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 0, 28),
            Font = Enum.Font.GothamMedium,
            Text = config.Title,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = frame.ZIndex + 2,
        })
        BindTheme(self.Window, title, "TextColor3", "SubText", config.TitleColor)
        title.Parent = frame
    end

    local scroll = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, titleHeight),
        Size = UDim2.new(1, 0, 1, -titleHeight),
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.XY,
        ScrollBarThickness = 2,
        ScrollBarImageTransparency = 0.75,
        ZIndex = frame.ZIndex + 2,
    })
    scroll.Parent = frame

    local label = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 8),
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Font = config.Font or Enum.Font.Code,
        Text = config.Code or config.Text or "",
        TextSize = config.TextSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = config.TextWrapped == true,
        RichText = config.RichText == true,
        ZIndex = scroll.ZIndex + 1,
    })
    BindTheme(self.Window, label, "TextColor3", "Text", config.TextColor)
    label.Parent = scroll

    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.TextLabel = label

    function element:SetCode(text)
        label.Text = tostring(text or "")
        return element
    end

    function element:GetCode()
        return label.Text
    end

    return element
end


--============================================================
-- Colorpicker (Wind-style compact row)
--============================================================

function Container:Colorpicker(config)
    config = config or {}
    self:_NextOrder(config)

    local value = config.Value or config.Default or Color3.new(1, 1, 1)
    if typeof(value) ~= "Color3" then value = Color3.new(1, 1, 1) end
    local transparency = math.clamp(tonumber(config.Transparency) or 0, 0, 1)
    local baseHeight = WindRowHeight(config, 46)

    local frame = New("Frame", {
        Name = config.Name or "Colorpicker",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, baseHeight),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
        ClipsDescendants = true,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 9)

    local title, desc = CreateWindTextBlock(self.Window, frame, config, 50, frame.ZIndex + 2)

    local preview = New("TextButton", {
        Name = "Preview",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -(config.Padding or 12), 0, baseHeight / 2),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = value,
        BackgroundTransparency = transparency,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = frame.ZIndex + 3,
    })
    Corner(preview, 8)
    AddStroke(preview, ThemeValue(self.Window, "Stroke"), 0.82, 1)
    preview.Parent = frame

    local editor = New("Frame", {
        Name = "Editor",
        Position = UDim2.fromOffset(12, baseHeight + 4),
        Size = UDim2.new(1, -24, 0, 82),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = frame.ZIndex + 2,
    })
    editor.Parent = frame

    local labels = {"R", "G", "B"}
    local rows = {}

    for i = 1, 3 do
        local y = (i - 1) * 26
        local label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, y),
            Size = UDim2.fromOffset(18, 20),
            Text = labels[i],
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = editor.ZIndex + 1,
        })
        BindTheme(self.Window, label, "TextColor3", "SubText")
        label.Parent = editor

        local track = New("Frame", {
            Position = UDim2.fromOffset(22, y + 8),
            Size = UDim2.new(1, -70, 0, 5),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = editor.ZIndex + 1,
        })
        BindTheme(self.Window, track, "BackgroundColor3", "Surface2")
        Corner(track, 999)
        track.Parent = editor

        local fill = New("Frame", {Size = UDim2.new(0,0,1,0), BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = track.ZIndex + 1})
        BindTheme(self.Window, fill, "BackgroundColor3", "Accent")
        Corner(fill, 999)
        fill.Parent = track

        local box = New("TextBox", {
            AnchorPoint = Vector2.new(1,0),
            Position = UDim2.new(1,0,0,y),
            Size = UDim2.fromOffset(42,20),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            Text = "0",
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = editor.ZIndex + 2,
        })
        BindTheme(self.Window, box, "BackgroundColor3", "Input")
        BindTheme(self.Window, box, "TextColor3", "Text")
        Corner(box, 6)
        box.Parent = editor

        rows[i] = {Track=track, Fill=fill, Box=box, Hitbox=CreateHitbox(track, track.ZIndex+5)}
    end

    frame.Parent = self.Container
    local element = MakeElement(self.Window, frame)
    element.Value = value
    element.Transparency = transparency
    element.Opened = false
    element.TitleLabel = title
    element.DescLabel = desc

    local function rgb(c)
        return math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5)
    end

    local function render()
        local r,g,b = rgb(element.Value)
        local nums = {r,g,b}
        preview.BackgroundColor3 = element.Value
        preview.BackgroundTransparency = element.Transparency
        for i,row in ipairs(rows) do
            row.Fill.Size = UDim2.new(nums[i]/255,0,1,0)
            row.Box.Text = tostring(nums[i])
        end
        title.TextColor3 = element.Locked and ThemeValue(self.Window, "MutedText") or (config.TextColor or ThemeValue(self.Window, "Text"))
    end

    local function fire()
        SafeCallback(config.Callback, element.Value, element.Transparency)
    end

    local function setComponent(index, numeric)
        if element.Locked then return end
        local r,g,b = rgb(element.Value)
        local nums = {r,g,b}
        nums[index] = math.clamp(math.floor((tonumber(numeric) or 0)+0.5),0,255)
        element.Value = Color3.fromRGB(nums[1],nums[2],nums[3])
        render()
        fire()
    end

    function element:Set(color, newTransparency, fireCallback)
        if element.Locked then return element end
        if typeof(color) == "Color3" then element.Value = color end
        if typeof(newTransparency) == "number" then element.Transparency = math.clamp(newTransparency,0,1) end
        render()
        if fireCallback ~= false then fire() end
        return element
    end

    function element:GetValue()
        return element.Value
    end

    function element:SetOpen(opened)
        if element.Locked then return element end
        element.Opened = opened == true
        editor.Visible = element.Opened
        frame.Size = config.Size or UDim2.new(1,0,0, element.Opened and (baseHeight + 94) or baseHeight)
        return element
    end

    AttachLockAPI(element, config, render)

    preview.MouseButton1Click:Connect(function()
        if not element.Locked then element:SetOpen(not element.Opened) end
    end)

    for index,row in ipairs(rows) do
        local dragging = false
        local function update(x)
            if element.Locked then return end
            local left = row.Track.AbsolutePosition.X
            local width = math.max(row.Track.AbsoluteSize.X,1)
            setComponent(index, math.clamp((x-left)/width,0,1)*255)
        end
        row.Hitbox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        row.Box.FocusLost:Connect(function() setComponent(index,row.Box.Text) end)
    end

    render()
    return element
end

--============================================================
-- ColorPicker (compact RGB editor)
--============================================================

function Container:ColorPicker(config)
    config = config or {}
    self:_NextOrder(config)

    local value = config.Value or config.Default or Color3.fromRGB(255, 255, 255)
    if typeof(value) ~= "Color3" then
        value = Color3.fromRGB(255, 255, 255)
    end

    local frame = New("Frame", {
        Name = config.Name or "ColorPicker",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 112),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })
    BindTheme(self.Window, frame, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(frame, config.CornerRadius or 8)

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.new(1, -60, 0, 20),
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Color",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = frame.ZIndex + 2,
    })
    BindTheme(self.Window, title, "TextColor3", "Text", config.TextColor)
    title.Parent = frame

    local preview = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 8),
        Size = UDim2.fromOffset(28, 20),
        BackgroundColor3 = value,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 2,
    })
    Corner(preview, 6)
    preview.Parent = frame

    local rows = {}
    local components = { "R", "G", "B" }

    for index, component in ipairs(components) do
        local y = 34 + ((index - 1) * 24)

        local label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, y),
            Size = UDim2.fromOffset(18, 18),
            Font = Enum.Font.GothamMedium,
            Text = component,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = frame.ZIndex + 2,
        })
        BindTheme(self.Window, label, "TextColor3", "SubText")
        label.Parent = frame

        local track = New("Frame", {
            Position = UDim2.fromOffset(34, y + 7),
            Size = UDim2.new(1, -88, 0, 4),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = frame.ZIndex + 2,
        })
        BindTheme(self.Window, track, "BackgroundColor3", "Surface2")
        Corner(track, 999)
        track.Parent = frame

        local fill = New("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = track.ZIndex + 1,
        })
        if component == "R" then
            fill.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
        elseif component == "G" then
            fill.BackgroundColor3 = Color3.fromRGB(90, 220, 130)
        else
            fill.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
        end
        Corner(fill, 999)
        fill.Parent = track

        local box = New("TextBox", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, y),
            Size = UDim2.fromOffset(40, 18),
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            Text = "0",
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = frame.ZIndex + 3,
        })
        BindTheme(self.Window, box, "BackgroundColor3", "Input")
        BindTheme(self.Window, box, "TextColor3", "Text")
        Corner(box, 5)
        box.Parent = frame

        local hitbox = CreateHitbox(track, track.ZIndex + 5)
        rows[index] = { Track = track, Fill = fill, Box = box, Hitbox = hitbox }
    end

    frame.Parent = self.Container

    local element = MakeElement(self.Window, frame)
    element.Value = value

    local function componentsFromColor(color)
        return math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)
    end

    local function render()
        local r, g, b = componentsFromColor(element.Value)
        local nums = { r, g, b }
        preview.BackgroundColor3 = element.Value

        for i, row in ipairs(rows) do
            local alpha = nums[i] / 255
            row.Fill.Size = UDim2.new(alpha, 0, 1, 0)
            row.Box.Text = tostring(nums[i])
        end
    end

    local function setComponent(index, numeric, fireCallback)
        local r, g, b = componentsFromColor(element.Value)
        local nums = { r, g, b }
        nums[index] = math.clamp(math.floor((tonumber(numeric) or 0) + 0.5), 0, 255)
        element.Value = Color3.fromRGB(nums[1], nums[2], nums[3])
        render()
        if fireCallback ~= false then
            SafeCallback(config.Callback, element.Value)
        end
    end

    function element:Set(color, fireCallback)
        if typeof(color) ~= "Color3" then
            return element
        end
        element.Value = color
        render()
        if fireCallback ~= false then
            SafeCallback(config.Callback, element.Value)
        end
        return element
    end

    function element:GetValue()
        return element.Value
    end

    for index, row in ipairs(rows) do
        local dragging = false

        local function update(x)
            local left = row.Track.AbsolutePosition.X
            local width = math.max(row.Track.AbsoluteSize.X, 1)
            local alpha = math.clamp((x - left) / width, 0, 1)
            setComponent(index, alpha * 255, true)
        end

        row.Hitbox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input.Position.X)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        row.Box.FocusLost:Connect(function()
            setComponent(index, row.Box.Text, true)
        end)
    end

    render()
    return element
end

--============================================================
-- Divider / Space / Image
--============================================================

function Container:Divider(config)
    config = config or {}
    self:_NextOrder(config)

    local holder = New("Frame", {
        Name = config.Name or "Divider",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 13),
        BackgroundTransparency = 1,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 15,
    })

    local line = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -(config.Inset or 0), 0, config.Thickness or 1),
        BackgroundTransparency = config.Transparency == nil and 0.91 or config.Transparency,
        BorderSizePixel = 0,
        ZIndex = holder.ZIndex + 1,
    })
    BindTheme(self.Window, line, "BackgroundColor3", "Stroke", config.Color)
    line.Parent = holder

    holder.Parent = self.Container
    local element = MakeElement(self.Window, holder)
    element.Line = line
    return element
end

function Container:Space(config)
    config = config or {}
    self:_NextOrder(config)

    local space = New("Frame", {
        Name = config.Name or "Space",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 12),
        BackgroundTransparency = 1,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 10,
    })
    space.Parent = self.Container
    return MakeElement(self.Window, space)
end

function Container:Image(config)
    config = config or {}
    self:_NextOrder(config)

    local image = New("ImageLabel", {
        Name = config.Name or "Image",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, config.Height or 160),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 1 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        Image = config.Icon and GetIcon(config.Icon) or (config.Image or ""),
        ImageTransparency = config.ImageTransparency or 0,
        ScaleType = config.ScaleType or Enum.ScaleType.Crop,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
    })

    if config.Icon then
        BindTheme(self.Window, image, "ImageColor3", "Icon", config.ImageColor)
    elseif config.ImageColor then
        image.ImageColor3 = config.ImageColor
    end

    if config.BackgroundColor then
        image.BackgroundColor3 = config.BackgroundColor
    else
        BindTheme(self.Window, image, "BackgroundColor3", "Surface")
    end

    if config.CornerRadius then
        Corner(image, config.CornerRadius)
    end

    if config.AspectRatio then
        local ratio = config.AspectRatio
        if typeof(ratio) == "string" then
            local a, b = string.match(ratio, "(%d+):(%d+)")
            if a and b then
                ratio = tonumber(a) / tonumber(b)
            end
        end

        if typeof(ratio) == "number" then
            New("UIAspectRatioConstraint", {
                AspectRatio = ratio,
                DominantAxis = Enum.DominantAxis.Width,
                Parent = image,
            })
        end
    end

    image.Parent = self.Container

    local element = MakeElement(self.Window, image)
    function element:SetImage(value)
        image.Image = value
        return element
    end
    return element
end

--============================================================
-- Section
--============================================================

function Container:Section(config)
    config = config or {}
    self:_NextOrder(config)

    local opened = config.Opened ~= false
    local collapsible = config.Collapsible ~= false
    local headerHeight = config.HeaderHeight or 42
    local contentPadding = config.Padding or 10

    local root = New("Frame", {
        Name = config.Name or "Section",
        Position = config.Position or UDim2.fromOffset(0, 0),
        Size = config.Size or UDim2.new(1, 0, 0, headerHeight),
        AnchorPoint = config.AnchorPoint or Vector2.zero,
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.10 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        LayoutOrder = config.LayoutOrder,
        ZIndex = config.ZIndex or 20,
        Visible = config.Visible ~= false,
        ClipsDescendants = true,
    })
    BindTheme(self.Window, root, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(root, config.CornerRadius or 9)

    if config.Stroke ~= false then
        local stroke = AddStroke(root, ThemeValue(self.Window, "Stroke"), config.StrokeTransparency == nil and 0.94 or config.StrokeTransparency, 1)
        BindTheme(self.Window, stroke, "Color", "Stroke", config.StrokeColor)
    end

    local header = New("TextButton", {
        Size = UDim2.new(1, 0, 0, headerHeight),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = root.ZIndex + 2,
    })
    header.Parent = root

    local iconOffset = 12
    if config.Icon then
        local icon = CreateIcon(config.Icon, config.IconSize or 17)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 12, 0.5, 0)
        icon.ZIndex = header.ZIndex + 2
        BindTheme(self.Window, icon, "ImageColor3", "Icon", config.IconColor)
        icon.Parent = header
        iconOffset = 39
    end

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(iconOffset, 0),
        Size = UDim2.new(1, -iconOffset - 38, 1, 0),
        Font = config.Font or Enum.Font.GothamMedium,
        Text = config.Title or "Section",
        TextSize = config.TextSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = header.ZIndex + 2,
    })
    BindTheme(self.Window, title, "TextColor3", "Text", config.TextColor)
    title.Parent = header

    local arrow
    if collapsible then
        arrow = CreateIcon("chevron-down", 14)
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -12, 0.5, 0)
        arrow.ZIndex = header.ZIndex + 2
        BindTheme(self.Window, arrow, "ImageColor3", "Icon", config.ArrowColor)
        arrow.Parent = header
    end

    local content = New("Frame", {
        Position = UDim2.fromOffset(0, headerHeight),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = opened,
        ZIndex = root.ZIndex + 1,
    })
    content.Parent = root

    New("UIPadding", {
        PaddingLeft = UDim.new(0, contentPadding),
        PaddingRight = UDim.new(0, contentPadding),
        PaddingBottom = UDim.new(0, contentPadding),
        Parent = content,
    })

    local contentLayout = New("UIListLayout", {
        Padding = UDim.new(0, config.Gap or 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = content,
    })

    root.Parent = self.Container

    local section = setmetatable({
        Window = self.Window,
        Instance = root,
        Root = root,
        Header = header,
        Content = content,
        LayoutObject = contentLayout,
        Opened = opened,
        Collapsible = collapsible,
        _container = setmetatable({
            Window = self.Window,
            Frame = content,
            Container = content,
            Type = "Vertical",
            LayoutObject = contentLayout,
            Children = {},
            _Order = 0,
        }, Container),
    }, Section)

    local function refresh(animated)
        task.defer(function()
            local contentHeight = contentLayout.AbsoluteContentSize.Y + contentPadding
            local targetHeight = section.Opened and (headerHeight + contentHeight) or headerHeight

            content.Visible = section.Opened
            if animated then
                Tween(root, 0.25, { Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset, 0, targetHeight) })
                if arrow then Tween(arrow, 0.18, { Rotation = section.Opened and 180 or 0 }) end
            else
                root.Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset, 0, targetHeight)
                if arrow then arrow.Rotation = section.Opened and 180 or 0 end
            end
        end)
    end

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if section.Opened then
            refresh(false)
        end
    end)

    if collapsible then
        header.MouseButton1Click:Connect(function()
            section:SetOpen(not section.Opened)
        end)
    end

    refresh(false)
    return section
end

function Section:SetOpen(value)
    self.Opened = value == true
    local headerHeight = self.Header.AbsoluteSize.Y > 0 and self.Header.AbsoluteSize.Y or 42
    local paddingObject = self.Content:FindFirstChildOfClass("UIPadding")
    local bottomPadding = paddingObject and paddingObject.PaddingBottom.Offset or 0
    local targetHeight = self.Opened and (headerHeight + self.LayoutObject.AbsoluteContentSize.Y + bottomPadding) or headerHeight

    self.Content.Visible = self.Opened
    Tween(self.Root, 0.25, {
        Size = UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset, 0, targetHeight),
    })

    local arrow = self.Header:FindFirstChildWhichIsA("ImageLabel")
    if arrow then
        Tween(arrow, 0.18, { Rotation = self.Opened and 180 or 0 })
    end

    return self
end

function Section:Toggle()
    return self:SetOpen(not self.Opened)
end

function Section:Destroy()
    if self.Root then self.Root:Destroy() end
end

local sectionProxyMethods = {
    "Layout", "Free", "Vertical", "Horizontal", "Grid",
    "Panel", "Text", "Paragraph", "Button", "Toggle", "Slider",
    "ProgressBar", "Input", "Dropdown", "Keybind", "Code",
    "ColorPicker", "Section", "Divider", "Space", "Image",
}

for _, method in ipairs(sectionProxyMethods) do
    Section[method] = function(self, config)
        return self._container[method](self._container, config)
    end
end

--============================================================
-- Topbar controls
--============================================================

local function CreateControlButton(window, iconName, parent)
    local button = New("TextButton", {
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 50,
    })
    BindTheme(window, button, "BackgroundColor3", "Surface")
    Corner(button, 8)

    local icon = CreateIcon(iconName, 16)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.ZIndex = 51
    BindTheme(window, icon, "ImageColor3", "Icon")
    icon.Parent = button

    button.MouseEnter:Connect(function()
        Tween(button, 0.14, { BackgroundTransparency = 0.92 })
    end)

    button.MouseLeave:Connect(function()
        Tween(button, 0.14, { BackgroundTransparency = 1 })
    end)

    button.Parent = parent
    return button, icon
end

--============================================================
-- CreateWindow
--============================================================

function Pebble:CreateWindow(config)
    config = config or {}

    local self = setmetatable({}, Window)

    self.Title = config.Title or Defaults.Title
    self.Version = config.Version or Defaults.Version
    self.Icon = config.Icon or Defaults.Icon
    self.Tags = config.Tags or Defaults.Tags

    self.Size = config.Size or Defaults.Size
    self.MinSize = config.MinSize or Defaults.MinSize
    self.MaxSize = config.MaxSize or Defaults.MaxSize

    self.TopbarHeight = config.TopbarHeight or Defaults.TopbarHeight
    self.SidebarWidth = config.SidebarWidth or Defaults.SidebarWidth
    self.CollapsedSidebarWidth = config.CollapsedSidebarWidth or Defaults.CollapsedSidebarWidth
    self.CornerRadius = config.CornerRadius or Defaults.CornerRadius

    self.BackgroundTransparency = config.BackgroundTransparency == nil and Defaults.BackgroundTransparency or Clamp01(config.BackgroundTransparency)
    self.SidebarTransparency = config.SidebarTransparency == nil and self.BackgroundTransparency or Clamp01(config.SidebarTransparency)
    self.SelectTransparency = config.SelectTransparency == nil and Defaults.SelectTransparency or Clamp01(config.SelectTransparency)

    self.Draggable = config.Draggable ~= false
    self.Resizable = config.Resizable ~= false

    self.Theme = Merge(DefaultTheme, config.Theme)
    if config.SelectColor then
        self.Theme.Accent = config.SelectColor
    end

    self.Tabs = {}
    self.SelectedTab = nil
    self.SidebarCollapsed = false
    self.Minimized = false
    self.Maximized = false
    self._SidebarOrder = 0
    self._themeBindings = {}

    -- ScreenGui
    local screenGui = New("ScreenGui", {
        Name = "PebbleUI_" .. tostring(math.random(100000, 999999)),
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    local parented = pcall(function()
        screenGui.Parent = CoreGui
    end)

    if not parented then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    self.ScreenGui = screenGui

    -- Main
    local main = New("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = config.Position or Defaults.Position,
        Size = self.Size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    main.Parent = screenGui
    self.Main = main

    -- ClipRoot
    local clipRoot = New("Frame", {
        Name = "ClipRoot",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    Corner(clipRoot, self.CornerRadius)
    clipRoot.Parent = main
    self.ClipRoot = clipRoot

    local outerStroke = AddStroke(clipRoot, ThemeValue(self, "Stroke"), 0.88, 1)
    BindTheme(self, outerStroke, "Color", "Stroke")

    -- Surface
    local surface = New("Frame", {
        Name = "Surface",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = self.BackgroundTransparency,
        BorderSizePixel = 0,
        ZIndex = 1,
    })
    BindTheme(self, surface, "BackgroundColor3", "Background")
    surface.Parent = clipRoot
    self.Surface = surface

    local surfaceGradient = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ThemeValue(self, "BackgroundTop")),
            ColorSequenceKeypoint.new(1, ThemeValue(self, "BackgroundBottom")),
        }),
        Rotation = 90,
    })
    surfaceGradient.Parent = surface
    self.SurfaceGradient = surfaceGradient

    -- Topbar
    local topbar = New("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, self.TopbarHeight),
        BackgroundTransparency = 1,
        ZIndex = 30,
    })
    topbar.Parent = clipRoot
    self.Topbar = topbar

    -- App icon
    local appIcon = CreateIcon(self.Icon, 20)
    appIcon.AnchorPoint = Vector2.new(0, 0.5)
    appIcon.Position = UDim2.new(0, 17, 0.5, 0)
    appIcon.ZIndex = 32
    BindTheme(self, appIcon, "ImageColor3", "Text")
    appIcon.Parent = topbar
    self.IconImage = appIcon

    local titleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(48, 9),
        Size = UDim2.new(0, 260, 0, 18),
        Font = Enum.Font.GothamMedium,
        Text = self.Title,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 32,
    })
    BindTheme(self, titleLabel, "TextColor3", "Text")
    titleLabel.Parent = topbar

    local versionLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(48, 29),
        Size = UDim2.fromOffset(90, 15),
        Font = Enum.Font.Gotham,
        Text = self.Version,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 32,
    })
    BindTheme(self, versionLabel, "TextColor3", "MutedText")
    versionLabel.Parent = topbar

    local tagHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(config.TagOffsetX or 160, 16),
        Size = UDim2.new(1, -(config.TagOffsetX or 160) - 190, 0, 22),
        ZIndex = 32,
    })
    tagHolder.Parent = topbar

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tagHolder,
    })

    for index, tagText in ipairs(self.Tags) do
        local tag = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 20),
            BackgroundTransparency = 0.92,
            BorderSizePixel = 0,
            Text = "  " .. tostring(tagText) .. "  ",
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            LayoutOrder = index,
            ZIndex = 33,
        })
        BindTheme(self, tag, "BackgroundColor3", "Surface2")
        BindTheme(self, tag, "TextColor3", "SubText")
        Corner(tag, 6)
        tag.Parent = tagHolder
    end

    -- Controls
    local controls = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(104, 32),
        BackgroundTransparency = 1,
        ZIndex = 50,
    })
    controls.Parent = topbar

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = controls,
    })

    local minimizeButton = CreateControlButton(self, "minus", controls)
    minimizeButton.LayoutOrder = 1

    local maximizeButton = CreateControlButton(self, "square", controls)
    maximizeButton.LayoutOrder = 2

    local closeButton, closeIcon = CreateControlButton(self, "x", controls)
    closeButton.LayoutOrder = 3

    closeButton.MouseEnter:Connect(function()
        Tween(closeButton, 0.14, {
            BackgroundColor3 = ThemeValue(self, "Danger"),
            BackgroundTransparency = 0.78,
        })
        Tween(closeIcon, 0.14, { ImageColor3 = Color3.fromRGB(255, 190, 190) })
    end)

    closeButton.MouseLeave:Connect(function()
        Tween(closeButton, 0.14, { BackgroundTransparency = 1 })
        Tween(closeIcon, 0.14, { ImageColor3 = ThemeValue(self, "Icon") })
    end)

    -- Sidebar
    local sidebar = New("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, self.TopbarHeight),
        Size = UDim2.new(0, self.SidebarWidth, 1, -self.TopbarHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 10,
    })
    sidebar.Parent = clipRoot
    self.Sidebar = sidebar

    local sidebarGlass = New("Frame", {
        Name = "SidebarGlass",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = self.SidebarTransparency,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    BindTheme(self, sidebarGlass, "BackgroundColor3", "Sidebar")
    sidebarGlass.Parent = sidebar
    self.SidebarGlass = sidebarGlass

    local sidebarLine = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    BindTheme(self, sidebarLine, "BackgroundColor3", "Stroke")
    sidebarLine.Parent = sidebar

    -- Sidebar toggle attached to edge
    local sidebarToggle = New("TextButton", {
        Name = "SidebarToggle",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(1, 0, 0, 10),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 60,
    })
    BindTheme(self, sidebarToggle, "BackgroundColor3", "Surface")
    Corner(sidebarToggle, 8)
    local toggleStroke = AddStroke(sidebarToggle, ThemeValue(self, "Stroke"), 0.88, 1)
    BindTheme(self, toggleStroke, "Color", "Stroke")
    sidebarToggle.Parent = sidebar

    local sidebarToggleIcon = CreateIcon("panel-left-close", 14)
    sidebarToggleIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    sidebarToggleIcon.Position = UDim2.fromScale(0.5, 0.5)
    sidebarToggleIcon.ZIndex = 61
    BindTheme(self, sidebarToggleIcon, "ImageColor3", "Icon")
    sidebarToggleIcon.Parent = sidebarToggle

    self.SidebarToggle = sidebarToggle
    self.SidebarToggleIcon = sidebarToggleIcon

    -- Tab scroller
    local tabScroller = New("ScrollingFrame", {
        Name = "Tabs",
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -88),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
        ZIndex = 15,
    })
    tabScroller.Parent = sidebar
    self.TabScroller = tabScroller

    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabScroller,
    })

    -- User panel
    local userPanel = New("Frame", {
        Name = "UserPanel",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 8, 1, -8),
        Size = UDim2.new(1, -16, 0, 64),
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 20,
    })
    BindTheme(self, userPanel, "BackgroundColor3", "Surface2")
    Corner(userPanel, 10)
    local userStroke = AddStroke(userPanel, ThemeValue(self, "Stroke"), 0.95, 1)
    BindTheme(self, userStroke, "Color", "Stroke")
    userPanel.Parent = sidebar
    self.UserPanel = userPanel

    local avatar = New("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 11, 0.5, 0),
        Size = UDim2.fromOffset(38, 38),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Image = "",
        ZIndex = 21,
    })
    BindTheme(self, avatar, "BackgroundColor3", "Surface")
    Corner(avatar, 19)
    avatar.Parent = userPanel
    self.UserAvatar = avatar

    task.spawn(function()
        local ok, thumbnail = pcall(function()
            return Players:GetUserThumbnailAsync(
                LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)
        if ok and avatar.Parent then
            avatar.Image = thumbnail
        end
    end)

    local displayName = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(59, 12),
        Size = UDim2.new(1, -70, 0, 18),
        Font = Enum.Font.GothamMedium,
        Text = LocalPlayer.DisplayName,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 21,
    })
    BindTheme(self, displayName, "TextColor3", "Text")
    displayName.Parent = userPanel

    local username = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(59, 33),
        Size = UDim2.new(1, -70, 0, 16),
        Font = Enum.Font.Gotham,
        Text = "@" .. LocalPlayer.Name,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 21,
    })
    BindTheme(self, username, "TextColor3", "SubText")
    username.Parent = userPanel

    self.DisplayNameLabel = displayName
    self.UsernameLabel = username

    -- Content
    local content = New("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(self.SidebarWidth, self.TopbarHeight),
        Size = UDim2.new(1, -self.SidebarWidth, 1, -self.TopbarHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 8,
    })
    content.Parent = clipRoot
    self.Content = content

    -- Overlay above window internals, used for dialogs
    local overlay = New("Frame", {
        Name = "Overlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 500,
    })
    overlay.Parent = clipRoot
    self.Overlay = overlay

    -- Notification holder outside clipped window
    local notifications = New("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Size = UDim2.fromOffset(320, 420),
        BackgroundTransparency = 1,
        ZIndex = 900,
    })
    notifications.Parent = screenGui
    self.NotificationHolder = notifications

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = notifications,
    })

    -- Sidebar collapse behavior
    function self:SetSidebarCollapsed(collapsed)
        self.SidebarCollapsed = collapsed == true
        local width = self.SidebarCollapsed and self.CollapsedSidebarWidth or self.SidebarWidth

        Tween(self.Sidebar, 0.38, {
            Size = UDim2.new(0, width, 1, -self.TopbarHeight),
        })

        Tween(self.Content, 0.38, {
            Position = UDim2.fromOffset(width, self.TopbarHeight),
            Size = UDim2.new(1, -width, 1, -self.TopbarHeight),
        })

        self.SidebarToggleIcon.Image = GetIcon(self.SidebarCollapsed and "panel-left-open" or "panel-left-close")

        for _, tab in ipairs(self.Tabs) do
            if tab.TitleLabel then
                Tween(tab.TitleLabel, 0.2, {
                    TextTransparency = self.SidebarCollapsed and 1 or 0,
                })
            end

            if tab.LockIcon then
                Tween(tab.LockIcon, 0.2, {
                    ImageTransparency = self.SidebarCollapsed and 1 or 0,
                })
            end
        end

        Tween(displayName, 0.2, { TextTransparency = self.SidebarCollapsed and 1 or 0 })
        Tween(username, 0.2, { TextTransparency = self.SidebarCollapsed and 1 or 0 })

        Tween(avatar, 0.35, {
            Position = self.SidebarCollapsed
                and UDim2.new(0.5, -19, 0.5, 0)
                or UDim2.new(0, 11, 0.5, 0),
        })

        return self
    end

    sidebarToggle.MouseButton1Click:Connect(function()
        self:SetSidebarCollapsed(not self.SidebarCollapsed)
    end)

    -- Minimize
    local normalSize = main.Size

    minimizeButton.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized

        if self.Minimized then
            normalSize = main.Size
            Tween(main, 0.3, {
                Size = UDim2.new(normalSize.X.Scale, normalSize.X.Offset, 0, self.TopbarHeight),
            })
        else
            Tween(main, 0.3, { Size = normalSize })
        end
    end)

    -- Maximize
    local previousPosition = main.Position
    local previousSize = main.Size
    local previousAnchor = main.AnchorPoint

    maximizeButton.MouseButton1Click:Connect(function()
        self.Maximized = not self.Maximized

        if self.Maximized then
            previousPosition = main.Position
            previousSize = main.Size
            previousAnchor = main.AnchorPoint

            main.AnchorPoint = Vector2.zero
            Tween(main, 0.35, {
                Position = UDim2.fromOffset(12, 12),
                Size = UDim2.new(1, -24, 1, -24),
            })
        else
            main.AnchorPoint = previousAnchor
            Tween(main, 0.35, {
                Position = previousPosition,
                Size = previousSize,
            })
        end
    end)

    -- Close
    closeButton.MouseButton1Click:Connect(function()
        Tween(main, 0.18, {
            Size = UDim2.new(
                main.Size.X.Scale,
                main.Size.X.Offset - 18,
                main.Size.Y.Scale,
                main.Size.Y.Offset - 18
            ),
        })

        task.delay(0.18, function()
            if screenGui then
                screenGui:Destroy()
            end
        end)
    end)

    -- Drag region excluding controls
    if self.Draggable then
        local dragRegion = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, -130, 1, 0),
            ZIndex = 29,
        })
        dragRegion.Parent = topbar

        local dragging = false
        local dragStart
        local startPosition

        dragRegion.InputBegan:Connect(function(input)
            if self.Maximized then return end

            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPosition = main.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end

            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- Resize
    if self.Resizable then
        local resizeHandle = New("TextButton", {
            Name = "ResizeHandle",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(22, 22),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 1000,
        })
        resizeHandle.Parent = main

        local resizing = false
        local resizeStart
        local startSize

        resizeHandle.InputBegan:Connect(function(input)
            if self.Maximized then return end

            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
                resizeStart = input.Position
                startSize = main.AbsoluteSize
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not resizing then return end

            if input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - resizeStart
                local width = math.clamp(startSize.X + delta.X, self.MinSize.X, self.MaxSize.X)
                local height = math.clamp(startSize.Y + delta.Y, self.MinSize.Y, self.MaxSize.Y)

                main.Size = UDim2.fromOffset(width, height)
                normalSize = main.Size
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
    end

    return self
end

--============================================================
-- Tabs
--============================================================

function Window:Tab(config)
    config = config or {}

    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab.Title = config.Title or "Tab"
    tab.Icon = config.Icon
    tab.Locked = config.Locked == true
    tab.Selected = false

    self._SidebarOrder = self._SidebarOrder + 1

    local button = New("TextButton", {
        Name = tab.Title,
        Size = UDim2.new(1, 0, 0, config.Height or 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = self._SidebarOrder,
        ZIndex = 25,
    })
    BindTheme(self, button, "BackgroundColor3", "Accent")
    Corner(button, config.CornerRadius or 9)
    button.Parent = self.TabScroller
    tab.Button = button

    local accent = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(config.AccentWidth or 3, config.AccentHeight or 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 27,
    })
    BindTheme(self, accent, "BackgroundColor3", "Accent")
    Corner(accent, 2)
    accent.Parent = button
    tab.Accent = accent

    if tab.Icon then
        local icon = CreateIcon(tab.Icon, config.IconSize or 17)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 13, 0.5, 0)
        icon.ZIndex = 27
        BindTheme(self, icon, "ImageColor3", "Icon")
        icon.Parent = button
        tab.IconImage = icon
    end

    local titleLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(tab.Icon and 42 or 14, 0),
        Size = UDim2.new(1, tab.Locked and -74 or -52, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = tab.Title,
        TextSize = config.TextSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 27,
    })
    BindTheme(self, titleLabel, "TextColor3", tab.Locked and "MutedText" or "SubText")
    titleLabel.Parent = button
    tab.TitleLabel = titleLabel

    if tab.Locked then
        local lock = CreateIcon("lock", 13)
        lock.AnchorPoint = Vector2.new(1, 0.5)
        lock.Position = UDim2.new(1, -12, 0.5, 0)
        lock.ZIndex = 27
        BindTheme(self, lock, "ImageColor3", "MutedText")
        lock.Parent = button
        tab.LockIcon = lock
    end

    local page = New("ScrollingFrame", {
        Name = tab.Title .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageTransparency = 0.72,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 12,
    })
    page.Parent = self.Content

    tab.Page = page
    tab.Container = page

    table.insert(self.Tabs, tab)

    if not tab.Locked then
        button.MouseEnter:Connect(function()
            if tab.Selected then return end
            Tween(button, 0.14, { BackgroundTransparency = 0.94 })
        end)

        button.MouseLeave:Connect(function()
            if tab.Selected then return end
            Tween(button, 0.14, { BackgroundTransparency = 1 })
        end)

        button.MouseButton1Click:Connect(function()
            tab:Select()
        end)
    end

    if not self.SelectedTab and not tab.Locked then
        task.defer(function()
            if not self.SelectedTab and tab.Page.Parent then
                tab:Select()
            end
        end)
    end

    return tab
end


-- Wind-style direct element API.
-- The custom layout engine remains available through Tab:Vertical/Free/Grid/etc.
function Tab:_GetDefaultContainer()
    if self._DefaultContainer and self._DefaultContainer.Frame and self._DefaultContainer.Frame.Parent then
        return self._DefaultContainer
    end

    self._DefaultContainer = CreateContainer(self.Window, self.Page, {
        Type = "Vertical",
        Name = "DefaultElements",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Gap = 8,
        BackgroundTransparency = 1,
        ZIndex = 14,
    })

    return self._DefaultContainer
end

local DirectTabMethods = {
    "Panel", "Text", "Paragraph", "Icon", "Button", "Toggle", "Slider",
    "ProgressBar", "Input", "Dropdown", "Keybind", "Code",
    "Colorpicker", "ColorPicker", "Section", "Space", "Image",
}

for _, methodName in ipairs(DirectTabMethods) do
    if Tab[methodName] == nil then
        Tab[methodName] = function(self, config)
            local container = self:_GetDefaultContainer()
            return container[methodName](container, config or {})
        end
    end
end

-- Content divider without changing Pebble's existing Tab:Divider() sidebar behavior.
function Tab:ContentDivider(config)
    local container = self:_GetDefaultContainer()
    return container:Divider(config or {})
end

function Tab:Select()
    if self.Locked then
        return self
    end

    local window = self.Window

    for _, tab in ipairs(window.Tabs) do
        local selected = tab == self
        tab.Selected = selected
        tab.Page.Visible = selected

        Tween(tab.Button, 0.22, {
            BackgroundColor3 = ThemeValue(window, "Accent"),
            BackgroundTransparency = selected and window.SelectTransparency or 1,
        })

        Tween(tab.Accent, 0.22, {
            BackgroundColor3 = ThemeValue(window, "Accent"),
            BackgroundTransparency = selected and 0 or 1,
        })

        if tab.IconImage then
            Tween(tab.IconImage, 0.22, {
                ImageColor3 = selected and ThemeValue(window, "IconSelected") or ThemeValue(window, "Icon"),
            })
        end

        Tween(tab.TitleLabel, 0.22, {
            TextColor3 = selected
                and ThemeValue(window, "Text")
                or (tab.Locked and ThemeValue(window, "MutedText") or ThemeValue(window, "SubText")),
        })
    end

    window.SelectedTab = self
    return self
end

function Tab:Divider(config)
    config = config or {}
    local window = self.Window
    window._SidebarOrder = window._SidebarOrder + 1

    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, config.Height or 13),
        BackgroundTransparency = 1,
        LayoutOrder = window._SidebarOrder,
        ZIndex = 20,
    })
    holder.Parent = window.TabScroller

    local line = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -(config.Inset or 16), 0, config.Thickness or 1),
        BackgroundTransparency = config.Transparency == nil and 0.91 or config.Transparency,
        BorderSizePixel = 0,
        ZIndex = 21,
    })
    BindTheme(window, line, "BackgroundColor3", "Stroke", config.Color)
    line.Parent = holder

    return holder
end

--============================================================
-- Tab layout API
--============================================================

function Tab:Layout(config)
    return CreateContainer(self.Window, self.Page, config or {})
end

function Tab:Free(config)
    config = config or {}
    config.Type = "Free"
    return self:Layout(config)
end

function Tab:Vertical(config)
    config = config or {}
    config.Type = "Vertical"
    return self:Layout(config)
end

function Tab:Horizontal(config)
    config = config or {}
    config.Type = "Horizontal"
    return self:Layout(config)
end

function Tab:Grid(config)
    config = config or {}
    config.Type = "Grid"
    return self:Layout(config)
end

--============================================================
-- Window theming / setters
--============================================================

function Window:SetTheme(partialTheme)
    for key, value in pairs(partialTheme or {}) do
        self.Theme[key] = value
    end

    self:_RefreshTheme()

    if self.SurfaceGradient then
        self.SurfaceGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, ThemeValue(self, "BackgroundTop")),
            ColorSequenceKeypoint.new(1, ThemeValue(self, "BackgroundBottom")),
        })
    end

    if self.SelectedTab then
        self.SelectedTab.Button.BackgroundColor3 = ThemeValue(self, "Accent")
        self.SelectedTab.Accent.BackgroundColor3 = ThemeValue(self, "Accent")
    end

    return self
end

function Window:SetSelectColor(color)
    if typeof(color) ~= "Color3" then return self end
    return self:SetTheme({ Accent = color })
end

function Window:SetSelectTransparency(value)
    if typeof(value) ~= "number" then return self end
    self.SelectTransparency = Clamp01(value)

    if self.SelectedTab then
        Tween(self.SelectedTab.Button, 0.2, {
            BackgroundTransparency = self.SelectTransparency,
        })
    end

    return self
end

function Window:SetBackgroundTransparency(value)
    if typeof(value) ~= "number" then return self end
    self.BackgroundTransparency = Clamp01(value)
    Tween(self.Surface, 0.25, {
        BackgroundTransparency = self.BackgroundTransparency,
    })
    return self
end

function Window:SetSidebarTransparency(value)
    if typeof(value) ~= "number" then return self end
    self.SidebarTransparency = Clamp01(value)
    Tween(self.SidebarGlass, 0.25, {
        BackgroundTransparency = self.SidebarTransparency,
    })
    return self
end

function Window:SetIcon(icon)
    self.Icon = icon
    if self.IconImage then
        self.IconImage.Image = GetIcon(icon)
    end
    return self
end

--============================================================
-- Notifications
--============================================================

function Window:Notify(config)
    config = config or {}

    local duration = config.Duration
    if duration == nil then duration = 4 end

    local card = New("Frame", {
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, config.Height or 78),
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.06 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        ZIndex = 910,
        LayoutOrder = math.floor(os.clock() * 1000),
    })
    BindTheme(self, card, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(card, config.CornerRadius or 10)
    local stroke = AddStroke(card, ThemeValue(self, "Stroke"), 0.92, 1)
    BindTheme(self, stroke, "Color", "Stroke", config.StrokeColor)
    card.Parent = self.NotificationHolder

    local iconOffset = 12
    if config.Icon then
        local icon = CreateIcon(config.Icon, 18)
        icon.Position = UDim2.fromOffset(12, 13)
        icon.ZIndex = 912
        BindTheme(self, icon, "ImageColor3", config.IconTheme or "Icon", config.IconColor)
        icon.Parent = card
        iconOffset = 40
    end

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(iconOffset, 10),
        Size = UDim2.new(1, -iconOffset - 32, 0, 20),
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Notification",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 912,
    })
    BindTheme(self, title, "TextColor3", "Text", config.TitleColor)
    title.Parent = card

    local content = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(iconOffset, 31),
        Size = UDim2.new(1, -iconOffset - 14, 1, -40),
        Font = Enum.Font.Gotham,
        Text = config.Content or config.Desc or "",
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 912,
    })
    BindTheme(self, content, "TextColor3", "SubText", config.ContentColor)
    content.Parent = card

    local close = CreateIcon("x", 13)
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -10, 0, 10)
    close.ZIndex = 913
    BindTheme(self, close, "ImageColor3", "MutedText")
    close.Parent = card

    local closeHit = CreateHitbox(close, 914)
    closeHit.Size = UDim2.new(1, 10, 1, 10)
    closeHit.AnchorPoint = Vector2.new(0.5, 0.5)
    closeHit.Position = UDim2.fromScale(0.5, 0.5)

    local progress
    if duration and duration > 0 then
        progress = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ZIndex = 914,
        })
        BindTheme(self, progress, "BackgroundColor3", "Accent", config.ProgressColor)
        progress.Parent = card
    end

    local closed = false
    local object = {}

    function object:Close()
        if closed then return end
        closed = true
        Tween(card, 0.22, {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(25, 0),
        })
        task.delay(0.22, function()
            if card then card:Destroy() end
        end)
    end

    closeHit.MouseButton1Click:Connect(function()
        object:Close()
    end)

    if duration and duration > 0 then
        Tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
        task.delay(duration, function()
            object:Close()
        end)
    end

    return object
end

--============================================================
-- Dialog
--============================================================

function Window:Dialog(config)
    config = config or {}

    local overlay = self.Overlay
    overlay.Visible = true
    overlay.BackgroundTransparency = 1
    Tween(overlay, 0.2, { BackgroundTransparency = config.OverlayTransparency or 0.45 })

    local card = New("Frame", {
        Name = "Dialog",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = config.Size or UDim2.fromOffset(config.Width or 390, config.Height or 190),
        BackgroundTransparency = config.BackgroundTransparency == nil and 0.03 or config.BackgroundTransparency,
        BorderSizePixel = 0,
        ZIndex = overlay.ZIndex + 5,
    })
    BindTheme(self, card, "BackgroundColor3", "Surface", config.BackgroundColor)
    Corner(card, config.CornerRadius or 12)
    local stroke = AddStroke(card, ThemeValue(self, "Stroke"), 0.90, 1)
    BindTheme(self, stroke, "Color", "Stroke", config.StrokeColor)
    card.Parent = overlay

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.new(1, -32, 0, 24),
        Font = Enum.Font.GothamMedium,
        Text = config.Title or "Dialog",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = card.ZIndex + 2,
    })
    BindTheme(self, title, "TextColor3", "Text", config.TitleColor)
    title.Parent = card

    local content = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 46),
        Size = UDim2.new(1, -32, 1, -105),
        Font = Enum.Font.Gotham,
        Text = config.Content or "",
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = card.ZIndex + 2,
    })
    BindTheme(self, content, "TextColor3", "SubText", config.ContentColor)
    content.Parent = card

    local buttonHolder = New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 16, 1, -14),
        Size = UDim2.new(1, -32, 0, 34),
        BackgroundTransparency = 1,
        ZIndex = card.ZIndex + 2,
    })
    buttonHolder.Parent = card

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = buttonHolder,
    })

    local closed = false
    local object = {}

    function object:Close()
        if closed then return end
        closed = true
        Tween(overlay, 0.18, { BackgroundTransparency = 1 })
        Tween(card, 0.18, { Size = UDim2.new(card.Size.X.Scale, card.Size.X.Offset - 15, card.Size.Y.Scale, card.Size.Y.Offset - 15) })
        task.delay(0.18, function()
            if card then card:Destroy() end
            overlay.Visible = false
        end)
    end

    local buttons = config.Buttons or {
        {
            Title = "Close",
            Callback = function() end,
        },
    }

    for index, buttonConfig in ipairs(buttons) do
        local button = New("TextButton", {
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.fromOffset(0, 32),
            BackgroundTransparency = buttonConfig.BackgroundTransparency == nil and 0.08 or buttonConfig.BackgroundTransparency,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "   " .. tostring(buttonConfig.Title or ("Button " .. index)) .. "   ",
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            LayoutOrder = index,
            ZIndex = buttonHolder.ZIndex + 2,
        })

        if buttonConfig.Primary then
            BindTheme(self, button, "BackgroundColor3", "Accent", buttonConfig.BackgroundColor)
            BindTheme(self, button, "TextColor3", "AccentText", buttonConfig.TextColor)
        else
            BindTheme(self, button, "BackgroundColor3", "Surface2", buttonConfig.BackgroundColor)
            BindTheme(self, button, "TextColor3", "Text", buttonConfig.TextColor)
        end

        Corner(button, 7)
        button.Parent = buttonHolder

        button.MouseButton1Click:Connect(function()
            SafeCallback(buttonConfig.Callback)
            if buttonConfig.Close ~= false then
                object:Close()
            end
        end)
    end

    return object
end

--============================================================
-- Destroy
--============================================================

function Window:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

print("[Pebble] Loaded v" .. Pebble.Version .. " | Wind-style defaults enabled")
return Pebble
