--[[
	Pebble UI Library
	Layout Engine v0.4.0

	Custom Layout System
	- Free
	- Vertical
	- Horizontal
	- Grid

	Elements
	- Panel
	- Text
	- Button
	- Icon
	- Divider
	- Spacer

	Every element supports:
	- Size
	- Position
	- AnchorPoint
	- BackgroundColor
	- BackgroundTransparency
	- CornerRadius
	- Stroke
	- Alignment
	- LayoutOrder
	- Visible
	- ZIndex

	Nested layouts supported.
]]

local Pebble = {
	Version = "0.4.0"
}

--// Services

local TweenService =
	game:GetService("TweenService")

local Players =
	game:GetService("Players")

local UserInputService =
	game:GetService("UserInputService")

local CoreGui =
	game:GetService("CoreGui")

local LocalPlayer =
	Players.LocalPlayer

--// Icons

local LucideIcons = {}

do
	local success, result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
		))()
	end)

	if success and typeof(result) == "table" then
		LucideIcons = result
	end
end

local function GetIcon(name)
	if not name then
		return ""
	end

	if typeof(name) ~= "string" then
		return ""
	end

	if string.match(name, "^rbxassetid://") then
		return name
	end

	return LucideIcons[name] or ""
end

--// Theme

local Theme = {
	Background =
		Color3.fromRGB(16, 17, 19),

	Surface =
		Color3.fromRGB(22, 23, 26),

	SurfaceHover =
		Color3.fromRGB(29, 30, 34),

	SurfaceActive =
		Color3.fromRGB(35, 36, 41),

	Secondary =
		Color3.fromRGB(25, 26, 29),

	Input =
		Color3.fromRGB(29, 30, 34),

	Stroke =
		Color3.fromRGB(255, 255, 255),

	Text =
		Color3.fromRGB(242, 243, 247),

	SubText =
		Color3.fromRGB(151, 152, 161),

	Muted =
		Color3.fromRGB(104, 105, 114),

	Accent =
		Color3.fromRGB(103, 76, 255),

	AccentText =
		Color3.fromRGB(255, 255, 255),

	Icon =
		Color3.fromRGB(180, 181, 191),

	Danger =
		Color3.fromRGB(235, 76, 76),
}

Pebble.Theme = Theme

--// Classes

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Layout = {}
Layout.__index = Layout

local Element = {}
Element.__index = Element

--// Utility

local function New(className, props)
	local object =
		Instance.new(className)

	for property, value in pairs(props or {}) do
		object[property] = value
	end

	return object
end

local function Corner(parent, radius)
	local corner =
		New("UICorner", {
			CornerRadius =
				UDim.new(
					0,
					radius or 8
				)
		})

	corner.Parent = parent

	return corner
end

local function AddStroke(
	parent,
	color,
	transparency,
	thickness
)
	local stroke =
		New("UIStroke", {
			Color =
				color
				or Theme.Stroke,

			Transparency =
				transparency
				or 0.9,

			Thickness =
				thickness
				or 1,

			ApplyStrokeMode =
				Enum.ApplyStrokeMode.Border
		})

	stroke.Parent = parent

	return stroke
end

local function Tween(object, duration, props)
	local tween =
		TweenService:Create(
			object,

			TweenInfo.new(
				duration or 0.2,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			),

			props
		)

	tween:Play()

	return tween
end

local function ResolveAlignment(value)
	if value == "Center" then
		return Enum.TextXAlignment.Center
	elseif value == "Right" then
		return Enum.TextXAlignment.Right
	end

	return Enum.TextXAlignment.Left
end

local function ResolveVerticalAlignment(value)
	if value == "Center" then
		return Enum.TextYAlignment.Center
	elseif value == "Bottom" then
		return Enum.TextYAlignment.Bottom
	end

	return Enum.TextYAlignment.Top
end

local function Wrap(instance)
	return setmetatable({
		Instance = instance
	}, Element)
end

--// Element API

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

function Element:Tween(properties, duration)
	if self.Instance then
		Tween(
			self.Instance,
			duration or 0.2,
			properties
		)
	end

	return self
end

