--[[
	Pebble UI Library
	Version 0.4.1

	Window
	Sidebar
	Tabs
	Custom Layout Engine

	Layout types:
	- Free
	- Vertical
	- Horizontal
	- Grid

	Elements:
	- Panel
	- Text
	- Icon
	- Button
	- Divider
	- Spacer
]]

local Pebble = {
	Version = "0.4.1"
}

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- ICONS
--==================================================

local LucideIcons = {}

do
	local Success, Result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
		))()
	end)

	if Success and typeof(Result) == "table" then
		LucideIcons = Result
	else
		warn(
			"[Pebble] Failed to load Lucide icons:",
			Result
		)
	end
end

local function GetIcon(Name)
	if typeof(Name) ~= "string" then
		return ""
	end

	if string.match(Name, "^rbxassetid://") then
		return Name
	end

	local Icon = LucideIcons[Name]

	if not Icon then
		warn(
			"[Pebble] Icon not found:",
			Name
		)

		return ""
	end

	return Icon
end

--==================================================
-- THEME
--==================================================

local Theme = {
	Background = Color3.fromRGB(16, 17, 19),
	BackgroundTop = Color3.fromRGB(23, 24, 27),
	BackgroundBottom = Color3.fromRGB(13, 14, 16),

	Surface = Color3.fromRGB(25, 26, 29),
	SurfaceHover = Color3.fromRGB(31, 32, 36),
	SurfaceActive = Color3.fromRGB(36, 37, 42),

	Sidebar = Color3.fromRGB(16, 17, 19),

	Input = Color3.fromRGB(28, 29, 33),

	Stroke = Color3.fromRGB(255, 255, 255),

	Text = Color3.fromRGB(244, 244, 247),
	SubText = Color3.fromRGB(147, 148, 157),
	MutedText = Color3.fromRGB(103, 104, 113),

	Accent = Color3.fromRGB(103, 76, 255),

	Icon = Color3.fromRGB(183, 184, 194),
	IconSelected = Color3.fromRGB(245, 245, 247),

	UserBackground = Color3.fromRGB(255, 255, 255),

	Close = Color3.fromRGB(235, 76, 76),
	CloseIcon = Color3.fromRGB(255, 180, 180),
}

Pebble.Theme = Theme

--==================================================
-- DEFAULTS
--==================================================

