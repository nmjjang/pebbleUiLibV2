--[[
	Pebble UI Library
	Window Base v0.1.5

	Changes:
	- No separator line
	- No icon holder/background
	- Topbar fully transparent
	- Rounded glass surface
	- Lucide controls
	- Drag
	- Resize
	- Minimize
	- Maximize
	- Close
]]

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- LIBRARY
------------------------------------------------------------

local Pebble = {}
Pebble.Version = "0.1.5"

------------------------------------------------------------
-- THEME
------------------------------------------------------------

local Theme = {
	Background = Color3.fromRGB(16, 17, 19),

	BackgroundTop = Color3.fromRGB(25, 26, 29),
	BackgroundBottom = Color3.fromRGB(14, 15, 17),

	Text = Color3.fromRGB(245, 245, 247),
	SubText = Color3.fromRGB(155, 156, 165),

	Icon = Color3.fromRGB(215, 216, 222),

	Stroke = Color3.fromRGB(255, 255, 255),

	Hover = Color3.fromRGB(255, 255, 255),

	Close = Color3.fromRGB(235, 76, 76),
	CloseIcon = Color3.fromRGB(255, 180, 180),

	Tag = Color3.fromRGB(255, 255, 255),
	TagText = Color3.fromRGB(205, 206, 214),
}

------------------------------------------------------------
-- DEFAULTS
------------------------------------------------------------

local Defaults = {
	Title = "Pebble",
	Version = "v0.1",

	Icon = "gem",

	Tags = {},

	Size = UDim2.fromOffset(680, 450),

	MinSize = Vector2.new(440, 300),
	MaxSize = Vector2.new(1100, 760),

	Position = UDim2.fromScale(0.5, 0.5),

	TopbarHeight = 54,

	CornerRadius = 12,

	Draggable = true,
	Resizable = true,
}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function New(className, properties, children)
	local object = Instance.new(className)

	if properties then
		for property, value in pairs(properties) do
			object[property] = value
		end
	end

	if children then
		for _, child in ipairs(children) do
			child.Parent = object
		end
	end

	return object
end

local function Tween(object, duration, properties)
	local tween = TweenService:Create(
		object,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		properties
	)

	tween:Play()

	return tween
end

local function AddConnection(window, connection)
	table.insert(window._Connections, connection)
	return connection
end

------------------------------------------------------------
-- GUI PARENT
------------------------------------------------------------

local function GetGuiParent()
	if typeof(gethui) == "function" then
		local success, result = pcall(gethui)

		if success and result then
			return result
		end
	end

	local success = pcall(function()
		return CoreGui.Name
	end)

	if success then
		return CoreGui
	end

	if LocalPlayer then
		return LocalPlayer:WaitForChild("PlayerGui")
	end

	return nil
end

------------------------------------------------------------
-- LUCIDE
------------------------------------------------------------

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
		warn("[Pebble] Failed to load Lucide:", result)
	end
end

------------------------------------------------------------
-- ICON API
------------------------------------------------------------

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

local function CreateIcon(name, size)
	return New("ImageLabel", {
		Name = "Icon",

		Size = UDim2.fromOffset(
			size or 18,
			size or 18
		),

		BackgroundTransparency = 1,

		Image = GetIcon(name) or "",

		ImageColor3 = Theme.Icon,
		ImageTransparency = 0,

		ScaleType = Enum.ScaleType.Fit,
	})
end

------------------------------------------------------------
-- WINDOW CLASS
------------------------------------------------------------

local Window = {}
Window.__index = Window

------------------------------------------------------------
-- TAG
------------------------------------------------------------

local function CreateTag(window, data)
	local text

	if typeof(data) == "table" then
		text = data.Text or data.Name or "Tag"
	else
		text = tostring(data)
	end

	return New("Frame", {
		Name = "Tag",

		AutomaticSize = Enum.AutomaticSize.X,

		Size = UDim2.fromOffset(0, 22),

		BackgroundColor3 = Theme.Tag,
		BackgroundTransparency = 0.92,

		BorderSizePixel = 0,

		Parent = window.TagContainer,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),

		New("UIStroke", {
			Color = Theme.Stroke,
			Transparency = 0.90,
			Thickness = 1,
		}),

		New("UIPadding", {
			PaddingLeft = UDim.new(0, 7),
			PaddingRight = UDim.new(0, 7),
		}),

		New("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,

			Size = UDim2.new(0, 0, 1, 0),

			BackgroundTransparency = 1,

			Text = text,

			TextColor3 = Theme.TagText,
			TextTransparency = 0,

			TextSize = 11,

			Font = Enum.Font.GothamMedium,
		}),
	})
