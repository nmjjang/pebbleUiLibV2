--[[
	Pebble UI
	Version: 0.3.0

	Features:
	- Window
	- Glass background
	- Custom background transparency
	- Custom selected tab color
	- Custom selected tab transparency
	- Collapsible sidebar
	- Sidebar toggle attached to sidebar edge
	- Tabs
	- Locked tabs
	- Dividers
	- Lucide icons
	- Player headshot / DisplayName / Username
	- Dragging
	- Resize
	- Minimize
	- Maximize
	- Close
]]

local Pebble = {
	Version = "0.3.0"
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// Lucide

local LucideIcons = {}

do
	local success, result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
		))()
	end)

	if success and typeof(result) == "table" then
		LucideIcons = result
	else
		warn("[Pebble] Failed to load Lucide icons:", result)
	end
end

local function GetIcon(name)
	if typeof(name) ~= "string" then
		return nil
	end

	if string.match(name, "^rbxassetid://") then
		return name
	end

	local icon = LucideIcons[name]

	if not icon then
		warn("[Pebble] Lucide icon not found:", name)
		return nil
	end

	return icon
end

--// Theme

local Theme = {
	Background = Color3.fromRGB(16, 17, 19),
	BackgroundTop = Color3.fromRGB(24, 25, 28),
	BackgroundBottom = Color3.fromRGB(13, 14, 16),

	Stroke = Color3.fromRGB(255, 255, 255),

	Text = Color3.fromRGB(244, 244, 247),
	SubText = Color3.fromRGB(146, 147, 157),
	MutedText = Color3.fromRGB(105, 106, 116),

	Sidebar = Color3.fromRGB(17, 18, 20),
	SidebarHover = Color3.fromRGB(255, 255, 255),
	SidebarSelected = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(103, 76, 255),
	AccentBright = Color3.fromRGB(124, 96, 255),

	Icon = Color3.fromRGB(183, 184, 194),
	IconSelected = Color3.fromRGB(245, 245, 247),

	Tag = Color3.fromRGB(255, 255, 255),
	TagText = Color3.fromRGB(200, 201, 210),

	UserBackground = Color3.fromRGB(255, 255, 255),

	Close = Color3.fromRGB(235, 76, 76),
	CloseIcon = Color3.fromRGB(255, 180, 180),
}

local Defaults = {
	Title = "Pebble",
	Version = "v0.3",
	Icon = "sparkles",
	Tags = {},

	Size = UDim2.fromOffset(760, 500),
	MinSize = Vector2.new(560, 360),
	MaxSize = Vector2.new(1200, 800),

	Position = UDim2.fromScale(0.5, 0.5),

	TopbarHeight = 56,

	SidebarWidth = 218,
	CollapsedSidebarWidth = 62,

	CornerRadius = 12,

	BackgroundTransparency = 0.12,
	SidebarTransparency = 0.16,

	SelectColor = Theme.Accent,
	SelectTransparency = 0.84,

	Draggable = true,
	Resizable = true,
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

--// Helpers

local function New(className, properties)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	return object
end

local function Corner(parent, radius)
	local corner = New("UICorner", {
		CornerRadius = UDim.new(0, radius)
	})

	corner.Parent = parent

	return corner
end

local function Stroke(parent, color, transparency, thickness)
	local stroke = New("UIStroke", {
		Color = color,
		Transparency = transparency or 0,
		Thickness = thickness or 1
	})

	stroke.Parent = parent

	return stroke
end

local function Tween(object, duration, properties)
	local tween = TweenService:Create(
		object,
		TweenInfo.new(
			duration or 0.2,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		properties
	)

	tween:Play()

	return tween
end

local function CreateIcon(iconName, size)
	local image = New("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size or 18, size or 18),

		Image = GetIcon(iconName) or "",
		ImageColor3 = Theme.Icon,

		ScaleType = Enum.ScaleType.Fit
	})

	return image
end

local function CreateControlButton(iconName, parent)
	local button = New("TextButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,

		Size = UDim2.fromOffset(32, 32),

		Text = "",
		AutoButtonColor = false,

		ZIndex = 20
	})

	Corner(button, 8)

	local icon = CreateIcon(iconName, 16)

	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.ImageColor3 = Theme.Icon
	icon.ZIndex = 21
	icon.Parent = button

	button.MouseEnter:Connect(function()
		Tween(button, 0.15, {
			BackgroundTransparency = 0.92
		})
	end)

	button.MouseLeave:Connect(function()
		Tween(button, 0.15, {
			BackgroundTransparency = 1
		})
	end)

	button.Parent = parent

	return button, icon