local Defaults = {
	Title = "Pebble",
	Version = "v0.4",
	Icon = "sparkles",

	Tags = {},

	Size = UDim2.fromOffset(
		760,
		500
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	MinSize = Vector2.new(
		560,
		360
	),

	MaxSize = Vector2.new(
		1200,
		800
	),

	TopbarHeight = 56,

	SidebarWidth = 218,
	CollapsedSidebarWidth = 62,

	CornerRadius = 12,

	BackgroundTransparency = 0.28,
	SidebarTransparency = 0.28,

	SelectColor = Theme.Accent,
	SelectTransparency = 0.82,
}

--==================================================
-- CLASSES
--==================================================

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Layout = {}
Layout.__index = Layout

local Element = {}
Element.__index = Element

--==================================================
-- HELPERS
--==================================================

local function New(ClassName, Properties)
	local Object = Instance.new(ClassName)

	for Property, Value in pairs(
		Properties or {}
	) do
		Object[Property] = Value
	end

	return Object
end

local function Corner(
	Parent,
	Radius
)
	local Object = New(
		"UICorner",
		{
			CornerRadius = UDim.new(
				0,
				Radius or 8
			)
		}
	)

	Object.Parent = Parent

	return Object
end

local function AddStroke(
	Parent,
	Color,
	Transparency,
	Thickness
)
	local Object = New(
		"UIStroke",
		{
			Color = Color
				or Theme.Stroke,

			Transparency = Transparency
				or 0.9,

			Thickness = Thickness
				or 1,

			ApplyStrokeMode =
				Enum.ApplyStrokeMode.Border
		}
	)

	Object.Parent = Parent

	return Object
end

local function Tween(
	Object,
	Duration,
	Properties
)
	local Animation =
		TweenService:Create(
			Object,

			TweenInfo.new(
				Duration or 0.2,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			),

			Properties
		)

	Animation:Play()

	return Animation
end

local function CreateIcon(
	Name,
	Size
)
	return New(
		"ImageLabel",
		{
			BackgroundTransparency = 1,

			Size = UDim2.fromOffset(
				Size or 18,
				Size or 18
			),

			Image = GetIcon(Name),

			ImageColor3 = Theme.Icon,

			ScaleType =
				Enum.ScaleType.Fit
		}
	)
end

local function ResolveTextXAlignment(
	Value
)
	if Value == "Center" then
		return Enum.TextXAlignment.Center
	elseif Value == "Right" then
		return Enum.TextXAlignment.Right
	end

	return Enum.TextXAlignment.Left
end

local function ResolveTextYAlignment(
	Value
)
	if Value == "Center" then
		return Enum.TextYAlignment.Center
	elseif Value == "Bottom" then
		return Enum.TextYAlignment.Bottom
	end

	return Enum.TextYAlignment.Top
end

local function ResolveHorizontalAlignment(
	Value
)
	if Value == "Center" then
		return Enum.HorizontalAlignment.Center
	elseif Value == "Right" then
		return Enum.HorizontalAlignment.Right
	end

	return Enum.HorizontalAlignment.Left
end

local function ResolveVerticalAlignment(
	Value
)
	if Value == "Center" then
		return Enum.VerticalAlignment.Center
	elseif Value == "Bottom" then
		return Enum.VerticalAlignment.Bottom
	end

	return Enum.VerticalAlignment.Top
end

local function WrapElement(
	Instance
)
	return setmetatable(
		{
			Instance = Instance,
			Container = Instance,
		},
		Element
	)
end

--==================================================
-- ELEMENT
--==================================================

function Element:Set(
	Property,
	Value
)
	if self.Instance then
		self.Instance[Property] = Value
	end

	return self
end

function Element:Get(
	Property
)
	if not self.Instance then
		return nil
	end

	return self.Instance[Property]
end

function Element:Tween(
	Properties,
	Duration
)
	if self.Instance then
		Tween(
			self.Instance,
			Duration or 0.2,
			Properties
		)
	end

	return self
end

function Element:SetVisible(
	Visible
)
	if self.Instance then
		self.Instance.Visible = Visible
	end

	return self
end

function Element:Destroy()
	if self.Instance then
		self.Instance:Destroy()
	end
end

--==================================================
-- LAYOUT ENGINE
--==================================================

local function CreateLayout(
	Parent,
	Config
)
	Config = Config or {}

	local LayoutType =
		Config.Type
		or "Free"

	local ContainerClass =
		Config.Scrolling
		and "ScrollingFrame"
		or "Frame"

	local Frame

	if ContainerClass == "ScrollingFrame" then
		Frame = New(
			"ScrollingFrame",
			{
				Name = Config.Name
					or "Layout",

				Position = Config.Position
					or UDim2.fromOffset(
						0,
						0
					),

				Size = Config.Size
					or UDim2.fromScale(
						1,
						1
					),

				AnchorPoint =
					Config.AnchorPoint
					or Vector2.zero,

				BackgroundColor3 =
					Config.BackgroundColor
					or Theme.Surface,

				BackgroundTransparency =
					Config.BackgroundTransparency
						~= nil
					and Config.BackgroundTransparency
					or 1,

				BorderSizePixel = 0,

				CanvasSize =
					Config.CanvasSize
					or UDim2.fromOffset(
						0,
						0
					),

				AutomaticCanvasSize =
					Config.AutomaticCanvasSize
					or Enum.AutomaticSize.Y,

				ScrollBarThickness =
					Config.ScrollBarThickness
					or 2,

				ScrollBarImageTransparency =
					Config.ScrollBarImageTransparency
					or 0.7,

				ClipsDescendants =
					Config.ClipsDescendants
						~= false,

				LayoutOrder =
					Config.LayoutOrder
					or 0,

				ZIndex =
					Config.ZIndex
					or 10,

				Visible =
					Config.Visible
						~= false,
			}
		)
	else
		Frame = New(
			"Frame",
			{
				Name = Config.Name
					or "Layout",

				Position = Config.Position
					or UDim2.fromOffset(
						0,
						0
					),

				Size = Config.Size
					or UDim2.fromScale(
						1,
						1
					),

				AnchorPoint =
					Config.AnchorPoint
					or Vector2.zero,

				BackgroundColor3 =
					Config.BackgroundColor
					or Theme.Surface,

				BackgroundTransparency =
					Config.BackgroundTransparency
						~= nil
					and Config.BackgroundTransparency
					or 1,

				BorderSizePixel = 0,

				ClipsDescendants =
					Config.ClipsDescendants
						== true,

				LayoutOrder =
					Config.LayoutOrder
					or 0,

				ZIndex =
					Config.ZIndex
					or 10,

				Visible =
					Config.Visible
						~= false,
			}
		)
	end

	Frame.Parent = Parent

	if Config.CornerRadius then
		Corner(
			Frame,
			Config.CornerRadius
		)
	end

	if Config.Stroke == true then
		AddStroke(
			Frame,

			Config.StrokeColor
				or Theme.Stroke,

			Config.StrokeTransparency
				or 0.9,

			Config.StrokeThickness
				or 1
		)
	end

	local Padding =
		Config.Padding

	if typeof(Padding) == "number"
		and Padding > 0
	then
		local PaddingObject =
			New(
				"UIPadding",
				{
					PaddingTop =
						UDim.new(
							0,
							Padding
						),

					PaddingBottom =
						UDim.new(
							0,
							Padding
						),

					PaddingLeft =
						UDim.new(
							0,
							Padding
						),

					PaddingRight =
						UDim.new(
							0,
							Padding
						),
				}
			)

		PaddingObject.Parent =
			Frame
	end

	local LayoutObject

	if LayoutType == "Vertical" then
		LayoutObject =
			New(
				"UIListLayout",
				{
					FillDirection =
						Enum.FillDirection.Vertical,

					Padding =
						UDim.new(
							0,
							Config.Gap
								or 8
						),

					SortOrder =
						Enum.SortOrder.LayoutOrder,

					HorizontalAlignment =
						ResolveHorizontalAlignment(
							Config.HorizontalAlignment
						),

					VerticalAlignment =
						ResolveVerticalAlignment(
							Config.VerticalAlignment
						),
				}
			)

	elseif LayoutType == "Horizontal" then
		LayoutObject =
			New(
				"UIListLayout",
				{
					FillDirection =
						Enum.FillDirection.Horizontal,

					Padding =
						UDim.new(
							0,
							Config.Gap
								or 8
						),

					SortOrder =
						Enum.SortOrder.LayoutOrder,

					HorizontalAlignment =
						ResolveHorizontalAlignment(
							Config.HorizontalAlignment
						),

					VerticalAlignment =
						ResolveVerticalAlignment(
							Config.VerticalAlignment
						),
				}
			)

	elseif LayoutType == "Grid" then
		local Columns =
			Config.Columns or 2

		local Gap =
			Config.Gap or 10

		LayoutObject =
			New(
				"UIGridLayout",
				{
					CellPadding =
						UDim2.fromOffset(
							Gap,
							Gap
						),

					CellSize =
						Config.CellSize
						or UDim2.new(
							1 / Columns,
							-Gap,
							0,
							Config.CellHeight
								or 120
						),

					SortOrder =
						Enum.SortOrder.LayoutOrder,

					FillDirection =
						Enum.FillDirection.Horizontal,

					FillDirectionMaxCells =
						Columns,
				}
			)
	end

	if LayoutObject then
		LayoutObject.Parent =
			Frame
	end

	local Object =
		setmetatable(
			{
				Frame = Frame,
				Container = Frame,

				Type = LayoutType,

				LayoutObject =
					LayoutObject,

				_Order = 0,

				Children = {},
			},
			Layout
		)

	return Object
end

--==================================================
-- LAYOUT CHILD
--==================================================

function Layout:_NextOrder(
	Config
)
	self._Order += 1

	if Config.LayoutOrder == nil then
		Config.LayoutOrder =
			self._Order
	end
end

function Layout:Layout(
	Config
)
	Config = Config or {}

	self:_NextOrder(Config)

	local Object =
		CreateLayout(
			self.Container,
			Config
		)

	table.insert(
		self.Children,
		Object
	)

	return Object
end

function Layout:Free(
	Config
)
	Config = Config or {}

	Config.Type = "Free"

	return self:Layout(Config)
end

function Layout:Vertical(
	Config
)
	Config = Config or {}

	Config.Type = "Vertical"

	return self:Layout(Config)
end

function Layout:Horizontal(
	Config
)
	Config = Config or {}

	Config.Type = "Horizontal"

	return self:Layout(Config)
end

function Layout:Grid(
	Config
)
	Config = Config or {}

	Config.Type = "Grid"

	return self:Layout(Config)
end

--==================================================
-- TEXT
--==================================================

function Layout:Text(
	Config
)
	Config = Config or {}

	self:_NextOrder(Config)

	local Label =
		New(
			"TextLabel",
			{
				Name = Config.Name
					or "Text",

				Position = Config.Position
					or UDim2.fromOffset(
						0,
						0
					),

				Size = Config.Size
					or UDim2.new(
						1,
						0,
						0,
						22
					),

				AnchorPoint =
					Config.AnchorPoint
					or Vector2.zero,

				BackgroundColor3 =
					Config.BackgroundColor
					or Theme.Surface,

				BackgroundTransparency =
					Config.BackgroundTransparency
						~= nil
					and Config.BackgroundTransparency
					or 1,

				BorderSizePixel = 0,

				Text = Config.Text
					or "Text",

				Font = Config.Font
					or Enum.Font.Gotham,

				TextSize = Config.TextSize
					or 12,

				TextColor3 =
					Config.TextColor
					or Theme.Text,

				TextTransparency =
					Config.TextTransparency
					or 0,

				TextXAlignment =
					ResolveTextXAlignment(
						Config.Alignment
					),

				TextYAlignment =
					ResolveTextYAlignment(
						Config.VerticalAlignment
					),

				TextWrapped =
					Config.TextWrapped
						~= false,

				RichText =
					Config.RichText
						== true,

				LayoutOrder =
					Config.LayoutOrder,

				ZIndex =
					Config.ZIndex
					or 20,

				Visible =
					Config.Visible
						~= false,
			}
		)

	if Config.CornerRadius then
		Corner(
			Label,
			Config.CornerRadius
		)
	end

	Label.Parent =
		self.Container

	return WrapElement(Label)
end

--==================================================
-- ICON
--==================================================

function Layout:Icon(
	Config
)
	Config = Config or {}

	self:_NextOrder(Config)

	local Icon =
		New(
			"ImageLabel",
			{
				Name = Config.Name
					or "Icon",

				Position = Config.Position
					or UDim2.fromOffset(
						0,
						0
					),

				Size = Config.Size
					or UDim2.fromOffset(
						18,
						18
					),

				AnchorPoint =
					Config.AnchorPoint
					or Vector2.zero,

				BackgroundColor3 =
					Config.BackgroundColor
					or Theme.Surface,

				BackgroundTransparency =
					Config.BackgroundTransparency
						~= nil
					and Config.BackgroundTransparency
					or 1,

				BorderSizePixel = 0,

				Image =
					GetIcon(
						Config.Icon
							or "circle"
					),

				ImageColor3 =
					Config.Color
					or Theme.Icon,

				ImageTransparency =
					Config.Transparency
					or 0,

				ScaleType =
					Enum.ScaleType.Fit,

				LayoutOrder =
					Config.LayoutOrder,

				ZIndex =
					Config.ZIndex
					or 20,
			}
		)

	Icon.Parent =
		self.Container

	return WrapElement(Icon)
end

--==================================================
-- BUTTON
--==================================================

function Layout:Button(
	Config
)
	Config = Config or {}

	self:_NextOrder(Config)

	local Button =
		New(
			"TextButton",
			{
				Name = Config.Name
					or "Button",

				Position = Config.Position
					or UDim2.fromOffset(
						0,
						0
					),

				Size = Config.Size
					or UDim2.new(
						1,
						0,
						0,
						36
					),

				AnchorPoint =
					Config.AnchorPoint
					or Vector2.zero,

				BackgroundColor3 =
					Config.BackgroundColor
					or Theme.Surface,

				BackgroundTransparency =
					Config.BackgroundTransparency
						~= nil
					and Config.BackgroundTransparency
					or 0.08,

				BorderSizePixel = 0,

				AutoButtonColor = false,

				Text = Config.Text
					or "Button",

				Font = Config.Font
					or Enum.Font.GothamMedium,

				TextSize =
					Config.TextSize
					or 12,

				TextColor3 =
					Config.TextColor
					or Theme.Text,

				TextXAlignment =
					ResolveTextXAlignment(
						Config.Alignment
							or "Center"
					),

				LayoutOrder =
					Config.LayoutOrder,

				ZIndex =
					Config.ZIndex
					or 20,

				Visible =
					Config.Visible
						~= false,
			}
		)

	Corner(
		Button,
		Config.CornerRadius
			or 8
	)

	if Config.Stroke ~= false then
		AddStroke(
			Button,

			Config.StrokeColor
				or Theme.Stroke,

			Config.StrokeTransparency
				or 0.93,

			Config.StrokeThickness
				or 1
		)
	end

	Button.Parent =
		self.Container

	local NormalColor =
		Button.BackgroundColor3

	local NormalTransparency =
		Button.BackgroundTransparency

	local HoverColor =
		Config.HoverColor
		or Theme.SurfaceHover

	local HoverTransparency =
		Config.HoverTransparency
			~= nil
		and Config.HoverTransparency
		or NormalTransparency

	Button.MouseEnter:Connect(function()
		Tween(
			Button,
			0.16,
			{
				BackgroundColor3 =
					HoverColor,

				BackgroundTransparency =
					HoverTransparency,
			}
		)
	end)

	Button.MouseLeave:Connect(function()
		Tween(
			Button,
			0.16,
			{
				BackgroundColor3 =
					NormalColor,

				BackgroundTransparency =
					NormalTransparency,
			}
		)
	end)

	if Config.Callback then
		Button.MouseButton1Click:Connect(
			Config.Callback
		)
	end

	local Wrapper =
		WrapElement(Button)

	function Wrapper:OnClick(
		Callback
	)
		Button.MouseButton1Click:Connect(
			Callback
		)

		return Wrapper
	end

	return Wrapper
end

--==================================================
-- DIVIDER
--==================================================

function Layout:Divider(
	Config
)
	Config = Config or {}

	self:_NextOrder(Config)

	local Holder =
		New(
			"Frame",
			{
				Name = "Divider",

				Position =
					Config.Position
					or UDim2.fromOffset(
						0,
						0
					),

				Size =
					Config.Size
					or UDim2.new(
						1,
						0,
						0,
						12
					),

				BackgroundTransparency = 1,

				LayoutOrder =
					Config.LayoutOrder,

				ZIndex =
					Config.ZIndex
					or 15,
			}
		)

	Holder.Parent =
		self.Container

	local Line =
		New(
			"Frame",
			{
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
						Config.Thickness
							or 1
					),

				BackgroundColor3 =
					Config.Color
					or Theme.Stroke,

				BackgroundTransparency =
					Config.Transparency
						~= nil
					and Config.Transparency
					or 0.91,

				BorderSizePixel = 0,

				ZIndex =
					(Config.ZIndex or 15)
					+ 1,
			}
		)

	Line.Parent =
		Holder

	return WrapElement(Holder)