end

------------------------------------------------------------
-- CONTROL BUTTON
------------------------------------------------------------

local function CreateControlButton(
	window,
	name,
	iconName,
	isClose
)

	local button = New("ImageButton", {
		Name = name,

		Size = UDim2.fromOffset(30, 30),

		BackgroundColor3 =
			isClose
			and Theme.Close
			or Theme.Hover,

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Image = "",

		ZIndex = 20,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
	})

	local icon = CreateIcon(iconName, 16)

	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)

	icon.ImageColor3 = Theme.SubText

	icon.ZIndex = 21
	icon.Parent = button

	AddConnection(
		window,
		button.MouseEnter:Connect(function()
			Tween(
				button,
				0.15,
				{
					BackgroundTransparency =
						isClose and 0.80 or 0.92,
				}
			)

			Tween(
				icon,
				0.15,
				{
					ImageColor3 =
						isClose
						and Theme.CloseIcon
						or Theme.Text,
				}
			)
		end)
	)

	AddConnection(
		window,
		button.MouseLeave:Connect(function()
			Tween(
				button,
				0.15,
				{
					BackgroundTransparency = 1,
				}
			)

			Tween(
				icon,
				0.15,
				{
					ImageColor3 = Theme.SubText,
				}
			)
		end)
	)

	return button, icon
end

------------------------------------------------------------
-- WINDOW
------------------------------------------------------------