end

--// Window

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
	self.CollapsedSidebarWidth =
		config.CollapsedSidebarWidth
		or Defaults.CollapsedSidebarWidth

	self.CornerRadius =
		config.CornerRadius
		or Defaults.CornerRadius

	self.BackgroundTransparency =
		config.BackgroundTransparency ~= nil
		and math.clamp(config.BackgroundTransparency, 0, 1)
		or Defaults.BackgroundTransparency

	self.SidebarTransparency =
		config.SidebarTransparency ~= nil
		and math.clamp(config.SidebarTransparency, 0, 1)
		or Defaults.SidebarTransparency

	self.SelectColor =
		config.SelectColor
		or Defaults.SelectColor

	self.SelectTransparency =
		config.SelectTransparency ~= nil
		and math.clamp(config.SelectTransparency, 0, 1)
		or Defaults.SelectTransparency

	self.Draggable =
		config.Draggable ~= false
		and Defaults.Draggable

	self.Resizable =
		config.Resizable ~= false
		and Defaults.Resizable

	self.Tabs = {}
	self.SelectedTab = nil

	self.SidebarCollapsed = false
	self.Minimized = false
	self.Maximized = false

	self._SidebarOrder = 0

	--// ScreenGui

	local screenGui = New("ScreenGui", {
		Name = "PebbleUI_" .. tostring(math.random(100000, 999999)),
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	})

	local success = pcall(function()
		screenGui.Parent = CoreGui
	end)

	if not success then
		screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	self.ScreenGui = screenGui

	--// Main

	local main = New("Frame", {
		Name = "Main",

		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or Defaults.Position,
		Size = self.Size,

		BackgroundTransparency = 1,

		BorderSizePixel = 0
	})

	main.Parent = screenGui

	self.Main = main

	--// Main Surface

	local surface = New("Frame", {
		Name = "Surface",

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = self.BackgroundTransparency,

		BorderSizePixel = 0,

		ZIndex = 1
	})

	Corner(surface, self.CornerRadius)

	Stroke(
		surface,
		Theme.Stroke,
		0.90,
		1
	)

	local gradient = New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				Theme.BackgroundTop
			),

			ColorSequenceKeypoint.new(
				1,
				Theme.BackgroundBottom
			)
		}),

		Rotation = 90
	})

	gradient.Parent = surface
	surface.Parent = main

	self.Surface = surface

	--// Topbar

	local topbar = New("Frame", {
		Name = "Topbar",

		Size = UDim2.new(
			1,
			0,
			0,
			self.TopbarHeight
		),

		BackgroundTransparency = 1,

		ZIndex = 10
	})

	topbar.Parent = main
	self.Topbar = topbar

	--// App icon

	local appIcon = CreateIcon(self.Icon, 20)

	appIcon.Name = "AppIcon"

	appIcon.AnchorPoint = Vector2.new(0, 0.5)

	appIcon.Position = UDim2.new(
		0,
		17,
		0.5,
		0
	)

	appIcon.ImageColor3 = Theme.Text

	appIcon.ZIndex = 13

	appIcon.Parent = topbar

	self.IconImage = appIcon

	--// Header

	local header = New("Frame", {
		Name = "Header",

		BackgroundTransparency = 1,

		Position = UDim2.fromOffset(48, 0),

		Size = UDim2.new(
			1,
			-250,
			1,
			0
		),

		ZIndex = 12
	})

	header.Parent = topbar

	local title = New("TextLabel", {
		Name = "Title",

		BackgroundTransparency = 1,

		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.new(
			0,
			0,
			0.5,
			-7
		),

		Size = UDim2.new(
			0,
			0,
			0,
			20
		),

		AutomaticSize = Enum.AutomaticSize.X,

		Font = Enum.Font.GothamMedium,

		Text = self.Title,
		TextColor3 = Theme.Text,
		TextSize = 14,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 13
	})

	title.Parent = header

	local version = New("TextLabel", {
		Name = "Version",

		BackgroundTransparency = 1,

		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.new(
			0,
			0,
			0.5,
			11
		),

		Size = UDim2.new(
			0,
			0,
			0,
			16
		),

		AutomaticSize = Enum.AutomaticSize.X,

		Font = Enum.Font.Gotham,

		Text = self.Version,
		TextColor3 = Theme.MutedText,
		TextSize = 11,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 13
	})

	version.Parent = header

	--// Tags

	local tagHolder = New("Frame", {
		Name = "Tags",

		BackgroundTransparency = 1,

		Position = UDim2.fromOffset(115, 18),

		Size = UDim2.new(
			1,
			-115,
			0,
			22
		),

		ZIndex = 13
	})

	tagHolder.Parent = header

	local tagLayout = New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,

		Padding = UDim.new(0, 6),

		VerticalAlignment = Enum.VerticalAlignment.Center,

		SortOrder = Enum.SortOrder.LayoutOrder
	})

	tagLayout.Parent = tagHolder

	for index, tagText in ipairs(self.Tags) do
		local tag = New("TextLabel", {
			BackgroundColor3 = Theme.Tag,
			BackgroundTransparency = 0.92,

			AutomaticSize = Enum.AutomaticSize.X,

			Size = UDim2.fromOffset(0, 20),

			Font = Enum.Font.GothamMedium,

			Text = "  " .. tostring(tagText) .. "  ",
			TextColor3 = Theme.TagText,
			TextSize = 10,

			LayoutOrder = index,

			ZIndex = 14
		})

		Corner(tag, 6)

		tag.Parent = tagHolder
	end

	--// Window controls

	local controls = New("Frame", {
		Name = "Controls",

		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(
			1,
			-12,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			104,
			32
		),

		BackgroundTransparency = 1,

		ZIndex = 20
	})

	controls.Parent = topbar

	local controlLayout = New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,

		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,

		Padding = UDim.new(0, 4),

		SortOrder = Enum.SortOrder.LayoutOrder
	})

	controlLayout.Parent = controls

	local minimizeButton, minimizeIcon =
		CreateControlButton("minus", controls)

	minimizeButton.LayoutOrder = 1

	local maximizeButton, maximizeIcon =
		CreateControlButton("square", controls)

	maximizeButton.LayoutOrder = 2

	local closeButton, closeIcon =
		CreateControlButton("x", controls)

	closeButton.LayoutOrder = 3

	closeButton.MouseEnter:Connect(function()
		Tween(closeButton, 0.15, {
			BackgroundColor3 = Theme.Close,
			BackgroundTransparency = 0.78
		})

		Tween(closeIcon, 0.15, {
			ImageColor3 = Theme.CloseIcon
		})
	end)

	closeButton.MouseLeave:Connect(function()
		Tween(closeButton, 0.15, {
			BackgroundTransparency = 1
		})

		Tween(closeIcon, 0.15, {
			ImageColor3 = Theme.Icon
		})
	end)

	--// Sidebar

	local sidebar = New("Frame", {
		Name = "Sidebar",

		Position = UDim2.fromOffset(
			0,
			self.TopbarHeight
		),

		Size = UDim2.new(
			0,
			self.SidebarWidth,
			1,
			-self.TopbarHeight
		),

		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = self.SidebarTransparency,

		BorderSizePixel = 0,

		ClipsDescendants = false,

		ZIndex = 5
	})

	sidebar.Parent = main
	self.Sidebar = sidebar

	--// Sidebar right border

	local sidebarLine = New("Frame", {
		Name = "SidebarLine",

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(
			1,
			0,
			0,
			0
		),

		Size = UDim2.new(
			0,
			1,
			1,
			0
		),

		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.93,

		BorderSizePixel = 0,

		ZIndex = 6
	})

	sidebarLine.Parent = sidebar

	--// Sidebar Toggle
	--// IMPORTANT: child of sidebar, so it follows it automatically

	local sidebarButton = New("TextButton", {
		Name = "SidebarToggle",

		AnchorPoint = Vector2.new(0.5, 0),

		Position = UDim2.new(
			1,
			0,
			0,
			10
		),

		Size = UDim2.fromOffset(
			28,
			28
		),

		BackgroundColor3 = Theme.BackgroundTop,
		BackgroundTransparency = 0.08,

		BorderSizePixel = 0,

		Text = "",

		AutoButtonColor = false,

		ZIndex = 40
	})

	Corner(sidebarButton, 8)

	Stroke(
		sidebarButton,
		Theme.Stroke,
		0.88,
		1
	)

	sidebarButton.Parent = sidebar

	local sidebarButtonIcon =
		CreateIcon("panel-left-close", 14)

	sidebarButtonIcon.AnchorPoint =
		Vector2.new(0.5, 0.5)

	sidebarButtonIcon.Position =
		UDim2.fromScale(0.5, 0.5)

	sidebarButtonIcon.ImageColor3 =
		Theme.Icon

	sidebarButtonIcon.ZIndex = 41

	sidebarButtonIcon.Parent =
		sidebarButton

	self.SidebarButton = sidebarButton
	self.SidebarButtonIcon = sidebarButtonIcon

	sidebarButton.MouseEnter:Connect(function()
		Tween(sidebarButton, 0.15, {
			BackgroundTransparency = 0
		})

		Tween(sidebarButtonIcon, 0.15, {
			ImageColor3 = Theme.Text
		})
	end)

	sidebarButton.MouseLeave:Connect(function()
		Tween(sidebarButton, 0.15, {
			BackgroundTransparency = 0.08
		})

		Tween(sidebarButtonIcon, 0.15, {
			ImageColor3 = Theme.Icon
		})
	end)

	--// Tab Scroller

	local tabScroller = New("ScrollingFrame", {
		Name = "Tabs",

		Position = UDim2.fromOffset(
			8,
			8
		),

		Size = UDim2.new(
			1,
			-16,
			1,
			-88
		),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		CanvasSize = UDim2.fromOffset(0, 0),

		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollBarThickness = 0,

		ScrollingDirection = Enum.ScrollingDirection.Y,

		ClipsDescendants = true,

		ZIndex = 7
	})

	tabScroller.Parent = sidebar
	self.TabScroller = tabScroller

	local tabLayout = New("UIListLayout", {
		Padding = UDim.new(0, 4),

		SortOrder = Enum.SortOrder.LayoutOrder
	})

	tabLayout.Parent = tabScroller

	self.TabLayout = tabLayout

	--// Player panel

	local userPanel = New("Frame", {
		Name = "UserPanel",

		AnchorPoint = Vector2.new(0, 1),

		Position = UDim2.new(
			0,
			8,
			1,
			-8
		),

		Size = UDim2.new(
			1,
			-16,
			0,
			64
		),

		BackgroundColor3 =
			Theme.UserBackground,

		BackgroundTransparency = 0.94,

		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 8
	})

	Corner(userPanel, 10)

	userPanel.Parent = sidebar

	self.UserPanel = userPanel

	local avatar = New("ImageLabel", {
		Name = "Avatar",

		AnchorPoint = Vector2.new(
			0,
			0.5
		),

		Position = UDim2.new(
			0,
			11,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			38,
			38
		),

		BackgroundColor3 =
			Theme.BackgroundTop,

		BackgroundTransparency = 0,

		BorderSizePixel = 0,

		Image = "",

		ZIndex = 9
	})

	Corner(avatar, 19)

	avatar.Parent = userPanel
	self.UserAvatar = avatar

	task.spawn(function()
		local successThumb, thumbnail =
			pcall(function()
				return Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)
			end)

		if successThumb then
			avatar.Image = thumbnail
		end
	end)

	local displayName = New("TextLabel", {
		Name = "DisplayName",

		BackgroundTransparency = 1,

		Position = UDim2.fromOffset(
			59,
			13
		),

		Size = UDim2.new(
			1,
			-70,
			0,
			18
		),

		Font = Enum.Font.GothamMedium,

		Text = LocalPlayer.DisplayName,
		TextColor3 = Theme.Text,
		TextSize = 12,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 9
	})

	displayName.Parent = userPanel

	local username = New("TextLabel", {
		Name = "Username",

		BackgroundTransparency = 1,

		Position = UDim2.fromOffset(
			59,
			33
		),

		Size = UDim2.new(
			1,
			-70,
			0,
			16
		),

		Font = Enum.Font.Gotham,

		Text = "@" .. LocalPlayer.Name,
		TextColor3 = Theme.SubText,
		TextSize = 10,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 9
	})

	username.Parent = userPanel

	self.DisplayNameLabel = displayName
	self.UsernameLabel = username

	--// Content

	local content = New("Frame", {
		Name = "Content",

		Position = UDim2.fromOffset(
			self.SidebarWidth,
			self.TopbarHeight
		),

		Size = UDim2.new(
			1,
			-self.SidebarWidth,
			1,
			-self.TopbarHeight
		),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 4
	})

	content.Parent = main
	self.Content = content

	--// Sidebar animation

	function self:SetSidebarCollapsed(collapsed)
		self.SidebarCollapsed = collapsed == true

		local targetWidth =
			self.SidebarCollapsed
			and self.CollapsedSidebarWidth
			or self.SidebarWidth

		Tween(
			self.Sidebar,
			0.38,
			{
				Size = UDim2.new(
					0,
					targetWidth,
					1,
					-self.TopbarHeight
				)
			}
		)

		Tween(
			self.Content,
			0.38,
			{
				Position = UDim2.fromOffset(
					targetWidth,
					self.TopbarHeight
				),

				Size = UDim2.new(
					1,
					-targetWidth,
					1,
					-self.TopbarHeight
				)
			}
		)

		self.SidebarButtonIcon.Image =
			GetIcon(
				self.SidebarCollapsed
				and "panel-left-open"
				or "panel-left-close"
			) or ""

		for _, tab in ipairs(self.Tabs) do
			if tab.TitleLabel then
				Tween(
					tab.TitleLabel,
					0.22,
					{
						TextTransparency =
							self.SidebarCollapsed
							and 1
							or 0
					}
				)
			end

			if tab.LockIcon then
				Tween(
					tab.LockIcon,
					0.22,
					{
						ImageTransparency =
							self.SidebarCollapsed
							and 1
							or 0
					}
				)
			end
		end

		Tween(
			self.DisplayNameLabel,
			0.2,
			{
				TextTransparency =
					self.SidebarCollapsed
					and 1
					or 0
			}
		)

		Tween(
			self.UsernameLabel,
			0.2,
			{
				TextTransparency =
					self.SidebarCollapsed
					and 1
					or 0
			}
		)

		if self.SidebarCollapsed then
			Tween(
				self.UserAvatar,
				0.38,
				{
					Position = UDim2.new(
						0.5,
						-19,
						0.5,
						0
					)
				}
			)
		else
			Tween(
				self.UserAvatar,
				0.38,
				{
					Position = UDim2.new(
						0,
						11,
						0.5,
						0
					)
				}
			)
		end
	end

	sidebarButton.MouseButton1Click:Connect(function()
		self:SetSidebarCollapsed(
			not self.SidebarCollapsed
		)
	end)

	--// Minimize

	local normalSize = self.Size

	minimizeButton.MouseButton1Click:Connect(function()
		self.Minimized = not self.Minimized

		if self.Minimized then
			Tween(
				main,
				0.32,
				{
					Size = UDim2.new(
						normalSize.X.Scale,
						normalSize.X.Offset,
						0,
						self.TopbarHeight
					)
				}
			)

			sidebar.Visible = false
			content.Visible = false
		else
			sidebar.Visible = true
			content.Visible = true

			Tween(
				main,
				0.32,
				{
					Size = normalSize
				}
			)
		end
	end)

	--// Maximize

	local previousPosition = main.Position
	local previousSize = main.Size

	maximizeButton.MouseButton1Click:Connect(function()
		self.Maximized = not self.Maximized

		if self.Maximized then
			previousPosition = main.Position
			previousSize = main.Size

			main.AnchorPoint = Vector2.new(0, 0)

			Tween(
				main,
				0.35,
				{
					Position =
						UDim2.fromOffset(12, 12),

					Size =
						UDim2.new(
							1,
							-24,
							1,
							-24
						)
				}
			)
		else
			main.AnchorPoint =
				Vector2.new(0.5, 0.5)

			Tween(
				main,
				0.35,
				{
					Position = previousPosition,
					Size = previousSize
				}
			)
		end
	end)

	--// Close

	closeButton.MouseButton1Click:Connect(function()
		Tween(
			main,
			0.18,
			{
				Size = UDim2.new(
					main.Size.X.Scale,
					main.Size.X.Offset - 20,
					main.Size.Y.Scale,
					main.Size.Y.Offset - 20
				)
			}
		)

		task.delay(0.18, function()
			screenGui:Destroy()
		end)
	end)

	--// Dragging

	if self.Draggable then
		local dragging = false
		local dragStart = nil
		local startPosition = nil

		topbar.InputBegan:Connect(function(input)
			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
				or input.UserInputType ==
				Enum.UserInputType.Touch
			then
				dragging = true

				dragStart = input.Position
				startPosition = main.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end

			if input.UserInputType ==
				Enum.UserInputType.MouseMovement
				or input.UserInputType ==
				Enum.UserInputType.Touch
			then
				local delta =
					input.Position - dragStart

				main.Position =
					UDim2.new(
						startPosition.X.Scale,
						startPosition.X.Offset
							+ delta.X,

						startPosition.Y.Scale,
						startPosition.Y.Offset
							+ delta.Y
					)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
				or input.UserInputType ==
				Enum.UserInputType.Touch
			then
				dragging = false
			end
		end)
	end

	--// Resize

	if self.Resizable then
		local resizeHandle = New("Frame", {
			Name = "ResizeHandle",

			AnchorPoint =
				Vector2.new(1, 1),

			Position =
				UDim2.fromScale(1, 1),

			Size =
				UDim2.fromOffset(18, 18),

			BackgroundTransparency = 1,

			ZIndex = 50
		})

		resizeHandle.Parent = main

		local resizeButton = New("TextButton", {
			BackgroundTransparency = 1,

			Size = UDim2.fromScale(1, 1),

			Text = "",

			ZIndex = 51
		})

		resizeButton.Parent = resizeHandle

		local resizing = false
		local resizeStart = nil
		local startSize = nil

		resizeButton.InputBegan:Connect(function(input)
			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
			then
				resizing = true
				resizeStart = input.Position
				startSize =
					main.AbsoluteSize
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not resizing then
				return
			end

			if input.UserInputType ==
				Enum.UserInputType.MouseMovement
			then
				local delta =
					input.Position
					- resizeStart

				local width =
					math.clamp(
						startSize.X + delta.X,
						self.MinSize.X,
						self.MaxSize.X
					)

				local height =
					math.clamp(
						startSize.Y + delta.Y,
						self.MinSize.Y,
						self.MaxSize.Y
					)

				main.Size =
					UDim2.fromOffset(
						width,
						height
					)

				normalSize = main.Size
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
			then
				resizing = false
			end
		end)
	end

	return self