end

--==================================================
-- SPACER
--==================================================

function Layout:Spacer(
	Config
)
	Config = Config or {}

	self:_NextOrder(Config)

	local Spacer =
		New(
			"Frame",
			{
				Name = "Spacer",

				Size =
					Config.Size
					or UDim2.new(
						1,
						0,
						0,
						Config.Height
							or 12
					),

				BackgroundTransparency = 1,

				LayoutOrder =
					Config.LayoutOrder,

				ZIndex =
					Config.ZIndex
					or 10,
			}
		)

	Spacer.Parent =
		self.Container

	return WrapElement(Spacer)
end

--==================================================
-- PANEL
--==================================================

function Layout:Panel(
	Config
)
	Config = Config or {}

	self:_NextOrder(Config)

	local Panel =
		New(
			"Frame",
			{
				Name = Config.Name
					or "Panel",

				Position = Config.Position
					or UDim2.fromOffset(
						0,
						0
					),

				Size = Config.Size
					or UDim2.new(
						1,
						0,
						0,
						100
					),

				AnchorPoint =
					Config.AnchorPoint
					or Vector2.zero,

				BackgroundColor3 =
					Config.BackgroundColor
					or Theme.Surface,

				BackgroundTransparency =
					Config.BackgroundTransparency
						~= nil
					and Config.BackgroundTransparency
					or 0.14,

				BorderSizePixel = 0,

				ClipsDescendants =
					Config.ClipsDescendants
						== true,

				LayoutOrder =
					Config.LayoutOrder,

				ZIndex =
					Config.ZIndex
					or 15,

				Visible =
					Config.Visible
						~= false,
			}
		)

	Corner(
		Panel,
		Config.CornerRadius
			or 10
	)

	if Config.Stroke ~= false then
		AddStroke(
			Panel,

			Config.StrokeColor
				or Theme.Stroke,

			Config.StrokeTransparency
				or 0.93,

			Config.StrokeThickness
				or 1
		)
	end

	Panel.Parent =
		self.Container

	local Wrapper =
		WrapElement(Panel)

	Wrapper._Layout =
		setmetatable(
			{
				Frame = Panel,
				Container = Panel,

				Type = "Free",

				_Order = 0,

				Children = {},
			},
			Layout
		)

	function Wrapper:Layout(
		ChildConfig
	)
		return self._Layout:Layout(
			ChildConfig
		)
	end

	function Wrapper:Free(
		ChildConfig
	)
		return self._Layout:Free(
			ChildConfig
		)
	end

	function Wrapper:Vertical(
		ChildConfig
	)
		return self._Layout:Vertical(
			ChildConfig
		)
	end

	function Wrapper:Horizontal(
		ChildConfig
	)
		return self._Layout:Horizontal(
			ChildConfig
		)
	end

	function Wrapper:Grid(
		ChildConfig
	)
		return self._Layout:Grid(
			ChildConfig
		)
	end

	function Wrapper:Panel(
		ChildConfig
	)
		return self._Layout:Panel(
			ChildConfig
		)
	end

	function Wrapper:Text(
		ChildConfig
	)
		return self._Layout:Text(
			ChildConfig
		)
	end

	function Wrapper:Icon(
		ChildConfig
	)
		return self._Layout:Icon(
			ChildConfig
		)
	end

	function Wrapper:Button(
		ChildConfig
	)
		return self._Layout:Button(
			ChildConfig
		)
	end

	function Wrapper:Divider(
		ChildConfig
	)
		return self._Layout:Divider(
			ChildConfig
		)
	end

	function Wrapper:Spacer(
		ChildConfig
	)
		return self._Layout:Spacer(
			ChildConfig
		)
	end

	return Wrapper