function Element:SetVisible(value)
	if self.Instance then
		self.Instance.Visible = value
	end

	return self
end

function Element:Destroy()
	if self.Instance then
		self.Instance:Destroy()
	end
end

--// Generic layout

local function CreateLayout(
	parent,
	config
)
	config = config or {}

	local mode =
		config.Type
		or config.Mode
		or "Free"

	local frame =
		New("Frame", {
			Name =
				config.Name
				or "Layout",

			BackgroundColor3 =
				config.BackgroundColor
				or Theme.Surface,

			BackgroundTransparency =
				config.BackgroundTransparency ~= nil
				and config.BackgroundTransparency
				or 1,

			Position =
				config.Position
				or UDim2.fromOffset(0, 0),

			Size =
				config.Size
				or UDim2.fromScale(1, 1),

			AnchorPoint =
				config.AnchorPoint
				or Vector2.zero,

			BorderSizePixel = 0,

			ClipsDescendants =
				config.ClipsDescendants
				== true,

			LayoutOrder =
				config.LayoutOrder
				or 0,

			ZIndex =
				config.ZIndex
				or 1,

			Visible =
				config.Visible
				~= false
		})

	frame.Parent = parent

	if config.CornerRadius then
		Corner(
			frame,
			config.CornerRadius
		)
	end

	if config.Stroke then
		AddStroke(
			frame,
			config.StrokeColor,
			config.StrokeTransparency,
			config.StrokeThickness
		)
	end

	local padding =
		config.Padding or 0

	if typeof(padding) == "number"
		and padding > 0
	then
		local uiPadding =
			New("UIPadding", {
				PaddingTop =
					UDim.new(0, padding),

				PaddingBottom =
					UDim.new(0, padding),

				PaddingLeft =
					UDim.new(0, padding),

				PaddingRight =
					UDim.new(0, padding)
			})

		uiPadding.Parent = frame
	end

	local layoutObject = nil

	if mode == "Vertical" then
		layoutObject =
			New("UIListLayout", {
				FillDirection =
					Enum.FillDirection.Vertical,

				Padding =
					UDim.new(
						0,
						config.Gap or 8
					),

				SortOrder =
					Enum.SortOrder.LayoutOrder,

				HorizontalAlignment =
					config.HorizontalAlignment
						or Enum.HorizontalAlignment.Left,

				VerticalAlignment =
					config.VerticalAlignment
						or Enum.VerticalAlignment.Top
			})

	elseif mode == "Horizontal" then
		layoutObject =
			New("UIListLayout", {
				FillDirection =
					Enum.FillDirection.Horizontal,

				Padding =
					UDim.new(
						0,
						config.Gap or 8
					),

				SortOrder =
					Enum.SortOrder.LayoutOrder,

				HorizontalAlignment =
					config.HorizontalAlignment
						or Enum.HorizontalAlignment.Left,

				VerticalAlignment =
					config.VerticalAlignment
						or Enum.VerticalAlignment.Top
			})

	elseif mode == "Grid" then
		local columns =
			config.Columns or 2

		local gap =
			config.Gap or 10

		local widthScale =
			1 / columns

		layoutObject =
			New("UIGridLayout", {
				CellPadding =
					UDim2.fromOffset(
						gap,
						gap
					),

				CellSize =
					config.CellSize
						or UDim2.new(
							widthScale,
							-gap,
							0,
							config.CellHeight
								or 120
						),

				SortOrder =
					Enum.SortOrder.LayoutOrder,

				FillDirection =
					Enum.FillDirection.Horizontal,

				FillDirectionMaxCells =
					columns
			})
	end

	if layoutObject then
		layoutObject.Parent = frame
	end

	return setmetatable({
		Frame = frame,
		Container = frame,
		Type = mode,
		LayoutObject = layoutObject,
		Children = {},
		_Order = 0,
	}, Layout)
end

--// Layout nesting

function Layout:Layout(config)
	config = config or {}

	self._Order += 1

	if config.LayoutOrder == nil then
		config.LayoutOrder =
			self._Order
	end

	local child =
		CreateLayout(
			self.Container,
			config
		)

	table.insert(
		self.Children,
		child
	)

	return child
end