function Window.new(config)
	config = config or {}

	local self = setmetatable({}, Window)

	self.Title = config.Title or Defaults.Title
	self.Version = config.Version or Defaults.Version
	self.Icon = config.Icon or Defaults.Icon

	self.Tags = config.Tags or {}

	self.Size = config.Size or Defaults.Size

	self.MinSize = config.MinSize or Defaults.MinSize
	self.MaxSize = config.MaxSize or Defaults.MaxSize

	self.Position = config.Position or Defaults.Position

	self.TopbarHeight =
		config.TopbarHeight
		or Defaults.TopbarHeight

	self.CornerRadius =
		config.CornerRadius
		or Defaults.CornerRadius

	self.Draggable = config.Draggable ~= false
	self.Resizable = config.Resizable ~= false

	self.Minimized = false
	self.Maximized = false
	self.Closed = false

	self._Connections = {}

	--------------------------------------------------------
	-- SCREEN GUI
	--------------------------------------------------------

	local screenGui = New("ScreenGui", {
		Name =
			"Pebble_"
			.. tostring(
				math.random(100000, 999999)
			),

		ResetOnSpawn = false,

		IgnoreGuiInset = false,

		ZIndexBehavior =
			Enum.ZIndexBehavior.Sibling,

		DisplayOrder = 999999,
	})

	screenGui.Parent = GetGuiParent()

	self.ScreenGui = screenGui

	--------------------------------------------------------
	-- MAIN
	--------------------------------------------------------

	local main = New("Frame", {
		Name = "Window",

		Size = self.Size,
		Position = self.Position,

		AnchorPoint = Vector2.new(0.5, 0.5),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		Parent = screenGui,
	})

	self.Main = main

	--------------------------------------------------------
	-- GLASS SURFACE
	--------------------------------------------------------

	local surface = New("Frame", {
		Name = "Surface",

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.08,

		BorderSizePixel = 0,

		ZIndex = 1,

		Parent = main,
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(
				0,
				self.CornerRadius
			),
		}),

		New("UIStroke", {
			Color = Theme.Stroke,
			Transparency = 0.86,
			Thickness = 1,
		}),

		New("UIGradient", {
			Rotation = 110,

			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(
					0,
					Theme.BackgroundTop
				),

				ColorSequenceKeypoint.new(
					0.55,
					Theme.Background
				),

				ColorSequenceKeypoint.new(
					1,
					Theme.BackgroundBottom
				),
			}),

			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05),
				NumberSequenceKeypoint.new(0.5, 0.10),
				NumberSequenceKeypoint.new(1, 0.04),
			}),
		}),
	})

	self.Surface = surface

	--------------------------------------------------------
	-- TOPBAR
	--
	-- 100% transparent.
	-- No line. No stroke. No background.
	--------------------------------------------------------

	local topbar = New("Frame", {
		Name = "Topbar",

		Size = UDim2.new(
			1,
			0,
			0,
			self.TopbarHeight
		),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		Active = true,

		ZIndex = 10,

		Parent = main,
	})

	self.Topbar = topbar

	--------------------------------------------------------
	-- HUB ICON
	--
	-- Directly on the topbar.
	-- No holder, no background, no stroke.
	--------------------------------------------------------

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

	appIcon.ZIndex = 13

	appIcon.Parent = topbar

	self.IconImage = appIcon

	--------------------------------------------------------
	-- HEADER
	--------------------------------------------------------

	local header = New("Frame", {
		Name = "Header",

		Position =
			UDim2.fromOffset(
				48,
				0
			),

		Size =
			UDim2.new(
				1,
				-185,
				1,
				0
			),

		BackgroundTransparency = 1,

		ZIndex = 12,

		Parent = topbar,
	})

	self.Header = header

	--------------------------------------------------------
	-- TITLE
	--------------------------------------------------------

	local title = New("TextLabel", {
		Name = "Title",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				20
			),

		AnchorPoint =
			Vector2.new(
				0,
				0.5
			),

		Position =
			UDim2.new(
				0,
				0,
				0.5,
				0
			),

		BackgroundTransparency = 1,

		Text = self.Title,

		TextColor3 = Theme.Text,

		TextTransparency = 0,

		TextSize = 15,

		Font =
			Enum.Font.GothamSemibold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 13,

		Parent = header,
	})

	self.TitleLabel = title

	--------------------------------------------------------
	-- VERSION
	--------------------------------------------------------

	local version = New("TextLabel", {
		Name = "Version",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				18
			),

		AnchorPoint =
			Vector2.new(
				0,
				0.5
			),

		BackgroundTransparency = 1,

		Text = self.Version,

		TextColor3 = Theme.SubText,

		TextTransparency = 0,

		TextSize = 11,

		Font =
			Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 13,

		Parent = header,
	})

	self.VersionLabel = version

	--------------------------------------------------------
	-- TAGS
	--------------------------------------------------------

	local tagContainer = New("Frame", {
		Name = "Tags",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				22
			),

		AnchorPoint =
			Vector2.new(
				0,
				0.5
			),

		BackgroundTransparency = 1,

		ZIndex = 13,

		Parent = header,
	}, {
		New("UIListLayout", {
			FillDirection =
				Enum.FillDirection.Horizontal,

			VerticalAlignment =
				Enum.VerticalAlignment.Center,

			Padding = UDim.new(0, 5),
		}),
	})

	self.TagContainer = tagContainer

	--------------------------------------------------------
	-- HEADER LAYOUT
	--------------------------------------------------------

	local function UpdateHeader()
		task.defer(function()
			if not title.Parent then
				return
			end

			version.Position =
				UDim2.new(
					0,
					title.TextBounds.X + 8,
					0.5,
					0
				)

			tagContainer.Position =
				UDim2.new(
					0,
					title.TextBounds.X
						+ version.TextBounds.X
						+ 17,
					0.5,
					0
				)
		end)
	end

	self._UpdateHeader = UpdateHeader

	AddConnection(
		self,
		title:GetPropertyChangedSignal(
			"TextBounds"
		):Connect(UpdateHeader)
	)

	AddConnection(
		self,
		version:GetPropertyChangedSignal(
			"TextBounds"
		):Connect(UpdateHeader)
	)

	--------------------------------------------------------
	-- CONTROLS
	--------------------------------------------------------

	local controls = New("Frame", {
		Name = "Controls",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				30
			),

		AnchorPoint =
			Vector2.new(
				1,
				0.5
			),

		Position =
			UDim2.new(
				1,
				-10,
				0.5,
				0
			),

		BackgroundTransparency = 1,

		ZIndex = 20,

		Parent = topbar,
	}, {
		New("UIListLayout", {
			FillDirection =
				Enum.FillDirection.Horizontal,

			HorizontalAlignment =
				Enum.HorizontalAlignment.Right,

			VerticalAlignment =
				Enum.VerticalAlignment.Center,

			Padding = UDim.new(0, 3),
		}),
	})

	self.Controls = controls

	local minimizeButton, minimizeIcon =
		CreateControlButton(
			self,
			"Minimize",
			"minus",
			false
		)

	minimizeButton.Parent = controls

	local maximizeButton, maximizeIcon =
		CreateControlButton(
			self,
			"Maximize",
			"square",
			false
		)

	maximizeButton.Parent = controls

	local closeButton, closeIcon =
		CreateControlButton(
			self,
			"Close",
			"x",
			true
		)

	closeButton.Parent = controls

	self.MinimizeButton = minimizeButton
	self.MaximizeButton = maximizeButton
	self.CloseButton = closeButton

	self.MinimizeIcon = minimizeIcon
	self.MaximizeIcon = maximizeIcon
	self.CloseIcon = closeIcon

	--------------------------------------------------------
	-- CONTENT
	--------------------------------------------------------

	local content = New("Frame", {
		Name = "Content",

		Position =
			UDim2.fromOffset(
				0,
				self.TopbarHeight
			),

		Size =
			UDim2.new(
				1,
				0,
				1,
				-self.TopbarHeight
			),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 5,

		Parent = main,
	})

	self.Content = content

	--------------------------------------------------------
	-- TAGS
	--------------------------------------------------------

	self:SetTags(self.Tags)

	UpdateHeader()

	--------------------------------------------------------
	-- INTERACTION
	--------------------------------------------------------

	self:_SetupDrag()

	if self.Resizable then
		self:_SetupResize()
	end

	--------------------------------------------------------
	-- CONTROL EVENTS
	--------------------------------------------------------

	AddConnection(
		self,
		minimizeButton.MouseButton1Click:Connect(function()
			self:ToggleMinimize()
		end)
	)

	AddConnection(
		self,
		maximizeButton.MouseButton1Click:Connect(function()
			self:ToggleMaximize()
		end)
	)

	AddConnection(
		self,
		closeButton.MouseButton1Click:Connect(function()
			self:Close()
		end)
	)

	--------------------------------------------------------
	-- INTRO
	--------------------------------------------------------

	local originalSize = main.Size

	main.Size = UDim2.new(
		originalSize.X.Scale,
		originalSize.X.Offset - 12,

		originalSize.Y.Scale,
		originalSize.Y.Offset - 12
	)

	Tween(
		main,
		0.28,
		{
			Size = originalSize,
		}
	)

	return self