end

--==================================================
-- CONTROL BUTTON
--==================================================

local function CreateControlButton(
	IconName,
	Parent
)
	local Button =
		New(
			"TextButton",
			{
				Size =
					UDim2.fromOffset(
						32,
						32
					),

				BackgroundColor3 =
					Color3.new(
						1,
						1,
						1
					),

				BackgroundTransparency = 1,

				Text = "",

				AutoButtonColor = false,

				ZIndex = 50,
			}
		)

	Corner(
		Button,
		8
	)

	local Icon =
		CreateIcon(
			IconName,
			16
		)

	Icon.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	Icon.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	Icon.ZIndex = 51

	Icon.Parent =
		Button

	Button.MouseEnter:Connect(function()
		Tween(
			Button,
			0.15,
			{
				BackgroundTransparency =
					0.92,
			}
		)
	end)

	Button.MouseLeave:Connect(function()
		Tween(
			Button,
			0.15,
			{
				BackgroundTransparency =
					1,
			}
		)
	end)

	Button.Parent =
		Parent

	return Button, Icon
end

--==================================================
-- CREATE WINDOW
--==================================================

function Pebble:CreateWindow(
	Config
)
	Config = Config or {}

	local self =
		setmetatable(
			{},
			Window
		)

	self.Title =
		Config.Title
		or Defaults.Title

	self.Version =
		Config.Version
		or Defaults.Version

	self.Icon =
		Config.Icon
		or Defaults.Icon

	self.Tags =
		Config.Tags
		or Defaults.Tags

	self.Size =
		Config.Size
		or Defaults.Size

	self.MinSize =
		Config.MinSize
		or Defaults.MinSize

	self.MaxSize =
		Config.MaxSize
		or Defaults.MaxSize

	self.TopbarHeight =
		Config.TopbarHeight
		or Defaults.TopbarHeight

	self.SidebarWidth =
		Config.SidebarWidth
		or Defaults.SidebarWidth

	self.CollapsedSidebarWidth =
		Config.CollapsedSidebarWidth
		or Defaults.CollapsedSidebarWidth

	self.CornerRadius =
		Config.CornerRadius
		or Defaults.CornerRadius

	self.BackgroundTransparency =
		Config.BackgroundTransparency
			~= nil
		and math.clamp(
			Config.BackgroundTransparency,
			0,
			1
		)
		or Defaults.BackgroundTransparency

	self.SidebarTransparency =
		Config.SidebarTransparency
			~= nil
		and math.clamp(
			Config.SidebarTransparency,
			0,
			1
		)
		or self.BackgroundTransparency

	self.SelectColor =
		Config.SelectColor
		or Defaults.SelectColor

	self.SelectTransparency =
		Config.SelectTransparency
			~= nil
		and math.clamp(
			Config.SelectTransparency,
			0,
			1
		)
		or Defaults.SelectTransparency

	self.Tabs = {}

	self.SelectedTab = nil

	self.SidebarCollapsed = false

	self.Minimized = false

	self.Maximized = false

	self._SidebarOrder = 0

	--==============================================
	-- SCREENGUI
	--==============================================

	local ScreenGui =
		New(
			"ScreenGui",
			{
				Name =
					"PebbleUI_"
					.. tostring(
						math.random(
							100000,
							999999
						)
					),

				IgnoreGuiInset = true,

				ResetOnSpawn = false,

				ZIndexBehavior =
					Enum.ZIndexBehavior.Sibling,
			}
		)

	local Success =
		pcall(function()
			ScreenGui.Parent =
				CoreGui
		end)

	if not Success then
		ScreenGui.Parent =
			LocalPlayer:WaitForChild(
				"PlayerGui"
			)
	end

	self.ScreenGui =
		ScreenGui

	--==============================================
	-- MAIN
	--==============================================

	local Main =
		New(
			"Frame",
			{
				Name = "Main",

				AnchorPoint =
					Vector2.new(
						0.5,
						0.5
					),

				Position =
					Config.Position
					or Defaults.Position,

				Size =
					self.Size,

				BackgroundTransparency = 1,

				BorderSizePixel = 0,
			}
		)

	Main.Parent =
		ScreenGui

	self.Main =
		Main

	--==============================================
	-- CLIP ROOT
	--==============================================

	local ClipRoot =
		New(
			"CanvasGroup",
			{
				Name = "ClipRoot",

				Size =
					UDim2.fromScale(
						1,
						1
					),

				BackgroundTransparency = 1,

				GroupTransparency = 0,

				ClipsDescendants = true,

				BorderSizePixel = 0,
			}
		)

	Corner(
		ClipRoot,
		self.CornerRadius
	)

	ClipRoot.Parent =
		Main

	self.ClipRoot =
		ClipRoot

	AddStroke(
		ClipRoot,
		Theme.Stroke,
		0.88,
		1
	)

	--==============================================
	-- SURFACE
	--==============================================

	local Surface =
		New(
			"Frame",
			{
				Name = "Surface",

				Size =
					UDim2.fromScale(
						1,
						1
					),

				BackgroundColor3 =
					Theme.Background,

				BackgroundTransparency =
					self.BackgroundTransparency,

				BorderSizePixel = 0,

				ZIndex = 1,
			}
		)

	Surface.Parent =
		ClipRoot

	self.Surface =
		Surface

	local Gradient =
		New(
			"UIGradient",
			{
				Color =
					ColorSequence.new({
						ColorSequenceKeypoint.new(
							0,
							Theme.BackgroundTop
						),

						ColorSequenceKeypoint.new(
							1,
							Theme.BackgroundBottom
						),
					}),

				Rotation = 90,
			}
		)

	Gradient.Parent =
		Surface

	--==============================================
	-- TOPBAR
	--==============================================

	local Topbar =
		New(
			"Frame",
			{
				Name = "Topbar",

				Size =
					UDim2.new(
						1,
						0,
						0,
						self.TopbarHeight
					),

				BackgroundTransparency = 1,

				ZIndex = 30,
			}
		)

	Topbar.Parent =
		ClipRoot

	self.Topbar =
		Topbar

	--==============================================
	-- APP ICON
	--==============================================

	local AppIcon =
		CreateIcon(
			self.Icon,
			20
		)

	AppIcon.AnchorPoint =
		Vector2.new(
			0,
			0.5
		)

	AppIcon.Position =
		UDim2.new(
			0,
			17,
			0.5,
			0
		)

	AppIcon.ImageColor3 =
		Theme.Text

	AppIcon.ZIndex = 32

	AppIcon.Parent =
		Topbar

	self.IconImage =
		AppIcon

	--==============================================
	-- TITLE
	--==============================================

	local Title =
		New(
			"TextLabel",
			{
				BackgroundTransparency = 1,

				Position =
					UDim2.fromOffset(
						48,
						11
					),

				Size =
					UDim2.fromOffset(
						220,
						18
					),

				Font =
					Enum.Font.GothamMedium,

				Text =
					self.Title,

				TextColor3 =
					Theme.Text,

				TextSize = 14,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				ZIndex = 32,
			}
		)

	Title.Parent =
		Topbar

	local Version =
		New(
			"TextLabel",
			{
				BackgroundTransparency = 1,

				Position =
					UDim2.fromOffset(
						48,
						31
					),

				Size =
					UDim2.fromOffset(
						80,
						14
					),

				Font =
					Enum.Font.Gotham,

				Text =
					self.Version,

				TextColor3 =
					Theme.MutedText,

				TextSize = 10,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				ZIndex = 32,
			}
		)

	Version.Parent =
		Topbar

	--==============================================
	-- TAGS
	--==============================================

	local TagHolder =
		New(
			"Frame",
			{
				BackgroundTransparency = 1,

				Position =
					UDim2.fromOffset(
						160,
						17
					),

				Size =
					UDim2.new(
						1,
						-360,
						0,
						22
					),

				ZIndex = 32,
			}
		)

	TagHolder.Parent =
		Topbar

	local TagLayout =
		New(
			"UIListLayout",
			{
				FillDirection =
					Enum.FillDirection.Horizontal,

				Padding =
					UDim.new(
						0,
						6
					),

				VerticalAlignment =
					Enum.VerticalAlignment.Center,
			}
		)

	TagLayout.Parent =
		TagHolder

	for Index, Text in ipairs(
		self.Tags
	) do
		local Tag =
			New(
				"TextLabel",
				{
					AutomaticSize =
						Enum.AutomaticSize.X,

					Size =
						UDim2.fromOffset(
							0,
							20
						),

					BackgroundColor3 =
						Color3.new(
							1,
							1,
							1
						),

					BackgroundTransparency =
						0.92,

					Text =
						"  "
						.. tostring(Text)
						.. "  ",

					TextColor3 =
						Theme.SubText,

					Font =
						Enum.Font.GothamMedium,

					TextSize = 10,

					LayoutOrder =
						Index,

					ZIndex = 33,
				}
			)

		Corner(
			Tag,
			6
		)

		Tag.Parent =
			TagHolder
	end

	--==============================================
	-- CONTROLS
	--==============================================

	local Controls =
		New(
			"Frame",
			{
				AnchorPoint =
					Vector2.new(
						1,
						0.5
					),

				Position =
					UDim2.new(
						1,
						-12,
						0.5,
						0
					),

				Size =
					UDim2.fromOffset(
						104,
						32
					),

				BackgroundTransparency = 1,

				ZIndex = 50,
			}
		)

	Controls.Parent =
		Topbar

	local ControlLayout =
		New(
			"UIListLayout",
			{
				FillDirection =
					Enum.FillDirection.Horizontal,

				HorizontalAlignment =
					Enum.HorizontalAlignment.Right,

				VerticalAlignment =
					Enum.VerticalAlignment.Center,

				Padding =
					UDim.new(
						0,
						4
					),
			}
		)

	ControlLayout.Parent =
		Controls

	local MinimizeButton =
		CreateControlButton(
			"minus",
			Controls
		)

	local MaximizeButton =
		CreateControlButton(
			"square",
			Controls
		)

	local CloseButton,
		CloseIcon =
		CreateControlButton(
			"x",
			Controls
		)

	CloseButton.MouseEnter:Connect(function()
		Tween(
			CloseButton,
			0.15,
			{
				BackgroundColor3 =
					Theme.Close,

				BackgroundTransparency =
					0.78,
			}
		)

		Tween(
			CloseIcon,
			0.15,
			{
				ImageColor3 =
					Theme.CloseIcon,
			}
		)
	end)

	CloseButton.MouseLeave:Connect(function()
		Tween(
			CloseButton,
			0.15,
			{
				BackgroundTransparency = 1,
			}
		)

		Tween(
			CloseIcon,
			0.15,
			{
				ImageColor3 =
					Theme.Icon,
			}
		)
	end)

	--==============================================
	-- SIDEBAR
	--==============================================

	local Sidebar =
		New(
			"Frame",
			{
				Name = "Sidebar",

				Position =
					UDim2.fromOffset(
						0,
						self.TopbarHeight
					),

				Size =
					UDim2.new(
						0,
						self.SidebarWidth,
						1,
						-self.TopbarHeight
					),

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				ClipsDescendants = false,

				ZIndex = 10,
			}
		)

	Sidebar.Parent =
		ClipRoot

	self.Sidebar =
		Sidebar

	local SidebarGlass =
		New(
			"Frame",
			{
				Name = "SidebarGlass",

				Size =
					UDim2.fromScale(
						1,
						1
					),

				BackgroundColor3 =
					Theme.Sidebar,

				BackgroundTransparency =
					self.SidebarTransparency,

				BorderSizePixel = 0,

				ZIndex = 10,
			}
		)

	SidebarGlass.Parent =
		Sidebar

	self.SidebarGlass =
		SidebarGlass

	local SidebarLine =
		New(
			"Frame",
			{
				AnchorPoint =
					Vector2.new(
						1,
						0
					),

				Position =
					UDim2.new(
						1,
						0,
						0,
						0
					),

				Size =
					UDim2.new(
						0,
						1,
						1,
						0
					),

				BackgroundColor3 =
					Theme.Stroke,

				BackgroundTransparency =
					0.94,

				BorderSizePixel = 0,

				ZIndex = 12,
			}
		)

	SidebarLine.Parent =
		Sidebar

	--==============================================
	-- SIDEBAR TOGGLE
	--==============================================

	local SidebarToggle =
		New(
			"TextButton",
			{
				Name = "SidebarToggle",

				AnchorPoint =
					Vector2.new(
						0.5,
						0
					),

				Position =
					UDim2.new(
						1,
						0,
						0,
						10
					),

				Size =
					UDim2.fromOffset(
						28,
						28
					),

				BackgroundColor3 =
					Theme.Surface,

				BackgroundTransparency =
					0.08,

				Text = "",

				AutoButtonColor = false,

				BorderSizePixel = 0,

				ZIndex = 60,
			}
		)

	Corner(
		SidebarToggle,
		8
	)

	AddStroke(
		SidebarToggle,
		Theme.Stroke,
		0.88,
		1
	)

	SidebarToggle.Parent =
		Sidebar

	local SidebarToggleIcon =
		CreateIcon(
			"panel-left-close",
			14
		)

	SidebarToggleIcon.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	SidebarToggleIcon.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	SidebarToggleIcon.ZIndex = 61

	SidebarToggleIcon.Parent =
		SidebarToggle

	self.SidebarToggle =
		SidebarToggle

	self.SidebarToggleIcon =
		SidebarToggleIcon

	--==============================================
	-- TAB SCROLLER
	--==============================================

	local TabScroller =
		New(
			"ScrollingFrame",
			{
				Name = "Tabs",

				Position =
					UDim2.fromOffset(
						8,
						8
					),

				Size =
					UDim2.new(
						1,
						-16,
						1,
						-88
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

				ScrollBarThickness = 0,

				ClipsDescendants = true,

				ZIndex = 15,
			}
		)

	TabScroller.Parent =
		Sidebar

	self.TabScroller =
		TabScroller

	local SidebarLayout =
		New(
			"UIListLayout",
			{
				Padding =
					UDim.new(
						0,
						4
					),

				SortOrder =
					Enum.SortOrder.LayoutOrder,
			}
		)

	SidebarLayout.Parent =
		TabScroller

	--==============================================
	-- USER PANEL
	--==============================================

	local UserPanel =
		New(
			"Frame",
			{
				AnchorPoint =
					Vector2.new(
						0,
						1
					),

				Position =
					UDim2.new(
						0,
						8,
						1,
						-8
					),

				Size =
					UDim2.new(
						1,
						-16,
						0,
						64
					),

				BackgroundColor3 =
					Theme.UserBackground,

				BackgroundTransparency =
					0.94,

				BorderSizePixel = 0,

				ClipsDescendants = true,

				ZIndex = 20,
			}
		)

	Corner(
		UserPanel,
		10
	)

	AddStroke(
		UserPanel,
		Theme.Stroke,
		0.95,
		1
	)

	UserPanel.Parent =
		Sidebar

	self.UserPanel =
		UserPanel

	local Avatar =
		New(
			"ImageLabel",
			{
				AnchorPoint =
					Vector2.new(
						0,
						0.5
					),

				Position =
					UDim2.new(
						0,
						11,
						0.5,
						0
					),

				Size =
					UDim2.fromOffset(
						38,
						38
					),

				BackgroundColor3 =
					Theme.Surface,

				BorderSizePixel = 0,

				Image = "",

				ZIndex = 21,
			}
		)

	Corner(
		Avatar,
		19
	)

	Avatar.Parent =
		UserPanel

	self.UserAvatar =
		Avatar

	task.spawn(function()
		local SuccessThumb,
			Thumbnail =
			pcall(function()
				return Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,

					Enum.ThumbnailType.HeadShot,

					Enum.ThumbnailSize.Size150x150
				)
			end)

		if SuccessThumb then
			Avatar.Image =
				Thumbnail
		end
	end)

	local DisplayName =
		New(
			"TextLabel",
			{
				BackgroundTransparency = 1,

				Position =
					UDim2.fromOffset(
						59,
						13
					),

				Size =
					UDim2.new(
						1,
						-70,
						0,
						18
					),

				Font =
					Enum.Font.GothamMedium,

				Text =
					LocalPlayer.DisplayName,

				TextColor3 =
					Theme.Text,

				TextSize = 12,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				TextTruncate =
					Enum.TextTruncate.AtEnd,

				ZIndex = 21,
			}
		)

	DisplayName.Parent =
		UserPanel

	local Username =
		New(
			"TextLabel",
			{
				BackgroundTransparency = 1,

				Position =
					UDim2.fromOffset(
						59,
						33
					),

				Size =
					UDim2.new(
						1,
						-70,
						0,
						16
					),

				Font =
					Enum.Font.Gotham,

				Text =
					"@"
					.. LocalPlayer.Name,

				TextColor3 =
					Theme.SubText,

				TextSize = 10,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				TextTruncate =
					Enum.TextTruncate.AtEnd,

				ZIndex = 21,
			}
		)

	Username.Parent =
		UserPanel

	self.DisplayNameLabel =
		DisplayName

	self.UsernameLabel =
		Username

	--==============================================
	-- CONTENT
	--==============================================

	local Content =
		New(
			"Frame",
			{
				Name = "Content",

				Position =
					UDim2.fromOffset(
						self.SidebarWidth,
						self.TopbarHeight
					),

				Size =
					UDim2.new(
						1,
						-self.SidebarWidth,
						1,
						-self.TopbarHeight
					),

				BackgroundTransparency = 1,

				ClipsDescendants = true,

				ZIndex = 8,
			}
		)

	Content.Parent =
		ClipRoot

	self.Content =
		Content

	--==============================================
	-- SIDEBAR COLLAPSE
	--==============================================

	function self:SetSidebarCollapsed(
		Collapsed
	)
		self.SidebarCollapsed =
			Collapsed == true

		local Width =
			self.SidebarCollapsed
			and self.CollapsedSidebarWidth
			or self.SidebarWidth

		Tween(
			self.Sidebar,
			0.38,
			{
				Size =
					UDim2.new(
						0,
						Width,
						1,
						-self.TopbarHeight
					),
			}
		)

		Tween(
			self.Content,
			0.38,
			{
				Position =
					UDim2.fromOffset(
						Width,
						self.TopbarHeight
					),

				Size =
					UDim2.new(
						1,
						-Width,
						1,
						-self.TopbarHeight
					),
			}
		)

		self.SidebarToggleIcon.Image =
			GetIcon(
				self.SidebarCollapsed
					and "panel-left-open"
					or "panel-left-close"
			)

		for _, TabObject in ipairs(
			self.Tabs
		) do
			if TabObject.TitleLabel then
				Tween(
					TabObject.TitleLabel,
					0.2,
					{
						TextTransparency =
							self.SidebarCollapsed
							and 1
							or 0,
					}
				)
			end

			if TabObject.LockIcon then
				Tween(
					TabObject.LockIcon,
					0.2,
					{
						ImageTransparency =
							self.SidebarCollapsed
							and 1
							or 0,
					}
				)
			end
		end

		Tween(
			DisplayName,
			0.2,
			{
				TextTransparency =
					self.SidebarCollapsed
					and 1
					or 0,
			}
		)

		Tween(
			Username,
			0.2,
			{
				TextTransparency =
					self.SidebarCollapsed
					and 1
					or 0,
			}
		)

		Tween(
			Avatar,
			0.35,
			{
				Position =
					self.SidebarCollapsed
					and UDim2.new(
						0.5,
						-19,
						0.5,
						0
					)
					or UDim2.new(
						0,
						11,
						0.5,
						0
					),
			}
		)
	end

	SidebarToggle.MouseButton1Click:Connect(function()
		self:SetSidebarCollapsed(
			not self.SidebarCollapsed
		)
	end)

	--==============================================
	-- CLOSE
	--==============================================

	CloseButton.MouseButton1Click:Connect(function()
		Tween(
			Main,
			0.18,
			{
				Size =
					UDim2.new(
						Main.Size.X.Scale,
						Main.Size.X.Offset - 18,

						Main.Size.Y.Scale,
						Main.Size.Y.Offset - 18
					),
			}
		)

		task.delay(
			0.18,
			function()
				ScreenGui:Destroy()
			end
		)
	end)

	--==============================================
	-- MINIMIZE
	--==============================================

	local NormalSize =
		Main.Size

	MinimizeButton.MouseButton1Click:Connect(function()
		self.Minimized =
			not self.Minimized

		if self.Minimized then
			NormalSize =
				Main.Size

			Tween(
				Main,
				0.3,
				{
					Size =
						UDim2.new(
							NormalSize.X.Scale,
							NormalSize.X.Offset,

							0,
							self.TopbarHeight
						),
				}
			)
		else
			Tween(
				Main,
				0.3,
				{
					Size =
						NormalSize,
				}
			)
		end
	end)

	--==============================================
	-- MAXIMIZE
	--==============================================

	local PreviousPosition =
		Main.Position

	local PreviousSize =
		Main.Size

	MaximizeButton.MouseButton1Click:Connect(function()
		self.Maximized =
			not self.Maximized

		if self.Maximized then
			PreviousPosition =
				Main.Position

			PreviousSize =
				Main.Size

			Main.AnchorPoint =
				Vector2.zero

			Tween(
				Main,
				0.35,
				{
					Position =
						UDim2.fromOffset(
							12,
							12
						),

					Size =
						UDim2.new(
							1,
							-24,
							1,
							-24
						),
				}
			)
		else
			Main.AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				)

			Tween(
				Main,
				0.35,
				{
					Position =
						PreviousPosition,

					Size =
						PreviousSize,
				}
			)
		end
	end)

	--==============================================
	-- DRAG
	--==============================================

	local Dragging = false
	local DragStart
	local StartPosition

	Topbar.InputBegan:Connect(function(Input)
		if
			Input.UserInputType
				== Enum.UserInputType.MouseButton1
			or Input.UserInputType
				== Enum.UserInputType.Touch
		then
			Dragging = true

			DragStart =
				Input.Position

			StartPosition =
				Main.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not Dragging then
			return
		end

		if
			Input.UserInputType
				== Enum.UserInputType.MouseMovement
			or Input.UserInputType
				== Enum.UserInputType.Touch
		then
			local Delta =
				Input.Position
				- DragStart

			Main.Position =
				UDim2.new(
					StartPosition.X.Scale,

					StartPosition.X.Offset
						+ Delta.X,

					StartPosition.Y.Scale,

					StartPosition.Y.Offset
						+ Delta.Y
				)
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if
			Input.UserInputType
				== Enum.UserInputType.MouseButton1
			or Input.UserInputType
				== Enum.UserInputType.Touch
		then
			Dragging = false
		end
	end)

	--==============================================
	-- RESIZE
	--==============================================

	local ResizeButton =
		New(
			"TextButton",
			{
				Name = "ResizeHandle",

				AnchorPoint =
					Vector2.new(
						1,
						1
					),

				Position =
					UDim2.fromScale(
						1,
						1
					),

				Size =
					UDim2.fromOffset(
						20,
						20
					),

				BackgroundTransparency = 1,

				Text = "",

				ZIndex = 100,
			}
		)

	ResizeButton.Parent =
		Main

	local Resizing = false
	local ResizeStart
	local StartSize

	ResizeButton.InputBegan:Connect(function(Input)
		if
			Input.UserInputType
				== Enum.UserInputType.MouseButton1
		then
			Resizing = true

			ResizeStart =
				Input.Position

			StartSize =
				Main.AbsoluteSize
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if not Resizing then
			return
		end

		if
			Input.UserInputType
				== Enum.UserInputType.MouseMovement
		then
			local Delta =
				Input.Position
				- ResizeStart

			local Width =
				math.clamp(
					StartSize.X
						+ Delta.X,

					self.MinSize.X,

					self.MaxSize.X
				)

			local Height =
				math.clamp(
					StartSize.Y
						+ Delta.Y,

					self.MinSize.Y,

					self.MaxSize.Y
				)

			Main.Size =
				UDim2.fromOffset(
					Width,
					Height
				)

			NormalSize =
				Main.Size
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if
			Input.UserInputType
				== Enum.UserInputType.MouseButton1
		then
			Resizing = false
		end
	end)

	return self