function Layout:Vertical(config)
	config = config or {}
	config.Type = "Vertical"

	return self:Layout(config)
end

function Layout:Horizontal(config)
	config = config or {}
	config.Type = "Horizontal"

	return self:Layout(config)
end

function Layout:Grid(config)
	config = config or {}
	config.Type = "Grid"

	return self:Layout(config)
end

function Layout:Free(config)
	config = config or {}
	config.Type = "Free"

	return self:Layout(config)
end

--// Panel

function Layout:Panel(config)
	config = config or {}

	self._Order += 1

	local panel =
		New("Frame", {
			Name =
				config.Name
				or "Panel",

			BackgroundColor3 =
				config.BackgroundColor
				or Theme.Surface,

			BackgroundTransparency =
				config.BackgroundTransparency ~= nil
				and config.BackgroundTransparency
				or 0.16,

			Size =
				config.Size
				or UDim2.new(
					1,
					0,
					0,
					100
				),

			Position =
				config.Position
				or UDim2.fromOffset(0, 0),

			AnchorPoint =
				config.AnchorPoint
				or Vector2.zero,

			LayoutOrder =
				config.LayoutOrder
				or self._Order,

			BorderSizePixel = 0,

			ClipsDescendants =
				config.ClipsDescendants
				== true,

			ZIndex =
				config.ZIndex
				or 2,

			Visible =
				config.Visible
				~= false
		})

	Corner(
		panel,
		config.CornerRadius
			or 10
	)

	if config.Stroke ~= false then
		AddStroke(
			panel,

			config.StrokeColor
				or Theme.Stroke,

			config.StrokeTransparency
				or 0.92,

			config.StrokeThickness
				or 1
		)
	end

	panel.Parent =
		self.Container

	local element = Wrap(panel)

	element.Container = panel

	function element:Layout(childConfig)
		return CreateLayout(
			panel,
			childConfig or {}
		)
	end

	function element:Text(childConfig)
		local temp =
			setmetatable({
				Container = panel,
				_Order = 0
			}, Layout)

		return temp:Text(childConfig)
	end

	function element:Button(childConfig)
		local temp =
			setmetatable({
				Container = panel,
				_Order = 0
			}, Layout)

		return temp:Button(childConfig)
	end

	function element:Icon(childConfig)
		local temp =
			setmetatable({
				Container = panel,
				_Order = 0
			}, Layout)

		return temp:Icon(childConfig)
	end

	table.insert(
		self.Children,
		element
	)

	return element
end

--// Text

function Layout:Text(config)
	config = config or {}

	self._Order += 1

	local label =
		New("TextLabel", {
			Name =
				config.Name
				or "Text",

			BackgroundTransparency =
				config.BackgroundTransparency
				or 1,

			BackgroundColor3 =
				config.BackgroundColor
				or Theme.Surface,

			Position =
				config.Position
				or UDim2.fromOffset(0, 0),

			Size =
				config.Size
				or UDim2.new(
					1,
					0,
					0,
					24
				),

			AnchorPoint =
				config.AnchorPoint
				or Vector2.zero,

			Font =
				config.Font
				or Enum.Font.Gotham,

			Text =
				config.Text
				or "Text",

			TextSize =
				config.TextSize
				or 13,

			TextColor3 =
				config.TextColor
				or Theme.Text,

			TextTransparency =
				config.TextTransparency
				or 0,

			TextXAlignment =
				ResolveAlignment(
					config.Alignment
				),

			TextYAlignment =
				ResolveVerticalAlignment(
					config.VerticalAlignment
				),

			TextWrapped =
				config.TextWrapped
				~= false,

			RichText =
				config.RichText
				== true,

			LayoutOrder =
				config.LayoutOrder
				or self._Order,

			ZIndex =
				config.ZIndex
				or 5
		})

	label.Parent =
		self.Container

	if config.CornerRadius then
		Corner(
			label,
			config.CornerRadius
		)
	end

	return Wrap(label)
end

--// Icon