end

--// Tabs

function Window:Tab(config)
	config = config or {}

	local tab = setmetatable({}, Tab)

	tab.Window = self

	tab.Title =
		config.Title
		or "Tab"

	tab.Icon = config.Icon

	tab.Locked =
		config.Locked == true

	tab.Selected = false

	-- Correct sequential sidebar ordering

	self._SidebarOrder += 1

	tab.LayoutOrder =
		self._SidebarOrder

	--// Sidebar button

	local button = New("TextButton", {
		Name = tab.Title,

		Size = UDim2.new(
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
			tab.LayoutOrder,

		ZIndex = 10
	})

	Corner(button, 9)

	button.Parent =
		self.TabScroller

	tab.Button = button

	--// Accent

	local accent = New("Frame", {
		Name = "Accent",

		AnchorPoint =
			Vector2.new(0, 0.5),

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

		ZIndex = 12
	})

	Corner(accent, 2)

	accent.Parent = button

	tab.Accent = accent

	--// Icon

	if tab.Icon then
		local icon = CreateIcon(
			tab.Icon,
			17
		)

		icon.AnchorPoint =
			Vector2.new(0, 0.5)

		icon.Position =
			UDim2.new(
				0,
				13,
				0.5,
				0
			)

		icon.ImageColor3 =
			Theme.Icon

		icon.ZIndex = 12

		icon.Parent = button

		tab.IconImage = icon
	end

	--// Title

	local titleLabel = New("TextLabel", {
		Name = "Title",

		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				tab.Icon and 42 or 14,
				0
			),

		Size =
			UDim2.new(
				1,
				tab.Locked and -74 or -52,
				1,
				0
			),

		Font = Enum.Font.GothamMedium,

		Text = tab.Title,

		TextColor3 =
			tab.Locked
			and Theme.MutedText
			or Theme.SubText,

		TextSize = 12,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 12
	})

	titleLabel.Parent = button

	tab.TitleLabel = titleLabel

	--// Lock

	if tab.Locked then
		local lock = CreateIcon(
			"lock",
			13
		)

		lock.AnchorPoint =
			Vector2.new(1, 0.5)

		lock.Position =
			UDim2.new(
				1,
				-12,
				0.5,
				0
			)

		lock.ImageColor3 =
			Theme.MutedText

		lock.ZIndex = 12

		lock.Parent = button

		tab.LockIcon = lock
	end

	--// Page

	local page = New("ScrollingFrame", {
		Name = tab.Title .. "Page",

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		CanvasSize =
			UDim2.fromOffset(0, 0),

		AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

		ScrollBarThickness = 3,

		ScrollBarImageTransparency = 0.65,

		Visible = false,

		ZIndex = 5
	})

	page.Parent = self.Content

	local pagePadding = New("UIPadding", {
		PaddingTop = UDim.new(0, 18),

		PaddingBottom =
			UDim.new(0, 18),

		PaddingLeft =
			UDim.new(0, 20),

		PaddingRight =
			UDim.new(0, 20)
	})

	pagePadding.Parent = page

	local pageLayout = New("UIListLayout", {
		Padding = UDim.new(0, 10),

		SortOrder =
			Enum.SortOrder.LayoutOrder
	})

	pageLayout.Parent = page

	tab.Page = page
	tab.Container = page
	tab.Layout = pageLayout

	table.insert(
		self.Tabs,
		tab
	)

	--// Hover

	if not tab.Locked then
		button.MouseEnter:Connect(function()
			if tab.Selected then
				return
			end

			Tween(
				button,
				0.16,
				{
					BackgroundColor3 =
						Theme.SidebarHover,

					BackgroundTransparency =
						0.96
				}
			)
		end)

		button.MouseLeave:Connect(function()
			if tab.Selected then
				return
			end

			Tween(
				button,
				0.16,
				{
					BackgroundTransparency = 1
				}
			)
		end)

		button.MouseButton1Click:Connect(function()
			tab:Select()
		end)
	end

	-- Auto select first unlocked tab

	if not self.SelectedTab
		and not tab.Locked
	then
		task.defer(function()
			if not self.SelectedTab then
				tab:Select()
			end
		end)
	end

	return tab