end

--==================================================
-- TAB
--==================================================

function Window:Tab(
	Config
)
	Config = Config or {}

	local Object =
		setmetatable(
			{},
			Tab
		)

	Object.Window =
		self

	Object.Title =
		Config.Title
		or "Tab"

	Object.Icon =
		Config.Icon

	Object.Locked =
		Config.Locked == true

	Object.Selected =
		false

	self._SidebarOrder += 1

	--==============================================
	-- TAB BUTTON
	--==============================================

	local Button =
		New(
			"TextButton",
			{
				Name =
					Object.Title,

				Size =
					UDim2.new(
						1,
						0,
						0,
						42
					),

				BackgroundColor3 =
					self.SelectColor,

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				Text = "",

				AutoButtonColor = false,

				LayoutOrder =
					self._SidebarOrder,

				ZIndex = 25,
			}
		)

	Corner(
		Button,
		9
	)

	Button.Parent =
		self.TabScroller

	Object.Button =
		Button

	--==============================================
	-- ACCENT
	--==============================================

	local Accent =
		New(
			"Frame",
			{
				AnchorPoint =
					Vector2.new(
						0,
						0.5
					),

				Position =
					UDim2.new(
						0,
						2,
						0.5,
						0
					),

				Size =
					UDim2.fromOffset(
						3,
						20
					),

				BackgroundColor3 =
					self.SelectColor,

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				ZIndex = 27,
			}
		)

	Corner(
		Accent,
		2
	)

	Accent.Parent =
		Button

	Object.Accent =
		Accent

	--==============================================
	-- TAB ICON
	--==============================================

	if Object.Icon then
		local Icon =
			CreateIcon(
				Object.Icon,
				17
			)

		Icon.AnchorPoint =
			Vector2.new(
				0,
				0.5
			)

		Icon.Position =
			UDim2.new(
				0,
				13,
				0.5,
				0
			)

		Icon.ZIndex = 27

		Icon.Parent =
			Button

		Object.IconImage =
			Icon
	end

	--==============================================
	-- TAB TITLE
	--==============================================

	local TitleLabel =
		New(
			"TextLabel",
			{
				BackgroundTransparency = 1,

				Position =
					UDim2.fromOffset(
						Object.Icon
							and 42
							or 14,

						0
					),

				Size =
					UDim2.new(
						1,
						Object.Locked
							and -74
							or -52,

						1,
						0
					),

				Font =
					Enum.Font.GothamMedium,

				Text =
					Object.Title,

				TextColor3 =
					Object.Locked
					and Theme.MutedText
					or Theme.SubText,

				TextSize = 12,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				TextTruncate =
					Enum.TextTruncate.AtEnd,

				ZIndex = 27,
			}
		)

	TitleLabel.Parent =
		Button

	Object.TitleLabel =
		TitleLabel

	--==============================================
	-- LOCK
	--==============================================

	if Object.Locked then
		local Lock =
			CreateIcon(
				"lock",
				13
			)

		Lock.AnchorPoint =
			Vector2.new(
				1,
				0.5
			)

		Lock.Position =
			UDim2.new(
				1,
				-12,
				0.5,
				0
			)

		Lock.ImageColor3 =
			Theme.MutedText

		Lock.ZIndex = 27

		Lock.Parent =
			Button

		Object.LockIcon =
			Lock
	end

	--==============================================
	-- PAGE
	--==============================================

	local Page =
		New(
			"ScrollingFrame",
			{
				Name =
					Object.Title
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
					Enum.AutomaticSize.None,

				ScrollBarThickness = 2,

				ScrollBarImageTransparency =
					0.7,

				Visible = false,

				ClipsDescendants = true,

				ZIndex = 12,
			}
		)

	Page.Parent =
		self.Content

	Object.Page =
		Page

	Object.Container =
		Page

	table.insert(
		self.Tabs,
		Object
	)

	--==============================================
	-- HOVER
	--==============================================

	if not Object.Locked then
		Button.MouseEnter:Connect(function()
			if Object.Selected then
				return
			end

			Tween(
				Button,
				0.16,
				{
					BackgroundColor3 =
						Theme.SurfaceHover,

					BackgroundTransparency =
						0.94,
				}
			)
		end)

		Button.MouseLeave:Connect(function()
			if Object.Selected then
				return
			end

			Tween(
				Button,
				0.16,
				{
					BackgroundTransparency =
						1,
				}
			)
		end)

		Button.MouseButton1Click:Connect(function()
			Object:Select()
		end)
	end

	if
		not self.SelectedTab
		and not Object.Locked
	then
		task.defer(function()
			if not self.SelectedTab then
				Object:Select()
			end
		end)
	end

	return Object