end

------------------------------------------------------------
-- DRAG
------------------------------------------------------------

function Window:_SetupDrag()
	if not self.Draggable then
		return
	end

	local dragging = false
	local dragStart
	local startPosition

	AddConnection(
		self,
		self.Topbar.InputBegan:Connect(function(input)
			if self.Maximized then
				return
			end

			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
				or input.UserInputType
					== Enum.UserInputType.Touch
			then
				dragging = true

				dragStart = input.Position
				startPosition = self.Main.Position
			end
		end)
	)

	AddConnection(
		self,
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end

			if
				input.UserInputType
					~= Enum.UserInputType.MouseMovement
				and input.UserInputType
					~= Enum.UserInputType.Touch
			then
				return
			end

			local delta =
				input.Position - dragStart

			self.Main.Position =
				UDim2.new(
					startPosition.X.Scale,

					startPosition.X.Offset
						+ delta.X,

					startPosition.Y.Scale,

					startPosition.Y.Offset
						+ delta.Y
				)
		end)
	)

	AddConnection(
		self,
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
	)
end

------------------------------------------------------------
-- RESIZE
------------------------------------------------------------

function Window:_SetupResize()
	local handle = New("ImageButton", {
		Name = "ResizeHandle",

		Size = UDim2.fromOffset(22, 22),

		AnchorPoint = Vector2.new(1, 1),

		Position = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		Image = "",

		AutoButtonColor = false,

		ZIndex = 50,

		Parent = self.Main,
	})

	self.ResizeHandle = handle

	local resizing = false
	local startMouse
	local startSize

	AddConnection(
		self,
		handle.InputBegan:Connect(function(input)
			if self.Maximized or self.Minimized then
				return
			end

			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
				or input.UserInputType
					== Enum.UserInputType.Touch
			then
				resizing = true

				startMouse = input.Position
				startSize = self.Main.AbsoluteSize
			end
		end)
	)

	AddConnection(
		self,
		UserInputService.InputChanged:Connect(function(input)
			if not resizing then
				return
			end

			if
				input.UserInputType
					~= Enum.UserInputType.MouseMovement
				and input.UserInputType
					~= Enum.UserInputType.Touch
			then
				return
			end

			local delta =
				input.Position - startMouse

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

			self.Main.Size =
				UDim2.fromOffset(
					width,
					height
				)
		end)
	)

	AddConnection(
		self,
		UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
				or input.UserInputType
					== Enum.UserInputType.Touch
			then
				resizing = false
			end
		end)
	)
end

------------------------------------------------------------
-- TITLE
------------------------------------------------------------

function Window:SetTitle(value)
	self.Title = tostring(value)
	self.TitleLabel.Text = self.Title

	self._UpdateHeader()

	return self
end