end

function Tab:Select()
	if self.Locked then
		return self
	end

	local window = self.Window

	for _, tab in ipairs(window.Tabs) do
		local selected =
			tab == self

		tab.Selected = selected
		tab.Page.Visible = selected

		Tween(
			tab.Button,
			0.22,
			{
				BackgroundColor3 =
					window.SelectColor,

				BackgroundTransparency =
					selected
					and window.SelectTransparency
					or 1
			}
		)

		if tab.Accent then
			tab.Accent.BackgroundColor3 =
				window.SelectColor

			Tween(
				tab.Accent,
				0.22,
				{
					BackgroundTransparency =
						selected and 0 or 1,

					Size =
						selected
						and UDim2.fromOffset(
							3,
							20
						)
						or UDim2.fromOffset(
							3,
							8
						)
				}
			)
		end

		if tab.IconImage then
			Tween(
				tab.IconImage,
				0.22,
				{
					ImageColor3 =
						selected
						and Theme.IconSelected
						or Theme.Icon
				}
			)
		end

		if tab.TitleLabel then
			Tween(
				tab.TitleLabel,
				0.22,
				{
					TextColor3 =
						selected
						and Theme.Text
						or (
							tab.Locked
							and Theme.MutedText
							or Theme.SubText
						)
				}
			)
		end
	end

	window.SelectedTab = self

	return self