end

--==================================================
-- TAB SELECT
--==================================================

function Tab:Select()
	if self.Locked then
		return self
	end

	local WindowObject =
		self.Window

	for _, Object in ipairs(
		WindowObject.Tabs
	) do
		local Selected =
			Object == self

		Object.Selected =
			Selected

		Object.Page.Visible =
			Selected

		Tween(
			Object.Button,
			0.22,
			{
				BackgroundColor3 =
					WindowObject.SelectColor,

				BackgroundTransparency =
					Selected
					and WindowObject.SelectTransparency
					or 1,
			}
		)

		Tween(
			Object.Accent,
			0.22,
			{
				BackgroundColor3 =
					WindowObject.SelectColor,

				BackgroundTransparency =
					Selected
					and 0
					or 1,
			}
		)

		if Object.IconImage then
			Tween(
				Object.IconImage,
				0.22,
				{
					ImageColor3 =
						Selected
						and Theme.IconSelected
						or Theme.Icon,
				}
			)
		end

		Tween(
			Object.TitleLabel,
			0.22,
			{
				TextColor3 =
					Selected
					and Theme.Text
					or (
						Object.Locked
						and Theme.MutedText
						or Theme.SubText
					),
			}
		)
	end

	WindowObject.SelectedTab =
		self

	return self
