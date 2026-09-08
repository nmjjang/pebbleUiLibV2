--[[
	Pebble UI Library
	Version: 0.3.1
]]

local Pebble = {
	Version = "0.3.1"
}

--// Services

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// Lucide Icons

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

	Sidebar = Color3.fromRGB(16, 17, 19),
	SidebarHover = Color3.fromRGB(255, 255, 255),

	Accent = Color3.fromRGB(103, 76, 255),

	Icon = Color3.fromRGB(183, 184, 194),
	IconSelected = Color3.fromRGB(245, 245, 247),

	Tag = Color3.fromRGB(255, 255, 255),
	TagText = Color3.fromRGB(200, 201, 210),

	UserBackground = Color3.fromRGB(255, 255, 255),

	Close = Color3.fromRGB(235, 76, 76),
	CloseIcon = Color3.fromRGB(255, 185, 185),
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

	BackgroundTransparency = 0.28,

	SelectColor = Theme.Accent,
	SelectTransparency = 0.82,

	Draggable = true,
	Resizable = true,
}

--// Classes

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

--// Helpers

local function New(className, properties)
	local instance = Instance.new(className)

	for property, value in pairs(properties or {}) do
		instance[property] = value
	end

	return instance
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
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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
	return New("ImageLabel", {
		BackgroundTransparency = 1,

		Size = UDim2.fromOffset(
			size or 18,
			size or 18
		),

		Image = GetIcon(iconName) or "",

		ImageColor3 = Theme.Icon,

		ScaleType = Enum.ScaleType.Fit
	})
end