------------------------------------------------------------
-- VERSION
------------------------------------------------------------

function Window:SetVersion(value)
	self.Version = tostring(value)
	self.VersionLabel.Text = self.Version

	self._UpdateHeader()

	return self
end

------------------------------------------------------------
-- ICON
------------------------------------------------------------

function Window:SetIcon(name)
	self.Icon = name

	local image = GetIcon(name)

	if not image then
		self.IconImage.Visible = false
		return self
	end

	self.IconImage.Visible = true
	self.IconImage.Image = image

	return self
end

------------------------------------------------------------
-- TAGS
------------------------------------------------------------

function Window:SetTags(tags)
	self.Tags = tags or {}

	for _, child in ipairs(
		self.TagContainer:GetChildren()
	) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, tag in ipairs(self.Tags) do
		CreateTag(self, tag)
	end

	self._UpdateHeader()

	return self
end

function Window:AddTag(tag)
	table.insert(self.Tags, tag)

	CreateTag(self, tag)

	self._UpdateHeader()

	return self
end

------------------------------------------------------------
-- MINIMIZE
------------------------------------------------------------

function Window:ToggleMinimize()
	if self.Closed then
		return self
	end

	if self.Maximized then
		self:ToggleMaximize()
	end

	self.Minimized = not self.Minimized

	if self.Minimized then
		self._MinimizedSize = self.Main.Size

		self.Content.Visible = false

		if self.ResizeHandle then
			self.ResizeHandle.Visible = false
		end

		Tween(
			self.Main,
			0.28,
			{
				Size = UDim2.new(
					self.Main.Size.X.Scale,
					self.Main.Size.X.Offset,

					0,
					self.TopbarHeight
				)
			}
		)
	else
		self.Content.Visible = true

		if self.ResizeHandle then
			self.ResizeHandle.Visible = true
		end

		Tween(
			self.Main,
			0.30,
			{
				Size =
					self._MinimizedSize
					or self.Size
			}
		)
	end

	return self
end

------------------------------------------------------------
-- MAXIMIZE
------------------------------------------------------------

function Window:ToggleMaximize()
	if self.Closed then
		return self
	end

	if self.Minimized then
		self:ToggleMinimize()
	end

	self.Maximized = not self.Maximized

	if self.Maximized then
		self._RestoreSize = self.Main.Size
		self._RestorePosition = self.Main.Position
		self._RestoreAnchor = self.Main.AnchorPoint

		if self.ResizeHandle then
			self.ResizeHandle.Visible = false
		end

		self.Main.AnchorPoint =
			Vector2.new(0, 0)

		Tween(
			self.Main,
			0.32,
			{
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
						-16
					),
			}
		)
	else
		if self.ResizeHandle then
			self.ResizeHandle.Visible = true
		end

		self.Main.AnchorPoint =
			self._RestoreAnchor
			or Vector2.new(0.5, 0.5)

		Tween(
			self.Main,
			0.32,
			{
				Position =
					self._RestorePosition
					or self.Position,

				Size =
					self._RestoreSize
					or self.Size,
			}
		)
	end

	return self
end

------------------------------------------------------------
-- VISIBILITY
------------------------------------------------------------

function Window:SetVisible(value)
	self.ScreenGui.Enabled = value == true
	return self
end

function Window:Show()
	return self:SetVisible(true)
end

function Window:Hide()
	return self:SetVisible(false)
end

------------------------------------------------------------
-- CLOSE
------------------------------------------------------------

function Window:Close()
	if self.Closed then
		return
	end

	self.Closed = true

	local currentSize = self.Main.Size

	Tween(
		self.Main,
		0.18,
		{
			Size =
				UDim2.new(
					currentSize.X.Scale,
					currentSize.X.Offset - 12,

					currentSize.Y.Scale,
					currentSize.Y.Offset - 12
				),
		}
	)

	Tween(
		self.Surface,
		0.18,
		{
			BackgroundTransparency = 1,
		}
	)

	task.delay(0.19, function()
		self:Destroy()
	end)
end

------------------------------------------------------------
-- DESTROY
------------------------------------------------------------

function Window:Destroy()
	for _, connection in ipairs(
		self._Connections
	) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(self._Connections)

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end

	self.Closed = true
end

------------------------------------------------------------
-- API
------------------------------------------------------------

function Pebble:CreateWindow(config)
	return Window.new(config)
end

function Pebble.new(config)
	return Window.new(config)
end

Pebble.Window = Window
Pebble.Theme = Theme
Pebble.Icons = LucideIcons

return Pebble