end

--==================================================
-- SIDEBAR DIVIDER
--==================================================

function Tab:Divider()
	local WindowObject =
		self.Window

	WindowObject._SidebarOrder += 1

	local Holder =
		New(
			"Frame",
			{
				Size =
					UDim2.new(
						1,
						0,
						0,
						13
					),

				BackgroundTransparency = 1,

				LayoutOrder =
					WindowObject._SidebarOrder,

				ZIndex = 20,
			}
		)

	Holder.Parent =
		WindowObject.TabScroller

	local Line =
		New(
			"Frame",
			{
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
						-16,
						0,
						1
					),

				BackgroundColor3 =
					Theme.Stroke,

				BackgroundTransparency =
					0.91,

				BorderSizePixel = 0,
			}
		)

	Line.Parent =
		Holder

	return Holder
end

--==================================================
-- TAB LAYOUT API
--==================================================

function Tab:Layout(
	Config
)
	Config = Config or {}

	return CreateLayout(
		self.Page,
		Config
	)
end

function Tab:Free(
	Config
)
	Config = Config or {}

	Config.Type = "Free"

	return self:Layout(Config)
end

function Tab:Vertical(
	Config
)
	Config = Config or {}

	Config.Type = "Vertical"

	return self:Layout(Config)
end

function Tab:Horizontal(
	Config
)
	Config = Config or {}

	Config.Type = "Horizontal"

	return self:Layout(Config)