local function CreateControlButton(iconName, parent)
	local button = New("TextButton", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,

		Size = UDim2.fromOffset(32, 32),

		Text = "",

		AutoButtonColor = false,

		ZIndex = 30
	})

	Corner(button, 8)

	local icon = CreateIcon(iconName, 16)

	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)

	icon.ImageColor3 = Theme.Icon

	icon.ZIndex = 31

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

	self.TopbarHeight =
		config.TopbarHeight
		or Defaults.TopbarHeight

	self.SidebarWidth =
		config.SidebarWidth
		or Defaults.SidebarWidth

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

	-- Por padrão usa EXATAMENTE a mesma transparência do fundo.
	self.SidebarTransparency =
		config.SidebarTransparency ~= nil
		and math.clamp(config.SidebarTransparency, 0, 1)
		or self.BackgroundTransparency

	self.SelectColor =
		config.SelectColor
		or Defaults.SelectColor

	self.SelectTransparency =
		config.SelectTransparency ~= nil
		and math.clamp(config.SelectTransparency, 0, 1)
		or Defaults.SelectTransparency

	self.Draggable =
		config.Draggable ~= false

	self.Resizable =
		config.Resizable ~= false

	self.Tabs = {}

	self.SelectedTab = nil

	self.SidebarCollapsed = false

	self.Minimized = false
	self.Maximized = false

	self._SidebarOrder = 0

	--// ScreenGui

	local screenGui = New("ScreenGui", {
		Name = "PebbleUI_" .. tostring(
			math.random(100000, 999999)
		),

		IgnoreGuiInset = true,

		ResetOnSpawn = false,

		ZIndexBehavior =
			Enum.ZIndexBehavior.Sibling
	})

	local success = pcall(function()
		screenGui.Parent = CoreGui
	end)

	if not success then
		screenGui.Parent =
			LocalPlayer:WaitForChild("PlayerGui")
	end

	self.ScreenGui = screenGui

	--// Main

	local main = New("Frame", {
		Name = "Main",

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position =
			config.Position
			or Defaults.Position,

		Size = self.Size,

		BackgroundTransparency = 1,

		BorderSizePixel = 0
	})

	main.Parent = screenGui

	self.Main = main

	--[[
		CLIP ROOT

		Toda a Window visual fica dentro daqui.

		Isso impede Sidebar, Content e Topbar de
		desenharem fora dos cantos arredondados.
	]]

	local clipRoot = New("CanvasGroup", {
		Name = "ClipRoot",

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		GroupTransparency = 0,

		ClipsDescendants = true,

		ZIndex = 1
	})

	Corner(
		clipRoot,
		self.CornerRadius
	)

	clipRoot.Parent = main

	self.ClipRoot = clipRoot

	--// Background principal

	local surface = New("Frame", {
		Name = "Surface",

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 =
			Theme.Background,

		BackgroundTransparency =
			self.BackgroundTransparency,

		BorderSizePixel = 0,

		ZIndex = 1
	})

	surface.Parent = clipRoot

	self.Surface = surface

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

	--// Borda externa

	local outerStroke = Stroke(
		clipRoot,
		Theme.Stroke,
		0.87,
		1
	)

	self.OuterStroke = outerStroke

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

		ZIndex = 20
	})

	topbar.Parent = clipRoot

	self.Topbar = topbar

	--// App icon

	local appIcon = CreateIcon(
		self.Icon,
		20
	)

	appIcon.Name = "AppIcon"

	appIcon.AnchorPoint =
		Vector2.new(0, 0.5)

	appIcon.Position =
		UDim2.new(
			0,
			17,
			0.5,
			0
		)

	appIcon.ImageColor3 =
		Theme.Text

	appIcon.ZIndex = 22

	appIcon.Parent = topbar

	self.IconImage = appIcon

	--// Header

	local header = New("Frame", {
		Name = "Header",

		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				48,
				0
			),

		Size =
			UDim2.new(
				1,
				-250,
				1,
				0
			),

		ZIndex = 21
	})

	header.Parent = topbar

	local title = New("TextLabel", {
		Name = "Title",

		BackgroundTransparency = 1,

		AnchorPoint =
			Vector2.new(0, 0.5),

		Position =
			UDim2.new(
				0,
				0,
				0.5,
				-7
			),

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				20
			),

		Font =
			Enum.Font.GothamMedium,

		Text = self.Title,

		TextColor3 =
			Theme.Text,

		TextSize = 14,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 22
	})

	title.Parent = header

	local version = New("TextLabel", {
		Name = "Version",

		BackgroundTransparency = 1,

		AnchorPoint =
			Vector2.new(0, 0.5),

		Position =
			UDim2.new(
				0,
				0,
				0.5,
				11
			),

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				16
			),

		Font = Enum.Font.Gotham,

		Text = self.Version,

		TextColor3 =
			Theme.MutedText,

		TextSize = 10,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 22
	})

	version.Parent = header

	--// Tags

	local tagHolder = New("Frame", {
		Name = "Tags",

		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				115,
				18
			),

		Size =
			UDim2.new(
				1,
				-115,
				0,
				22
			),

		ZIndex = 22
	})

	tagHolder.Parent = header

	local tagLayout = New("UIListLayout", {
		FillDirection =
			Enum.FillDirection.Horizontal,

		Padding =
			UDim.new(0, 6),

		VerticalAlignment =
			Enum.VerticalAlignment.Center,

		SortOrder =
			Enum.SortOrder.LayoutOrder
	})

	tagLayout.Parent = tagHolder

	for index, tagText in ipairs(self.Tags) do
		local tag = New("TextLabel", {
			BackgroundColor3 =
				Theme.Tag,

			BackgroundTransparency =
				0.92,

			AutomaticSize =
				Enum.AutomaticSize.X,

			Size =
				UDim2.fromOffset(
					0,
					20
				),

			Font =
				Enum.Font.GothamMedium,

			Text =
				"  "
				.. tostring(tagText)
				.. "  ",

			TextColor3 =
				Theme.TagText,

			TextSize = 10,

			LayoutOrder = index,

			ZIndex = 23
		})

		Corner(tag, 6)

		tag.Parent = tagHolder
	end

	--// Controls

	local controls = New("Frame", {
		Name = "Controls",

		AnchorPoint =
			Vector2.new(1, 0.5),

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

		ZIndex = 30
	})

	controls.Parent = topbar

	local controlLayout = New("UIListLayout", {
		FillDirection =
			Enum.FillDirection.Horizontal,

		HorizontalAlignment =
			Enum.HorizontalAlignment.Right,

		VerticalAlignment =
			Enum.VerticalAlignment.Center,

		Padding =
			UDim.new(0, 4),

		SortOrder =
			Enum.SortOrder.LayoutOrder
	})

	controlLayout.Parent = controls

	local minimizeButton =
		CreateControlButton(
			"minus",
			controls
		)

	minimizeButton.LayoutOrder = 1

	local maximizeButton =
		CreateControlButton(
			"square",
			controls
		)

	maximizeButton.LayoutOrder = 2

	local closeButton, closeIcon =
		CreateControlButton(
			"x",
			controls
		)

	closeButton.LayoutOrder = 3

	closeButton.MouseEnter:Connect(function()
		Tween(
			closeButton,
			0.15,
			{
				BackgroundColor3 =
					Theme.Close,

				BackgroundTransparency =
					0.78
			}
		)

		Tween(
			closeIcon,
			0.15,
			{
				ImageColor3 =
					Theme.CloseIcon
			}
		)
	end)

	closeButton.MouseLeave:Connect(function()
		Tween(
			closeButton,
			0.15,
			{
				BackgroundTransparency = 1
			}
		)

		Tween(
			closeIcon,
			0.15,
			{
				ImageColor3 =
					Theme.Icon
			}
		)
	end)

	--// Sidebar

	local sidebar = New("Frame", {
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

		ZIndex = 10
	})

	sidebar.Parent = clipRoot

	self.Sidebar = sidebar

	--[[
		Sidebar Glass

		A própria Sidebar não desenha fundo.

		Esse frame interno usa a transparência configurada,
		mas continua preso ao ClipRoot arredondado.
	]]

	local sidebarGlass = New("Frame", {
		Name = "SidebarGlass",

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 =
			Theme.Sidebar,

		BackgroundTransparency =
			self.SidebarTransparency,

		BorderSizePixel = 0,

		ZIndex = 10
	})

	sidebarGlass.Parent = sidebar

	self.SidebarGlass = sidebarGlass

	-- leve gradiente na sidebar

	local sidebarGradient = New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(
				0,
				Color3.fromRGB(
					23,
					24,
					27
				)
			),

			ColorSequenceKeypoint.new(
				1,
				Color3.fromRGB(
					14,
					15,
					17
				)
			)
		}),

		Rotation = 90
	})

	sidebarGradient.Parent =
		sidebarGlass

	--// Linha vertical

	local sidebarLine = New("Frame", {
		Name = "SidebarLine",

		AnchorPoint =
			Vector2.new(1, 0),

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

		ZIndex = 14
	})

	sidebarLine.Parent = sidebar

	self.SidebarLine = sidebarLine

	--// Sidebar Toggle

	local sidebarToggle = New("TextButton", {
		Name = "SidebarToggle",

		AnchorPoint =
			Vector2.new(0.5, 0),

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
			Theme.BackgroundTop,

		BackgroundTransparency =
			0.12,

		BorderSizePixel = 0,

		Text = "",

		AutoButtonColor = false,

		ZIndex = 40
	})

	Corner(sidebarToggle, 8)

	Stroke(
		sidebarToggle,
		Theme.Stroke,
		0.86,
		1
	)

	sidebarToggle.Parent = sidebar

	local sidebarToggleIcon =
		CreateIcon(
			"panel-left-close",
			14
		)

	sidebarToggleIcon.AnchorPoint =
		Vector2.new(0.5, 0.5)

	sidebarToggleIcon.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	sidebarToggleIcon.ImageColor3 =
		Theme.Icon

	sidebarToggleIcon.ZIndex = 41

	sidebarToggleIcon.Parent =
		sidebarToggle

	self.SidebarToggle =
		sidebarToggle

	self.SidebarToggleIcon =
		sidebarToggleIcon

	sidebarToggle.MouseEnter:Connect(function()
		Tween(
			sidebarToggle,
			0.15,
			{
				BackgroundTransparency =
					0.02
			}
		)

		Tween(
			sidebarToggleIcon,
			0.15,
			{
				ImageColor3 =
					Theme.Text
			}
		)
	end)

	sidebarToggle.MouseLeave:Connect(function()
		Tween(
			sidebarToggle,
			0.15,
			{
				BackgroundTransparency =
					0.12
			}
		)

		Tween(
			sidebarToggleIcon,
			0.15,
			{
				ImageColor3 =
					Theme.Icon
			}
		)
	end)

	--// Tab Scroller

	local tabScroller = New("ScrollingFrame", {
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
			UDim2.fromOffset(0, 0),

		AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

		ScrollBarThickness = 0,

		ScrollingDirection =
			Enum.ScrollingDirection.Y,

		ClipsDescendants = true,

		ZIndex = 15
	})

	tabScroller.Parent = sidebar

	self.TabScroller = tabScroller

	local tabLayout = New("UIListLayout", {
		Padding = UDim.new(0, 4),

		SortOrder =
			Enum.SortOrder.LayoutOrder
	})

	tabLayout.Parent = tabScroller

	self.TabLayout = tabLayout

	--// User panel

	local userPanel = New("Frame", {
		Name = "UserPanel",

		AnchorPoint =
			Vector2.new(0, 1),

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

		ZIndex = 16
	})

	Corner(userPanel, 10)

	Stroke(
		userPanel,
		Theme.Stroke,
		0.94,
		1
	)

	userPanel.Parent = sidebar

	self.UserPanel = userPanel

	local avatar = New("ImageLabel", {
		Name = "Avatar",

		AnchorPoint =
			Vector2.new(0, 0.5),

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
			Theme.BackgroundTop,

		BackgroundTransparency = 0,

		BorderSizePixel = 0,

		Image = "",

		ZIndex = 17
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

		ZIndex = 17
	})

	displayName.Parent = userPanel

	local username = New("TextLabel", {
		Name = "Username",

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
			"@" .. LocalPlayer.Name,

		TextColor3 =
			Theme.SubText,

		TextSize = 10,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 17
	})

	username.Parent = userPanel

	self.DisplayNameLabel =
		displayName

	self.UsernameLabel =
		username

	--// Content

	local content = New("Frame", {
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

		ZIndex = 8
	})

	content.Parent = clipRoot

	self.Content = content

	--// Sidebar collapse

	function self:SetSidebarCollapsed(collapsed)
		self.SidebarCollapsed =
			collapsed == true

		local width =
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
						width,
						1,
						-self.TopbarHeight
					)
			}
		)

		Tween(
			self.Content,
			0.38,
			{
				Position =
					UDim2.fromOffset(
						width,
						self.TopbarHeight
					),

				Size =
					UDim2.new(
						1,
						-width,
						1,
						-self.TopbarHeight
					)
			}
		)

		self.SidebarToggleIcon.Image =
			GetIcon(
				self.SidebarCollapsed
				and "panel-left-open"
				or "panel-left-close"
			)
			or ""

		for _, tab in ipairs(self.Tabs) do
			if tab.TitleLabel then
				Tween(
					tab.TitleLabel,
					0.2,
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
					0.2,
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

		Tween(
			self.UserAvatar,
			0.36,
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
					)
			}
		)
	end

	sidebarToggle.MouseButton1Click:Connect(function()
		self:SetSidebarCollapsed(
			not self.SidebarCollapsed
		)
	end)

	--// Close

	closeButton.MouseButton1Click:Connect(function()
		Tween(
			main,
			0.18,
			{
				Size =
					UDim2.new(
						main.Size.X.Scale,
						main.Size.X.Offset - 18,

						main.Size.Y.Scale,
						main.Size.Y.Offset - 18
					)
			}
		)

		task.delay(0.18, function()
			screenGui:Destroy()
		end)
	end)

	--// Minimize

	local normalSize = main.Size

	minimizeButton.MouseButton1Click:Connect(function()
		self.Minimized =
			not self.Minimized

		if self.Minimized then
			normalSize = main.Size

			Tween(
				main,
				0.3,
				{
					Size =
						UDim2.new(
							normalSize.X.Scale,
							normalSize.X.Offset,
							0,
							self.TopbarHeight
						)
				}
			)
		else
			Tween(
				main,
				0.3,
				{
					Size = normalSize
				}
			)
		end
	end)

	--// Maximize

	local previousPosition =
		main.Position

	local previousSize =
		main.Size

	maximizeButton.MouseButton1Click:Connect(function()
		self.Maximized =
			not self.Maximized

		if self.Maximized then
			previousPosition =
				main.Position

			previousSize =
				main.Size

			main.AnchorPoint =
				Vector2.new(0, 0)

			Tween(
				main,
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
					Position =
						previousPosition,

					Size =
						previousSize
				}
			)
		end
	end)

	--// Drag

	if self.Draggable then
		local dragging = false

		local dragStart
		local startPosition

		topbar.InputBegan:Connect(function(input)
			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
				or input.UserInputType
					== Enum.UserInputType.Touch
			then
				dragging = true

				dragStart =
					input.Position

				startPosition =
					main.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end

			if
				input.UserInputType
					== Enum.UserInputType.MouseMovement
				or input.UserInputType
					== Enum.UserInputType.Touch
			then
				local delta =
					input.Position
					- dragStart

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
			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
				or input.UserInputType
					== Enum.UserInputType.Touch
			then
				dragging = false
			end
		end)
	end

	--// Resize

	if self.Resizable then
		local resizeButton = New("TextButton", {
			Name = "ResizeHandle",

			AnchorPoint =
				Vector2.new(1, 1),

			Position =
				UDim2.fromScale(1, 1),

			Size =
				UDim2.fromOffset(
					20,
					20
				),

			BackgroundTransparency = 1,

			Text = "",

			ZIndex = 100
		})

		resizeButton.Parent = main

		local resizing = false

		local resizeStart
		local startSize

		resizeButton.InputBegan:Connect(function(input)
			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
			then
				resizing = true

				resizeStart =
					input.Position

				startSize =
					main.AbsoluteSize
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if not resizing then
				return
			end

			if
				input.UserInputType
					== Enum.UserInputType.MouseMovement
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

				normalSize =
					main.Size
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
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

	local tab =
		setmetatable({}, Tab)

	tab.Window = self

	tab.Title =
		config.Title or "Tab"

	tab.Icon =
		config.Icon

	tab.Locked =
		config.Locked == true

	tab.Selected = false

	self._SidebarOrder += 1

	tab.LayoutOrder =
		self._SidebarOrder

	--// Button

	local button = New("TextButton", {
		Name = tab.Title,

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
			tab.LayoutOrder,

		ZIndex = 20
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

		ZIndex = 22
	})

	Corner(accent, 2)

	accent.Parent = button

	tab.Accent = accent

	--// Icon

	if tab.Icon then
		local icon =
			CreateIcon(
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

		icon.ZIndex = 22

		icon.Parent = button

		tab.IconImage = icon
	end

	--// Label

	local titleLabel = New("TextLabel", {
		Name = "Title",

		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				tab.Icon
					and 42
					or 14,

				0
			),

		Size =
			UDim2.new(
				1,
				tab.Locked
					and -74
					or -52,

				1,
				0
			),

		Font =
			Enum.Font.GothamMedium,

		Text =
			tab.Title,

		TextColor3 =
			tab.Locked
			and Theme.MutedText
			or Theme.SubText,

		TextSize = 12,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 22
	})

	titleLabel.Parent = button

	tab.TitleLabel =
		titleLabel

	--// Lock

	if tab.Locked then
		local lock =
			CreateIcon(
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

		lock.ZIndex = 22

		lock.Parent = button

		tab.LockIcon = lock
	end

	--// Page

	local page = New("ScrollingFrame", {
		Name =
			tab.Title .. "Page",

		Size =
			UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		CanvasSize =
			UDim2.fromOffset(0, 0),

		AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

		ScrollBarThickness = 3,

		ScrollBarImageTransparency = 0.65,

		Visible = false,

		ZIndex = 10
	})

	page.Parent =
		self.Content

	local padding = New("UIPadding", {
		PaddingTop =
			UDim.new(0, 18),

		PaddingBottom =
			UDim.new(0, 18),

		PaddingLeft =
			UDim.new(0, 20),

		PaddingRight =
			UDim.new(0, 20)
	})

	padding.Parent = page

	local layout = New("UIListLayout", {
		Padding =
			UDim.new(0, 10),

		SortOrder =
			Enum.SortOrder.LayoutOrder
	})

	layout.Parent = page

	tab.Page = page
	tab.Container = page
	tab.Layout = layout

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

	if
		not self.SelectedTab
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

	local window =
		self.Window

	for _, tab in ipairs(window.Tabs) do
		local selected =
			tab == self

		tab.Selected = selected

		tab.Page.Visible =
			selected

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

		Tween(
			tab.Accent,
			0.22,
			{
				BackgroundColor3 =
					window.SelectColor,

				BackgroundTransparency =
					selected
					and 0
					or 1,

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

	window.SelectedTab =
		self

	return self
end

function Tab:Divider()
	local window =
		self.Window

	window._SidebarOrder += 1

	local holder = New("Frame", {
		Name = "Divider",

		Size =
			UDim2.new(
				1,
				0,
				0,
				13
			),

		BackgroundTransparency = 1,

		LayoutOrder =
			window._SidebarOrder,

		ZIndex = 18
	})

	holder.Parent =
		window.TabScroller

	local line = New("Frame", {
		AnchorPoint =
			Vector2.new(0.5, 0.5),

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

		ZIndex = 19
	})

	line.Parent = holder

	return holder
end

--// Runtime setters

function Window:SetSelectColor(color)
	if typeof(color) ~= "Color3" then
		return
	end

	self.SelectColor = color

	for _, tab in ipairs(self.Tabs) do
		tab.Accent.BackgroundColor3 =
			color

		if tab.Selected then
			tab.Button.BackgroundColor3 =
				color
		end
	end
end

function Window:SetSelectTransparency(transparency)
	if typeof(transparency) ~= "number" then
		return
	end

	self.SelectTransparency =
		math.clamp(
			transparency,
			0,
			1
		)

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
		math.clamp(
			transparency,
			0,
			1
		)

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
		math.clamp(
			transparency,
			0,
			1
		)

	Tween(
		self.SidebarGlass,
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