function Layout:Icon(config)
	config = config or {}

	self._Order += 1

	local icon =
		New("ImageLabel", {
			Name =
				config.Name
				or "Icon",

			BackgroundTransparency =
				config.BackgroundTransparency
				or 1,

			BackgroundColor3 =
				config.BackgroundColor
				or Theme.Surface,

			Position =
				config.Position
				or UDim2.fromOffset(0, 0),

			Size =
				config.Size
				or UDim2.fromOffset(
					18,
					18
				),

			AnchorPoint =
				config.AnchorPoint
				or Vector2.zero,

			Image =
				GetIcon(
					config.Icon
				),

			ImageColor3 =
				config.Color
				or Theme.Icon,

			ImageTransparency =
				config.Transparency
				or 0,

			ScaleType =
				Enum.ScaleType.Fit,

			LayoutOrder =
				config.LayoutOrder
				or self._Order,

			ZIndex =
				config.ZIndex
				or 5
		})

	icon.Parent =
		self.Container

	return Wrap(icon)
end

--// Button

function Layout:Button(config)
	config = config or {}

	self._Order += 1

	local button =
		New("TextButton", {
			Name =
				config.Name
				or "Button",

			BackgroundColor3 =
				config.BackgroundColor
				or Theme.Surface,

			BackgroundTransparency =
				config.BackgroundTransparency ~= nil
				and config.BackgroundTransparency
				or 0.05,

			Position =
				config.Position
				or UDim2.fromOffset(0, 0),

			Size =
				config.Size
				or UDim2.new(
					1,
					0,
					0,
					36
				),

			AnchorPoint =
				config.AnchorPoint
				or Vector2.zero,

			AutoButtonColor = false,

			Text =
				config.Text
				or "Button",

			Font =
				config.Font
				or Enum.Font.GothamMedium,

			TextSize =
				config.TextSize
				or 12,

			TextColor3 =
				config.TextColor
				or Theme.Text,

			TextXAlignment =
				ResolveAlignment(
					config.Alignment
						or "Center"
				),

			LayoutOrder =
				config.LayoutOrder
				or self._Order,

			BorderSizePixel = 0,

			ZIndex =
				config.ZIndex
				or 5
		})

	Corner(
		button,
		config.CornerRadius
			or 8
	)

	if config.Stroke ~= false then
		AddStroke(
			button,

			config.StrokeColor
				or Theme.Stroke,

			config.StrokeTransparency
				or 0.92,

			1
		)
	end

	button.Parent =
		self.Container

	local normalColor =
		button.BackgroundColor3

	local hoverColor =
		config.HoverColor
			or Theme.SurfaceHover

	button.MouseEnter:Connect(function()
		Tween(
			button,
			0.16,
			{
				BackgroundColor3 =
					hoverColor
			}
		)
	end)

	button.MouseLeave:Connect(function()
		Tween(
			button,
			0.16,
			{
				BackgroundColor3 =
					normalColor
			}
		)
	end)

	if config.Callback then
		button.MouseButton1Click:Connect(
			config.Callback
		)
	end

	local wrapper =
		Wrap(button)

	function wrapper:OnClick(callback)
		button.MouseButton1Click:Connect(
			callback
		)

		return wrapper
	end

	return wrapper
end

--// Divider

function Layout:Divider(config)
	config = config or {}

	self._Order += 1

	local holder =
		New("Frame", {
			Name = "Divider",

			BackgroundTransparency = 1,

			Size =
				config.Size
				or UDim2.new(
					1,
					0,
					0,
					13
				),

			Position =
				config.Position
				or UDim2.fromOffset(
					0,
					0
				),

			LayoutOrder =
				config.LayoutOrder
				or self._Order,

			ZIndex =
				config.ZIndex
				or 3
		})

	holder.Parent =
		self.Container

	local line =
		New("Frame", {
			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					config.Thickness
						or 1
				),

			BackgroundColor3 =
				config.Color
					or Theme.Stroke,

			BackgroundTransparency =
				config.Transparency
					or 0.9,

			BorderSizePixel = 0
		})

	line.Parent = holder

	return Wrap(holder)
end

--// Spacer