end

function Tab:Grid(
	Config
)
	Config = Config or {}

	Config.Type = "Grid"

	return self:Layout(Config)
end

--==================================================
-- WINDOW SETTERS
--==================================================

function Window:SetSelectColor(
	Color
)
	if typeof(Color) ~= "Color3" then
		return
	end

	self.SelectColor =
		Color

	for _, Object in ipairs(
		self.Tabs
	) do
		Object.Accent.BackgroundColor3 =
			Color

		if Object.Selected then
			Object.Button.BackgroundColor3 =
				Color
		end
	end
end

function Window:SetSelectTransparency(
	Value
)
	if typeof(Value) ~= "number" then
		return
	end

	self.SelectTransparency =
		math.clamp(
			Value,
			0,
			1
		)

	if self.SelectedTab then
		Tween(
			self.SelectedTab.Button,
			0.2,
			{
				BackgroundTransparency =
					self.SelectTransparency,
			}
		)
	end
end

function Window:SetBackgroundTransparency(
	Value
)
	if typeof(Value) ~= "number" then
		return
	end

	self.BackgroundTransparency =
		math.clamp(
			Value,
			0,
			1
		)

	Tween(
		self.Surface,
		0.25,
		{
			BackgroundTransparency =
				self.BackgroundTransparency,
		}
	)
end

function Window:SetSidebarTransparency(
	Value
)
	if typeof(Value) ~= "number" then
		return
	end

	self.SidebarTransparency =
		math.clamp(
			Value,
			0,
			1
		)

	Tween(
		self.SidebarGlass,
		0.25,
		{
			BackgroundTransparency =
				self.SidebarTransparency,
		}
	)
end

function Window:SetIcon(
	Icon
)
	self.Icon =
		Icon

	if self.IconImage then
		self.IconImage.Image =
			GetIcon(Icon)
	end
end

function Window:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

print(
	"[Pebble] Loaded v"
	.. Pebble.Version
)

return Pebble
