--!strict

--[[
    Window.lua
    Primeira base da nossa UI Library.

    Ainda NÃO possui:
    - Tabs
    - Sections
    - Elements

    Possui:
    - Window
    - Drag
    - Resize
    - Minimize
    - Maximize / Restore
    - Close
    - Title
    - Version
    - Tags
    - Icon support
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Window = {}
Window.__index = Window

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local DEFAULTS = {
	Title = "UI Library",
	Version = "v1.0.0",

	Icon = nil,

	Size = UDim2.fromOffset(640, 420),
	MinSize = Vector2.new(420, 280),
	MaxSize = Vector2.new(1100, 750),

	Position = UDim2.fromScale(0.5, 0.5),

	Resizable = true,
	Draggable = true,

	Tags = {},

	CornerRadius = 14,

	TopbarHeight = 52,
	ResizeHandleSize = 14,
}

----------------------------------------------------------------
-- COLORS
----------------------------------------------------------------

local COLORS = {
	Background = Color3.fromRGB(18, 18, 20),
	Topbar = Color3.fromRGB(22, 22, 25),

	Border = Color3.fromRGB(48, 48, 54),

	Text = Color3.fromRGB(245, 245, 245),
	SubText = Color3.fromRGB(150, 150, 158),

	ButtonHover = Color3.fromRGB(40, 40, 45),

	TagBackground = Color3.fromRGB(34, 34, 38),
	TagText = Color3.fromRGB(190, 190, 198),

	Resize = Color3.fromRGB(95, 95, 105),
}

----------------------------------------------------------------
-- UTIL
----------------------------------------------------------------

local function Create(
	className: string,
	properties: {[string]: any}?,
	children: {Instance}?
): Instance

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

local function Tween(
	object: Instance,
	duration: number,
	properties: {[string]: any}
)

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

----------------------------------------------------------------
-- ICON SYSTEM
----------------------------------------------------------------

--[[
    Por enquanto a Window não depende de uma implementação específica.

    Você pode passar um IconResolver:

    IconResolver = function(name)
        return {
            Image = "...",
            ImageRectSize = Vector2.new(...),
            ImageRectOffset = Vector2.new(...)
        }
    end

    Assim depois conectamos nossa API Lucide sem acoplar
    a Window ao módulo de ícones.
]]

local function ResolveIcon(self, icon)

	if icon == nil then
		return nil
	end

	if typeof(icon) == "string" then

		-- Asset direto
		if icon:find("rbxassetid://") then
			return {
				Image = icon,
				ImageRectSize = Vector2.zero,
				ImageRectOffset = Vector2.zero,
			}
		end

		-- Resolver Lucide
		if self.IconResolver then

			local success, result = pcall(
				self.IconResolver,
				icon
			)

			if success and result then
				return result
			end
		end
	end

	if typeof(icon) == "table" then
		return icon
	end

	return nil
end

----------------------------------------------------------------
-- TAG
----------------------------------------------------------------

local function CreateTag(
	parent: Instance,
	text: string
)

	local tag = Create("Frame", {
		Name = "Tag",

		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 24),

		BackgroundColor3 = COLORS.TagBackground,

		BorderSizePixel = 0,

		Parent = parent,
	}, {

		Create("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),

		Create("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),

		Create("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,

			Size = UDim2.fromScale(0, 1),

			BackgroundTransparency = 1,

			Text = text,

			TextColor3 = COLORS.TagText,

			TextSize = 12,

			Font = Enum.Font.GothamMedium,
		}),

	})

	return tag
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------

function Window.new(config)

	config = config or {}

	local self = setmetatable({}, Window)

	------------------------------------------------------------
	-- SETTINGS
	------------------------------------------------------------

	self.Title = config.Title or DEFAULTS.Title
	self.Version = config.Version or DEFAULTS.Version

	self.Icon = config.Icon

	self.Tags = config.Tags or DEFAULTS.Tags

	self.Size = config.Size or DEFAULTS.Size

	self.MinSize =
		config.MinSize
		or DEFAULTS.MinSize

	self.MaxSize =
		config.MaxSize
		or DEFAULTS.MaxSize

	self.Position =
		config.Position
		or DEFAULTS.Position

	self.Resizable =
		config.Resizable ~= false

	self.Draggable =
		config.Draggable ~= false

	self.IconResolver =
		config.IconResolver

	self.Minimized = false
	self.Maximized = false
	self.Closed = false

	self._connections = {}

	------------------------------------------------------------
	-- SCREEN GUI
	------------------------------------------------------------

	local ScreenGui = Create("ScreenGui", {
		Name = "UILibrary",

		ResetOnSpawn = false,

		ZIndexBehavior =
			Enum.ZIndexBehavior.Sibling,

		IgnoreGuiInset = false,
	})

	self.ScreenGui = ScreenGui

	------------------------------------------------------------
	-- PARENT
	------------------------------------------------------------

	local success = pcall(function()
		ScreenGui.Parent = game:GetService("CoreGui")
	end)

	if not success then

		ScreenGui.Parent =
			LocalPlayer:WaitForChild("PlayerGui")
	end

	------------------------------------------------------------
	-- MAIN
	------------------------------------------------------------

	local Main = Create("Frame", {
		Name = "Window",

		Size = self.Size,

		Position = self.Position,

		AnchorPoint =
			Vector2.new(0.5, 0.5),

		BackgroundColor3 =
			COLORS.Background,

		BorderSizePixel = 0,

		ClipsDescendants = true,

		Parent = ScreenGui,
	}, {

		Create("UICorner", {
			CornerRadius =
				UDim.new(
					0,
					config.CornerRadius
					or DEFAULTS.CornerRadius
				),
		}),

		Create("UIStroke", {
			Color = COLORS.Border,

			Transparency = 0.25,

			Thickness = 1,
		}),

	})

	self.Main = Main

	------------------------------------------------------------
	-- TOPBAR
	------------------------------------------------------------

	local TopbarHeight =
		config.TopbarHeight
		or DEFAULTS.TopbarHeight

	local Topbar = Create("Frame", {
		Name = "Topbar",

		Size =
			UDim2.new(
				1,
				0,
				0,
				TopbarHeight
			),

		BackgroundColor3 =
			COLORS.Topbar,

		BorderSizePixel = 0,

		Parent = Main,
	})

	self.Topbar = Topbar

	------------------------------------------------------------
	-- TOPBAR BOTTOM BORDER
	------------------------------------------------------------

	Create("Frame", {
		Name = "Separator",

		Size =
			UDim2.new(
				1,
				0,
				0,
				1
			),

		Position =
			UDim2.new(
				0,
				0,
				1,
				-1
			),

		BackgroundColor3 =
			COLORS.Border,

		BackgroundTransparency = 0.4,

		BorderSizePixel = 0,

		Parent = Topbar,
	})

	------------------------------------------------------------
	-- ICON
	------------------------------------------------------------

	local IconHolder = Create("Frame", {
		Name = "IconHolder",

		Size = UDim2.fromOffset(30, 30),

		Position =
			UDim2.fromOffset(
				14,
				math.floor(
					(TopbarHeight - 30) / 2
				)
			),

		BackgroundColor3 =
			Color3.fromRGB(
				30,
				30,
				34
			),

		BorderSizePixel = 0,

		Parent = Topbar,
	}, {

		Create("UICorner", {
			CornerRadius =
				UDim.new(0, 8),
		}),

	})

	self.IconHolder = IconHolder

	local IconImage = Create("ImageLabel", {
		Name = "Icon",

		Size =
			UDim2.fromOffset(
				18,
				18
			),

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

		BackgroundTransparency = 1,

		ImageColor3 =
			COLORS.Text,

		ScaleType =
			Enum.ScaleType.Fit,

		Parent = IconHolder,
	})

	self.IconImage = IconImage

	------------------------------------------------------------
	-- TITLE CONTAINER
	------------------------------------------------------------

	local TitleContainer = Create(
		"Frame",
		{
			Name = "TitleContainer",

			Position =
				UDim2.fromOffset(
					54,
					0
				),

			Size =
				UDim2.new(
					1,
					-220,
					1,
					0
				),

			BackgroundTransparency = 1,

			Parent = Topbar,
		}
	)

	------------------------------------------------------------
	-- TITLE
	------------------------------------------------------------

	local Title = Create("TextLabel", {
		Name = "Title",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.new(
				0,
				0,
				0,
				20
			),

		Position =
			UDim2.new(
				0,
				0,
				0.5,
				-10
			),

		BackgroundTransparency = 1,

		Text = self.Title,

		TextColor3 = COLORS.Text,

		TextSize = 15,

		Font = Enum.Font.GothamSemibold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		Parent = TitleContainer,
	})

	self.TitleLabel = Title

	------------------------------------------------------------
	-- VERSION
	------------------------------------------------------------

	local Version = Create("TextLabel", {
		Name = "Version",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.new(
				0,
				0,
				0,
				18
			),

		Position =
			UDim2.new(
				0,
				Title.TextBounds.X + 8,
				0.5,
				-9
			),

		BackgroundTransparency = 1,

		Text = self.Version,

		TextColor3 =
			COLORS.SubText,

		TextSize = 12,

		Font =
			Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		Parent = TitleContainer,
	})

	self.VersionLabel = Version

	------------------------------------------------------------
	-- TAGS
	------------------------------------------------------------

	local TagContainer = Create("Frame", {
		Name = "Tags",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				24
			),

		Position =
			UDim2.new(
				0,
				0,
				0.5,
				-12
			),

		BackgroundTransparency = 1,

		Parent = TitleContainer,
	}, {

		Create("UIListLayout", {

			FillDirection =
				Enum.FillDirection.Horizontal,

			VerticalAlignment =
				Enum.VerticalAlignment.Center,

			Padding =
				UDim.new(
					0,
					5
				),

		}),

	})

	self.TagContainer = TagContainer

	------------------------------------------------------------
	-- UPDATE TITLE LAYOUT
	------------------------------------------------------------

	local function UpdateHeaderLayout()

		task.defer(function()

			Version.Position =
				UDim2.new(
					0,
					Title.TextBounds.X + 8,
					0.5,
					-9
				)

			TagContainer.Position =
				UDim2.new(
					0,
					Title.TextBounds.X
						+ Version.TextBounds.X
						+ 18,
					0.5,
					-12
				)

		end)

	end

	self._updateHeaderLayout =
		UpdateHeaderLayout

	------------------------------------------------------------
	-- BUTTON CONTAINER
	------------------------------------------------------------

	local Controls = Create("Frame", {
		Name = "Controls",

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

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size =
			UDim2.fromOffset(
				0,
				32
			),

		BackgroundTransparency = 1,

		Parent = Topbar,
	}, {

		Create("UIListLayout", {

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

		}),

	})

	------------------------------------------------------------
	-- CONTROL BUTTON
	------------------------------------------------------------

	local function ControlButton(
		name: string,
		text: string
	)

		local button = Create(
			"TextButton",
			{
				Name = name,

				Size =
					UDim2.fromOffset(
						32,
						32
					),

				BackgroundTransparency = 1,

				Text = text,

				TextSize = 16,

				TextColor3 =
					COLORS.SubText,

				Font =
					Enum.Font.GothamMedium,

				AutoButtonColor = false,

				Parent = Controls,
			},
			{

				Create("UICorner", {
					CornerRadius =
						UDim.new(
							0,
							7
						),
				}),

			}
		)

		button.MouseEnter:Connect(function()

			Tween(
				button,
				0.15,
				{
					BackgroundTransparency = 0,
					BackgroundColor3 =
						COLORS.ButtonHover,
				}
			)

		end)

		button.MouseLeave:Connect(function()

			Tween(
				button,
				0.15,
				{
					BackgroundTransparency = 1,
				}
			)

		end)

		return button
	end

	local MinimizeButton =
		ControlButton(
			"Minimize",
			"−"
		)

	local MaximizeButton =
		ControlButton(
			"Maximize",
			"□"
		)

	local CloseButton =
		ControlButton(
			"Close",
			"×"
		)

	self.MinimizeButton =
		MinimizeButton

	self.MaximizeButton =
		MaximizeButton

	self.CloseButton =
		CloseButton

	------------------------------------------------------------
	-- CONTENT
	------------------------------------------------------------

	local Content = Create("Frame", {
		Name = "Content",

		Position =
			UDim2.fromOffset(
				0,
				TopbarHeight
			),

		Size =
			UDim2.new(
				1,
				0,
				1,
				-TopbarHeight
			),

		BackgroundTransparency = 1,

		Parent = Main,
	})

	self.Content = Content

	------------------------------------------------------------
	-- DRAG
	------------------------------------------------------------

	self:_setupDrag()

	------------------------------------------------------------
	-- RESIZE
	------------------------------------------------------------

	if self.Resizable then
		self:_setupResize()
	end

	------------------------------------------------------------
	-- BUTTON EVENTS
	------------------------------------------------------------

	MinimizeButton.MouseButton1Click:Connect(
		function()

			self:ToggleMinimize()

		end
	)

	MaximizeButton.MouseButton1Click:Connect(
		function()

			self:ToggleMaximize()

		end
	)

	CloseButton.MouseButton1Click:Connect(
		function()

			self:Close()

		end
	)

	------------------------------------------------------------
	-- INITIAL DATA
	------------------------------------------------------------

	self:SetIcon(self.Icon)

	self:SetTags(self.Tags)

	UpdateHeaderLayout()

	return self
end

----------------------------------------------------------------
-- DRAG
----------------------------------------------------------------

function Window:_setupDrag()

	if not self.Draggable then
		return
	end

	local dragging = false

	local dragStart
	local startPosition
	local inputObject

	self.Topbar.InputBegan:Connect(
		function(input)

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

				inputObject = input

				dragStart =
					input.Position

				startPosition =
					self.Main.Position

			end

		end
	)

	UserInputService.InputChanged:Connect(
		function(input)

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

			end

		end
	)

	UserInputService.InputEnded:Connect(
		function(input)

			if input == inputObject then
				dragging = false
			end

		end
	)

end

----------------------------------------------------------------
-- RESIZE
----------------------------------------------------------------

function Window:_setupResize()

	local handleSize =
		DEFAULTS.ResizeHandleSize

	local ResizeHandle = Create("Frame", {
		Name = "ResizeHandle",

		Size =
			UDim2.fromOffset(
				handleSize,
				handleSize
			),

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

		BackgroundTransparency = 1,

		Active = true,

		Parent = self.Main,
	})

	self.ResizeHandle =
		ResizeHandle

	------------------------------------------------------------
	-- SMALL VISUAL CORNER
	------------------------------------------------------------

	Create("Frame", {
		Size =
			UDim2.fromOffset(
				7,
				1
			),

		AnchorPoint =
			Vector2.new(
				1,
				1
			),

		Position =
			UDim2.new(
				1,
				-3,
				1,
				-3
			),

		Rotation = -45,

		BackgroundColor3 =
			COLORS.Resize,

		BorderSizePixel = 0,

		Parent = ResizeHandle,
	})

	------------------------------------------------------------
	-- LOGIC
	------------------------------------------------------------

	local resizing = false

	local startMouse
	local startSize

	ResizeHandle.InputBegan:Connect(
		function(input)

			if self.Maximized then
				return
			end

			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
				or input.UserInputType
					== Enum.UserInputType.Touch
			then

				resizing = true

				startMouse =
					input.Position

				startSize =
					self.Main.AbsoluteSize

			end

		end
	)

	UserInputService.InputChanged:Connect(
		function(input)

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

		end
	)

	UserInputService.InputEnded:Connect(
		function(input)

			if
				input.UserInputType
					== Enum.UserInputType.MouseButton1
				or input.UserInputType
					== Enum.UserInputType.Touch
			then

				resizing = false

			end

		end
	)

end

----------------------------------------------------------------
-- TITLE
----------------------------------------------------------------

function Window:SetTitle(title: string)

	self.Title =
		title

	self.TitleLabel.Text =
		title

	self._updateHeaderLayout()

	return self
end

----------------------------------------------------------------
-- VERSION
----------------------------------------------------------------

function Window:SetVersion(version: string)

	self.Version =
		version

	self.VersionLabel.Text =
		version

	self._updateHeaderLayout()

	return self
end

----------------------------------------------------------------
-- ICON
----------------------------------------------------------------

function Window:SetIcon(icon)

	self.Icon =
		icon

	local resolved =
		ResolveIcon(
			self,
			icon
		)

	if not resolved then

		self.IconHolder.Visible =
			false

		return self
	end

	self.IconHolder.Visible =
		true

	self.IconImage.Image =
		resolved.Image
		or ""

	self.IconImage.ImageRectSize =
		resolved.ImageRectSize
		or Vector2.zero

	self.IconImage.ImageRectOffset =
		resolved.ImageRectOffset
		or Vector2.zero

	return self
end

----------------------------------------------------------------
-- TAGS
----------------------------------------------------------------

function Window:SetTags(tags)

	self.Tags =
		tags or {}

	for _, object in ipairs(
		self.TagContainer:GetChildren()
	) do

		if object:IsA("Frame") then
			object:Destroy()
		end

	end

	for _, tag in ipairs(self.Tags) do

		if typeof(tag) == "string" then

			CreateTag(
				self.TagContainer,
				tag
			)

		elseif typeof(tag) == "table" then

			CreateTag(
				self.TagContainer,
				tag.Text or tag.Name or "Tag"
			)

		end
	end

	self._updateHeaderLayout()

	return self
end

----------------------------------------------------------------
-- MINIMIZE
----------------------------------------------------------------

function Window:ToggleMinimize()

	if self.Maximized then
		return
	end

	self.Minimized =
		not self.Minimized

	if self.Minimized then

		self._lastSize =
			self.Main.Size

		self.Content.Visible =
			false

		Tween(
			self.Main,
			0.28,
			{
				Size =
					UDim2.new(
						self.Main.Size.X.Scale,
						self.Main.Size.X.Offset,
						0,
						DEFAULTS.TopbarHeight
					)
			}
		)

	else

		self.Content.Visible =
			true

		Tween(
			self.Main,
			0.28,
			{
				Size =
					self._lastSize
					or self.Size
			}
		)

	end

	return self
end

----------------------------------------------------------------
-- MAXIMIZE
----------------------------------------------------------------

function Window:ToggleMaximize()

	if self.Minimized then
		self:ToggleMinimize()
	end

	self.Maximized =
		not self.Maximized

	if self.Maximized then

		self._restoreSize =
			self.Main.Size

		self._restorePosition =
			self.Main.Position

		Tween(
			self.Main,
			0.3,
			{
				AnchorPoint =
					Vector2.zero,

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

		self.MaximizeButton.Text =
			"❐"

	else

		Tween(
			self.Main,
			0.3,
			{
				AnchorPoint =
					Vector2.new(
						0.5,
						0.5
					),

				Position =
					self._restorePosition
					or self.Position,

				Size =
					self._restoreSize
					or self.Size,
			}
		)

		self.MaximizeButton.Text =
			"□"

	end

	return self
end

----------------------------------------------------------------
-- SIZE
----------------------------------------------------------------

function Window:SetSize(
	size: UDim2
)

	self.Main.Size =
		size

	return self
end

----------------------------------------------------------------
-- POSITION
----------------------------------------------------------------

function Window:SetPosition(
	position: UDim2
)

	self.Main.Position =
		position

	return self
end

----------------------------------------------------------------
-- VISIBILITY
----------------------------------------------------------------

function Window:SetVisible(
	visible: boolean
)

	self.ScreenGui.Enabled =
		visible

	return self
end

function Window:Show()

	return self:SetVisible(true)

end

function Window:Hide()

	return self:SetVisible(false)

end

----------------------------------------------------------------
-- CLOSE
----------------------------------------------------------------

function Window:Close()

	if self.Closed then
		return
	end

	self.Closed = true

	Tween(
		self.Main,
		0.2,
		{
			BackgroundTransparency = 1,

			Size =
				UDim2.new(
					self.Main.Size.X.Scale,
					self.Main.Size.X.Offset - 20,

					self.Main.Size.Y.Scale,
					self.Main.Size.Y.Offset - 20
				),
		}
	)

	task.delay(
		0.2,
		function()

			if self.ScreenGui then
				self.ScreenGui:Destroy()
			end

		end
	)

end

----------------------------------------------------------------
-- DESTROY
----------------------------------------------------------------

function Window:Destroy()

	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end

	self.Closed =
		true

end

return Window