function Layout:Spacer(config)
	config = config or {}

	self._Order += 1

	local spacer =
		New("Frame", {
			Name = "Spacer",

			BackgroundTransparency = 1,

			Size =
				config.Size
				or UDim2.new(
					1,
					0,
					0,
					config.Height
						or 12
				),

			LayoutOrder =
				config.LayoutOrder
				or self._Order
		})

	spacer.Parent =
		self.Container

	return Wrap(spacer)
end

--// Tab Layout API

function Tab:Layout(config)
	return CreateLayout(
		self.Page,
		config or {}
	)
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

--// Example Page/Tab constructor
--// Keep your existing Sidebar code if preferred.

function Pebble:CreateWindow(config)
	config = config or {}

	local self =
		setmetatable({}, Window)

	self.Tabs = {}
	self.SelectedTab = nil

	self.SelectColor =
		config.SelectColor
			or Theme.Accent

	self.SelectTransparency =
		config.SelectTransparency ~= nil
			and config.SelectTransparency
			or 0.82

	local gui =
		New("ScreenGui", {
			Name =
				"PebbleUI_"
				.. tostring(
					math.random(
						10000,
						99999
					)
				),

			IgnoreGuiInset = true,

			ResetOnSpawn = false,

			ZIndexBehavior =
				Enum.ZIndexBehavior.Sibling
		})

	pcall(function()
		gui.Parent = CoreGui
	end)

	if not gui.Parent then
		gui.Parent =
			LocalPlayer:WaitForChild(
				"PlayerGui"
			)
	end

	self.ScreenGui = gui

	local main =
		New("Frame", {
			Name = "Main",

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Position =
				config.Position
					or UDim2.fromScale(
						0.5,
						0.5
					),

			Size =
				config.Size
					or UDim2.fromOffset(
						760,
						500
					),

			BackgroundColor3 =
				Theme.Background,

			BackgroundTransparency =
				config.BackgroundTransparency ~= nil
					and config.BackgroundTransparency
					or 0.25,

			BorderSizePixel = 0,

			ClipsDescendants = true
		})

	Corner(
		main,
		config.CornerRadius
			or 12
	)

	AddStroke(
		main,
		Theme.Stroke,
		0.88,
		1
	)

	main.Parent = gui

	self.Main = main

	-- Placeholder Sidebar region.
	-- Replace this section with the Sidebar
	-- from your current Pebble version.

	local sidebarWidth =
		config.SidebarWidth
			or 218

	local sidebar =
		New("Frame", {
			Name = "Sidebar",

			Size =
				UDim2.new(
					0,
					sidebarWidth,
					1,
					0
				),

			BackgroundTransparency = 1,

			BorderSizePixel = 0
		})

	sidebar.Parent = main

	self.Sidebar = sidebar

	local content =
		New("Frame", {
			Name = "Content",

			Position =
				UDim2.fromOffset(
					sidebarWidth,
					56
				),

			Size =
				UDim2.new(
					1,
					-sidebarWidth,
					1,
					-56
				),

			BackgroundTransparency = 1,

			ClipsDescendants = true
		})

	content.Parent = main

	self.Content = content

	return self
end

function Window:Tab(config)
	config = config or {}

	local tab =
		setmetatable({}, Tab)

	tab.Window = self

	tab.Title =
		config.Title
			or "Tab"

	tab.Icon =
		config.Icon

	tab.Locked =
		config.Locked == true

	local page =
		New("ScrollingFrame", {
			Name =
				tab.Title
				.. "Page",

			Size =
				UDim2.fromScale(
					1,
					1
				),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			CanvasSize =
				UDim2.fromOffset(
					0,
					0
				),

			AutomaticCanvasSize =
				Enum.AutomaticSize.Y,

			ScrollBarThickness = 3,

			ScrollBarImageTransparency =
				0.7,

			Visible = false,

			ClipsDescendants = true
		})

	page.Parent =
		self.Content

	tab.Page = page
	tab.Container = page

	table.insert(
		self.Tabs,
		tab
	)

	return tab
end

function Tab:Select()
	if self.Locked then
		return self
	end

	for _, tab in ipairs(
		self.Window.Tabs
	) do
		tab.Page.Visible =
			tab == self
	end

	self.Window.SelectedTab =
		self

	return self
end

function Window:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

return Pebble