end

function Tab:Divider()
	local window = self.Window

	window._SidebarOrder += 1

	local holder = New("Frame", {
		Name = "Divider",

		Size = UDim2.new(
			1,
			0,
			0,
			13
		),

		BackgroundTransparency = 1,

		LayoutOrder =
			window._SidebarOrder,

		ZIndex = 8
	})

	holder.Parent =
		window.TabScroller

	local line = New("Frame", {
		AnchorPoint =
			Vector2.new(0.5, 0.5),

		Position =
			UDim2.fromScale(0.5, 0.5),

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

		ZIndex = 9
	})

	line.Parent = holder

	return holder
end

--// Window setters

function Window:SetSelectColor(color)
	if typeof(color) ~= "Color3" then
		return
	end

	self.SelectColor = color

	for _, tab in ipairs(self.Tabs) do
		tab.Accent.BackgroundColor3 = color

		if tab.Selected then
			tab.Button.BackgroundColor3 = color
		end
	end
end

function Window:SetSelectTransparency(transparency)
	if typeof(transparency) ~= "number" then
		return
	end

	self.SelectTransparency =
		math.clamp(transparency, 0, 1)

	if self.SelectedTab then
		Tween(
			self.SelectedTab.Button,
			0.2,
			{
				BackgroundTransparency =
					self.SelectTransparency
			}
		)
	end
end

function Window:SetBackgroundTransparency(transparency)
	if typeof(transparency) ~= "number" then
		return
	end

	self.BackgroundTransparency =
		math.clamp(transparency, 0, 1)

	Tween(
		self.Surface,
		0.25,
		{
			BackgroundTransparency =
				self.BackgroundTransparency
		}
	)
end

function Window:SetSidebarTransparency(transparency)
	if typeof(transparency) ~= "number" then
		return
	end

	self.SidebarTransparency =
		math.clamp(transparency, 0, 1)

	Tween(
		self.Sidebar,
		0.25,
		{
			BackgroundTransparency =
				self.SidebarTransparency
		}
	)
end

function Window:SetIcon(icon)
	self.Icon = icon

	if self.IconImage then
		self.IconImage.Image =
			GetIcon(icon) or ""
	end
end

function Window:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

return Pebble
