--[[
	██████╗ ███████╗██████╗ ██████╗ ██╗     ███████╗
	██╔══██╗██╔════╝██╔══██╗██╔══██╗██║     ██╔════╝
	██████╔╝█████╗  ██████╔╝██████╔╝██║     █████╗
	██╔═══╝ ██╔══╝  ██╔══██╗██╔══██╗██║     ██╔══╝
	██║     ███████╗██████╔╝██████╔╝███████╗███████╗
	╚═╝     ╚══════╝╚═════╝ ╚═════╝ ╚══════╝╚══════╝

	Pebble UI Library
	Window Prototype

	Current features:
	- Window
	- Lucide icons
	- Acrylic style
	- Drag
	- Resize
	- Minimize
	- Maximize
	- Close
	- Tags
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

Pebble.Version = "0.1.0"

------------------------------------------------------------
-- LUCIDE
------------------------------------------------------------

local Lucide

do
	local Success, Result = pcall(function()
		return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"
		))()
	end)

	if Success then
		Lucide = Result

		pcall(function()
			Lucide.SetIconsType("lucide")
		end)
	else
		warn("[Pebble] Failed to load Lucide icons:", Result)
	end
end

------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------

local Theme = {

	Window = Color3.fromRGB(15, 16, 18),

	Glass = Color3.fromRGB(28, 29, 33),

	GlassLight = Color3.fromRGB(42, 43, 48),

	Topbar = Color3.fromRGB(27, 28, 32),

	Stroke = Color3.fromRGB(255, 255, 255),

	Text = Color3.fromRGB(244, 244, 246),

	SubText = Color3.fromRGB(155, 156, 165),

	Icon = Color3.fromRGB(213, 214, 220),

	Hover = Color3.fromRGB(255, 255, 255),

	Close = Color3.fromRGB(239, 89, 89),

	CloseIcon = Color3.fromRGB(255, 178, 178),

	Tag = Color3.fromRGB(255, 255, 255),

	TagText = Color3.fromRGB(201, 202, 210),
}

local Defaults = {

	Title = "Pebble",

	Version = "v0.1",

	Icon = "gem",

	Tags = {},

	Size = UDim2.fromOffset(680, 450),

	MinSize = Vector2.new(440, 300),

	MaxSize = Vector2.new(1100, 760),

	Position = UDim2.fromScale(0.5, 0.5),

	Draggable = true,

	Resizable = true,

	TopbarHeight = 54,

	CornerRadius = 11,
}

------------------------------------------------------------
-- UTILITY
------------------------------------------------------------

local function New(ClassName, Properties, Children)

	local Object = Instance.new(ClassName)

	if Properties then
		for Property, Value in pairs(Properties) do
			Object[Property] = Value
		end
	end

	if Children then
		for _, Child in ipairs(Children) do
			Child.Parent = Object
		end
	end

	return Object
end

local function Tween(Object, Duration, Properties)

	local Animation = TweenService:Create(
		Object,
		TweenInfo.new(
			Duration,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		Properties
	)

	Animation:Play()

	return Animation
end

local function AddConnection(Window, Connection)

	table.insert(
		Window._Connections,
		Connection
	)

	return Connection
end

------------------------------------------------------------
-- PARENT
------------------------------------------------------------

local function GetGuiParent()

	if typeof(gethui) == "function" then

		local Success, Result = pcall(gethui)

		if Success and Result then
			return Result
		end
	end

	local Success = pcall(function()
		return CoreGui.Name
	end)

	if Success then
		return CoreGui
	end

	if LocalPlayer then
		return LocalPlayer:WaitForChild("PlayerGui")
	end

	return nil
end

------------------------------------------------------------
-- ICON SYSTEM
------------------------------------------------------------

local function GetIcon(Name)

	if not Name then
		return nil
	end

	--------------------------------------------------------
	-- DIRECT ASSET
	--------------------------------------------------------

	if typeof(Name) == "string"
		and string.find(Name, "rbxassetid://")
	then

		return {
			Image = Name,

			ImageRectSize = Vector2.zero,

			ImageRectOffset = Vector2.zero,
		}
	end

	--------------------------------------------------------
	-- LUCIDE
	--------------------------------------------------------

	if not Lucide then
		return nil
	end

	local Success, Icon = pcall(function()
		return Lucide.Icon(Name)
	end)

	if not Success or not Icon then
		warn(
			"[Pebble] Lucide icon not found:",
			Name
		)

		return nil
	end

	if typeof(Icon) == "string" then

		return {
			Image = Icon,

			ImageRectSize = Vector2.zero,

			ImageRectOffset = Vector2.zero,
		}
	end

	if typeof(Icon) == "table" then

		local Sprite = Icon[2] or {}

		return {
			Image = Icon[1],

			ImageRectSize =
				Sprite.ImageRectSize
				or Vector2.zero,

			ImageRectOffset =
				Sprite.ImageRectPosition
				or Sprite.ImageRectOffset
				or Vector2.zero,
		}
	end

	return nil
end

local function CreateIcon(Name, Size)

	local Data = GetIcon(Name)

	local Icon = New("ImageLabel", {

		Name = "Icon",

		Size = UDim2.fromOffset(
			Size or 18,
			Size or 18
		),

		BackgroundTransparency = 1,

		Image = Data and Data.Image or "",

		ImageRectSize =
			Data
			and Data.ImageRectSize
			or Vector2.zero,

		ImageRectOffset =
			Data
			and Data.ImageRectOffset
			or Vector2.zero,

		ImageColor3 = Theme.Icon,

		ScaleType = Enum.ScaleType.Fit,
	})

	return Icon
end

------------------------------------------------------------
-- WINDOW CLASS
------------------------------------------------------------

local Window = {}

Window.__index = Window

------------------------------------------------------------
-- CREATE TAG
------------------------------------------------------------

local function CreateTag(WindowObject, Data)

	local Text

	if typeof(Data) == "table" then
		Text =
			Data.Text
			or Data.Name
			or "Tag"
	else
		Text = tostring(Data)
	end

	local Tag = New("Frame", {

		Name = "Tag",

		AutomaticSize =
			Enum.AutomaticSize.X,

		Size = UDim2.fromOffset(
			0,
			22
		),

		BackgroundColor3 =
			Theme.Tag,

		BackgroundTransparency =
			0.93,

		BorderSizePixel = 0,

	}, {

		New("UICorner", {

			CornerRadius =
				UDim.new(0, 6),

		}),

		New("UIStroke", {

			Color =
				Theme.Stroke,

			Transparency =
				0.92,

			Thickness = 1,

		}),

		New("UIPadding", {

			PaddingLeft =
				UDim.new(0, 7),

			PaddingRight =
				UDim.new(0, 7),

		}),

		New("TextLabel", {

			AutomaticSize =
				Enum.AutomaticSize.X,

			Size =
				UDim2.new(
					0,
					0,
					1,
					0
				),

			BackgroundTransparency = 1,

			Text = Text,

			TextColor3 =
				Theme.TagText,

			TextTransparency = 0.08,

			TextSize = 11,

			Font =
				Enum.Font.GothamMedium,

		}),
	})

	Tag.Parent =
		WindowObject.TagContainer

	return Tag
end

------------------------------------------------------------
-- CONTROL BUTTON
------------------------------------------------------------

local function CreateControlButton(
	WindowObject,
	Name,
	IconName,
	IsClose
)

	local Button = New("ImageButton", {

		Name = Name,

		Size =
			UDim2.fromOffset(
				30,
				30
			),

		BackgroundColor3 =
			IsClose
			and Theme.Close
			or Theme.Hover,

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Image = "",

	}, {

		New("UICorner", {

			CornerRadius =
				UDim.new(0, 7),

		}),

	})

	local Icon =
		CreateIcon(
			IconName,
			16
		)

	Icon.AnchorPoint =
		Vector2.new(0.5, 0.5)

	Icon.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	Icon.ImageColor3 =
		Theme.SubText

	Icon.ImageTransparency =
		0.05

	Icon.Parent = Button

	--------------------------------------------------------
	-- HOVER
	--------------------------------------------------------

	AddConnection(
		WindowObject,
		Button.MouseEnter:Connect(
			function()

				Tween(
					Button,
					0.15,
					{
						BackgroundTransparency =
							IsClose
							and 0.82
							or 0.93,
					}
				)

				Tween(
					Icon,
					0.15,
					{
						ImageColor3 =
							IsClose
							and Theme.CloseIcon
							or Theme.Text,

						ImageTransparency = 0,
					}
				)
			end
		)
	)

	AddConnection(
		WindowObject,
		Button.MouseLeave:Connect(
			function()

				Tween(
					Button,
					0.15,
					{
						BackgroundTransparency = 1,
					}
				)

				Tween(
					Icon,
					0.15,
					{
						ImageColor3 =
							Theme.SubText,

						ImageTransparency =
							0.05,
					}
				)
			end
		)
	)

	Button.Icon = Icon

	return Button
end

------------------------------------------------------------
-- WINDOW CONSTRUCTOR
------------------------------------------------------------

function Window.new(Config)

	Config = Config or {}

	local Self =
		setmetatable(
			{},
			Window
		)

	--------------------------------------------------------
	-- CONFIG
	--------------------------------------------------------

	Self.Title =
		Config.Title
		or Defaults.Title

	Self.Version =
		Config.Version
		or Defaults.Version

	Self.Icon =
		Config.Icon
		or Defaults.Icon

	Self.Tags =
		Config.Tags
		or {}

	Self.Size =
		Config.Size
		or Defaults.Size

	Self.MinSize =
		Config.MinSize
		or Defaults.MinSize

	Self.MaxSize =
		Config.MaxSize
		or Defaults.MaxSize

	Self.Position =
		Config.Position
		or Defaults.Position

	Self.Draggable =
		Config.Draggable
		~= false

	Self.Resizable =
		Config.Resizable
		~= false

	Self.TopbarHeight =
		Config.TopbarHeight
		or Defaults.TopbarHeight

	Self.CornerRadius =
		Config.CornerRadius
		or Defaults.CornerRadius

	Self.Minimized = false

	Self.Maximized = false

	Self.Closed = false

	Self._Connections = {}

	Self._RestoreSize = nil

	Self._RestorePosition = nil

	Self._RestoreAnchorPoint = nil

	--------------------------------------------------------
	-- SCREEN GUI
	--------------------------------------------------------

	local ScreenGui = New(
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

			ResetOnSpawn = false,

			ZIndexBehavior =
				Enum.ZIndexBehavior.Sibling,

			IgnoreGuiInset = false,

			DisplayOrder = 999999,
		}
	)

	ScreenGui.Parent =
		GetGuiParent()

	Self.ScreenGui =
		ScreenGui

	--------------------------------------------------------
	-- WINDOW
	--------------------------------------------------------

	local Main = New(
		"CanvasGroup",
		{
			Name = "Window",

			Size =
				Self.Size,

			Position =
				Self.Position,

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			BackgroundColor3 =
				Theme.Window,

			BackgroundTransparency =
				0.04,

			BorderSizePixel = 0,

			ClipsDescendants = true,

			GroupTransparency = 0,

			Parent =
				ScreenGui,
		},
		{

			New("UICorner", {

				CornerRadius =
					UDim.new(
						0,
						Self.CornerRadius
					),

			}),

			New("UIStroke", {

				Color =
					Theme.Stroke,

				Transparency =
					0.88,

				Thickness = 1,

			}),
		}
	)

	Self.Main = Main

	--------------------------------------------------------
	-- BASE GLASS TINT
	--------------------------------------------------------

	local Glass =
		New(
			"Frame",
			{
				Name = "Glass",

				Size =
					UDim2.fromScale(
						1,
						1
					),

				BackgroundColor3 =
					Theme.Glass,

				BackgroundTransparency =
					0.35,

				BorderSizePixel = 0,

				ZIndex = 0,

				Parent = Main,
			},
			{

				New("UICorner", {

					CornerRadius =
						UDim.new(
							0,
							Self.CornerRadius
						),

				}),

				New("UIGradient", {

					Rotation = 125,

					Color =
						ColorSequence.new({

							ColorSequenceKeypoint.new(
								0,
								Color3.fromRGB(
									45,
									46,
									51
								)
							),

							ColorSequenceKeypoint.new(
								0.45,
								Color3.fromRGB(
									26,
									27,
									31
								)
							),

							ColorSequenceKeypoint.new(
								1,
								Color3.fromRGB(
									14,
									15,
									17
								)
							),

						}),

					Transparency =
						NumberSequence.new({

							NumberSequenceKeypoint.new(
								0,
								0.28
							),

							NumberSequenceKeypoint.new(
								0.5,
								0.48
							),

							NumberSequenceKeypoint.new(
								1,
								0.22
							),

						}),

				}),
			}
		)

	Self.Glass = Glass

	--------------------------------------------------------
	-- ACRYLIC NOISE
	--------------------------------------------------------

	local Noise =
		New(
			"ImageLabel",
			{
				Name =
					"AcrylicNoise",

				Size =
					UDim2.fromScale(
						1,
						1
					),

				BackgroundTransparency = 1,

				Image =
					"rbxassetid://9968344227",

				ImageTransparency =
					0.92,

				ScaleType =
					Enum.ScaleType.Tile,

				TileSize =
					UDim2.fromOffset(
						128,
						128
					),

				ZIndex = 1,

				Parent = Main,
			},
			{

				New("UICorner", {

					CornerRadius =
						UDim.new(
							0,
							Self.CornerRadius
						),

				}),
			}
		)

	Self.Noise = Noise

	--------------------------------------------------------
	-- TOPBAR
	--------------------------------------------------------

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
						Self.TopbarHeight
					),

				BackgroundColor3 =
					Theme.Topbar,

				BackgroundTransparency =
					0.25,

				BorderSizePixel = 0,

				ZIndex = 5,

				Active = true,

				Parent = Main,
			},
			{

				New("UIGradient", {

					Rotation = 90,

					Color =
						ColorSequence.new({

							ColorSequenceKeypoint.new(
								0,
								Color3.fromRGB(
									43,
									44,
									49
								)
							),

							ColorSequenceKeypoint.new(
								1,
								Color3.fromRGB(
									25,
									26,
									30
								)
							),

						}),

					Transparency =
						NumberSequence.new({

							NumberSequenceKeypoint.new(
								0,
								0.20
							),

							NumberSequenceKeypoint.new(
								1,
								0.46
							),

						}),

				}),
			}
		)

	Self.Topbar = Topbar

	--------------------------------------------------------
	-- TOPBAR SHINE
	--------------------------------------------------------

	New("Frame", {

		Name = "TopHighlight",

		Size =
			UDim2.new(
				1,
				-20,
				0,
				1
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0
			),

		Position =
			UDim2.new(
				0.5,
				0,
				0,
				1
			),

		BackgroundColor3 =
			Color3.new(
				1,
				1,
				1
			),

		BackgroundTransparency =
			0.91,

		BorderSizePixel = 0,

		ZIndex = 6,

		Parent = Topbar,
	})

	--------------------------------------------------------
	-- SEPARATOR
	--------------------------------------------------------

	New("Frame", {

		Name = "Separator",

		Size =
			UDim2.new(
				1,
				-20,
				0,
				1
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				1
			),

		Position =
			UDim2.new(
				0.5,
				0,
				1,
				0
			),

		BackgroundColor3 =
			Color3.new(
				1,
				1,
				1
			),

		BackgroundTransparency =
			0.91,

		BorderSizePixel = 0,

		ZIndex = 6,

		Parent = Topbar,
	})

	--------------------------------------------------------
	-- APP ICON HOLDER
	--------------------------------------------------------

	local IconHolder =
		New(
			"Frame",
			{
				Name =
					"IconHolder",

				Size =
					UDim2.fromOffset(
						32,
						32
					),

				AnchorPoint =
					Vector2.new(
						0,
						0.5
					),

				Position =
					UDim2.new(
						0,
						13,
						0.5,
						0
					),

				BackgroundColor3 =
					Color3.fromRGB(
						255,
						255,
						255
					),

				BackgroundTransparency =
					0.94,

				BorderSizePixel = 0,

				ZIndex = 7,

				Parent = Topbar,
			},
			{

				New("UICorner", {

					CornerRadius =
						UDim.new(
							0,
							8
						),

				}),

				New("UIStroke", {

					Color =
						Theme.Stroke,

					Transparency =
						0.91,

					Thickness = 1,

				}),
			}
		)

	Self.IconHolder =
		IconHolder

	local AppIcon =
		CreateIcon(
			Self.Icon,
			18
		)

	AppIcon.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	AppIcon.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	AppIcon.ImageColor3 =
		Theme.Text

	AppIcon.ZIndex = 8

	AppIcon.Parent =
		IconHolder

	Self.IconImage =
		AppIcon

	--------------------------------------------------------
	-- HEADER DATA CONTAINER
	--------------------------------------------------------

	local Header =
		New("Frame", {

			Name = "Header",

			Position =
				UDim2.fromOffset(
					55,
					0
				),

			Size =
				UDim2.new(
					1,
					-190,
					1,
					0
				),

			BackgroundTransparency = 1,

			ZIndex = 7,

			Parent = Topbar,
		})

	Self.Header = Header

	--------------------------------------------------------
	-- TITLE
	--------------------------------------------------------

	local TitleLabel =
		New("TextLabel", {

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

			Text =
				Self.Title,

			TextColor3 =
				Theme.Text,

			TextSize = 15,

			Font =
				Enum.Font.GothamSemibold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			TextTruncate =
				Enum.TextTruncate.AtEnd,

			ZIndex = 8,

			Parent = Header,
		})

	Self.TitleLabel =
		TitleLabel

	--------------------------------------------------------
	-- VERSION
	--------------------------------------------------------

	local VersionLabel =
		New("TextLabel", {

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

			Text =
				Self.Version,

			TextColor3 =
				Theme.SubText,

			TextTransparency =
				0.1,

			TextSize = 11,

			Font =
				Enum.Font.GothamMedium,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 8,

			Parent = Header,
		})

	Self.VersionLabel =
		VersionLabel

	--------------------------------------------------------
	-- TAGS
	--------------------------------------------------------

	local TagContainer =
		New(
			"Frame",
			{
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

				ZIndex = 8,

				Parent = Header,
			},
			{

				New("UIListLayout", {

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
			}
		)

	Self.TagContainer =
		TagContainer

	--------------------------------------------------------
	-- HEADER LAYOUT
	--------------------------------------------------------

	local function UpdateHeader()

		task.defer(function()

			if not TitleLabel.Parent then
				return
			end

			VersionLabel.Position =
				UDim2.new(
					0,
					TitleLabel.TextBounds.X
						+ 8,
					0.5,
					0
				)

			TagContainer.Position =
				UDim2.new(
					0,
					TitleLabel.TextBounds.X
						+ VersionLabel.TextBounds.X
						+ 17,
					0.5,
					0
				)
		end)
	end

	Self._UpdateHeader =
		UpdateHeader

	AddConnection(
		Self,
		TitleLabel:GetPropertyChangedSignal(
			"TextBounds"
		):Connect(
			UpdateHeader
		)
	)

	AddConnection(
		Self,
		VersionLabel:GetPropertyChangedSignal(
			"TextBounds"
		):Connect(
			UpdateHeader
		)
	)

	--------------------------------------------------------
	-- WINDOW CONTROLS
	--------------------------------------------------------

	local Controls =
		New(
			"Frame",
			{
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

				ZIndex = 10,

				Parent = Topbar,
			},
			{

				New("UIListLayout", {

					FillDirection =
						Enum.FillDirection.Horizontal,

					HorizontalAlignment =
						Enum.HorizontalAlignment.Right,

					VerticalAlignment =
						Enum.VerticalAlignment.Center,

					Padding =
						UDim.new(
							0,
							3
						),

				}),
			}
		)

	Self.Controls =
		Controls

	local MinimizeButton =
		CreateControlButton(
			Self,
			"Minimize",
			"minus",
			false
		)

	MinimizeButton.Parent =
		Controls

	local MaximizeButton =
		CreateControlButton(
			Self,
			"Maximize",
			"square",
			false
		)

	MaximizeButton.Parent =
		Controls

	local CloseButton =
		CreateControlButton(
			Self,
			"Close",
			"x",
			true
		)

	CloseButton.Parent =
		Controls

	Self.MinimizeButton =
		MinimizeButton

	Self.MaximizeButton =
		MaximizeButton

	Self.CloseButton =
		CloseButton

	--------------------------------------------------------
	-- CONTENT
	--------------------------------------------------------

	local Content =
		New("Frame", {

			Name = "Content",

			Position =
				UDim2.fromOffset(
					0,
					Self.TopbarHeight
				),

			Size =
				UDim2.new(
					1,
					0,
					1,
					-Self.TopbarHeight
				),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			ZIndex = 3,

			Parent = Main,
		})

	Self.Content = Content

	--------------------------------------------------------
	-- INITIAL TAGS
	--------------------------------------------------------

	Self:SetTags(
		Self.Tags
	)

	UpdateHeader()

	--------------------------------------------------------
	-- INTERACTION
	--------------------------------------------------------

	Self:_SetupDrag()

	if Self.Resizable then
		Self:_SetupResize()
	end

	--------------------------------------------------------
	-- BUTTONS
	--------------------------------------------------------

	AddConnection(
		Self,
		MinimizeButton.MouseButton1Click:Connect(
			function()

				Self:ToggleMinimize()

			end
		)
	)

	AddConnection(
		Self,
		MaximizeButton.MouseButton1Click:Connect(
			function()

				Self:ToggleMaximize()

			end
		)
	)

	AddConnection(
		Self,
		CloseButton.MouseButton1Click:Connect(
			function()

				Self:Close()

			end
		)
	)

	--------------------------------------------------------
	-- INTRO ANIMATION
	--------------------------------------------------------

	Main.GroupTransparency = 1

	local OriginalSize =
		Main.Size

	Main.Size =
		UDim2.new(
			OriginalSize.X.Scale,
			OriginalSize.X.Offset - 18,

			OriginalSize.Y.Scale,
			OriginalSize.Y.Offset - 18
		)

	Tween(
		Main,
		0.32,
		{
			GroupTransparency = 0,

			Size = OriginalSize,
		}
	)

	return Self
end

------------------------------------------------------------
-- DRAG
------------------------------------------------------------

function Window:_SetupDrag()

	if not self.Draggable then
		return
	end

	local Dragging = false

	local DragInput = nil

	local DragStart = nil

	local StartPosition = nil

	AddConnection(
		self,
		self.Topbar.InputBegan:Connect(
			function(Input)

				if self.Maximized then
					return
				end

				if Input.UserInputType
						== Enum.UserInputType.MouseButton1
					or Input.UserInputType
						== Enum.UserInputType.Touch
				then

					Dragging = true

					DragInput =
						Input

					DragStart =
						Input.Position

					StartPosition =
						self.Main.Position
				end
			end
		)
	)

	AddConnection(
		self,
		UserInputService.InputChanged:Connect(
			function(Input)

				if not Dragging then
					return
				end

				if Input.UserInputType
						~= Enum.UserInputType.MouseMovement
					and Input.UserInputType
						~= Enum.UserInputType.Touch
				then

					return
				end

				local Delta =
					Input.Position
					- DragStart

				self.Main.Position =
					UDim2.new(

						StartPosition.X.Scale,

						StartPosition.X.Offset
							+ Delta.X,

						StartPosition.Y.Scale,

						StartPosition.Y.Offset
							+ Delta.Y
					)
			end
		)
	)

	AddConnection(
		self,
		UserInputService.InputEnded:Connect(
			function(Input)

				if Input == DragInput
					or Input.UserInputType
						== Enum.UserInputType.MouseButton1
				then

					Dragging = false

					DragInput = nil
				end
			end
		)
	)
end

------------------------------------------------------------
-- RESIZE
------------------------------------------------------------

function Window:_SetupResize()

	local Handle =
		New("ImageButton", {

			Name =
				"ResizeHandle",

			Size =
				UDim2.fromOffset(
					20,
					20
				),

			AnchorPoint =
				Vector2.new(
					1,
					1
				),

			Position =
				UDim2.new(
					1,
					0,
					1,
					0
				),

			BackgroundTransparency = 1,

			Image = "",

			AutoButtonColor = false,

			ZIndex = 50,

			Parent =
				self.Main,
		})

	self.ResizeHandle =
		Handle

	--------------------------------------------------------
	-- RESIZE MARK
	--------------------------------------------------------

	for Index = 0, 1 do

		New("Frame", {

			Size =
				UDim2.fromOffset(
					8 - Index * 3,
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
					-4,
					1,
					-(4 + Index * 4)
				),

			Rotation = -45,

			BackgroundColor3 =
				Theme.SubText,

			BackgroundTransparency =
				0.45
				+ Index * 0.1,

			BorderSizePixel = 0,

			ZIndex = 51,

			Parent = Handle,
		})
	end

	--------------------------------------------------------
	-- RESIZE LOGIC
	--------------------------------------------------------

	local Resizing = false

	local StartPosition

	local StartSize

	AddConnection(
		self,
		Handle.InputBegan:Connect(
			function(Input)

				if self.Maximized
					or self.Minimized
				then
					return
				end

				if Input.UserInputType
						== Enum.UserInputType.MouseButton1
					or Input.UserInputType
						== Enum.UserInputType.Touch
				then

					Resizing = true

					StartPosition =
						Input.Position

					StartSize =
						self.Main.AbsoluteSize
				end
			end
		)
	)

	AddConnection(
		self,
		UserInputService.InputChanged:Connect(
			function(Input)

				if not Resizing then
					return
				end

				if Input.UserInputType
						~= Enum.UserInputType.MouseMovement
					and Input.UserInputType
						~= Enum.UserInputType.Touch
				then
					return
				end

				local Delta =
					Input.Position
					- StartPosition

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

				self.Main.Size =
					UDim2.fromOffset(
						Width,
						Height
					)
			end
		)
	)

	AddConnection(
		self,
		UserInputService.InputEnded:Connect(
			function(Input)

				if Input.UserInputType
						== Enum.UserInputType.MouseButton1
					or Input.UserInputType
						== Enum.UserInputType.Touch
				then

					Resizing = false
				end
			end
		)
	)
end

------------------------------------------------------------
-- TITLE
------------------------------------------------------------

function Window:SetTitle(Title)

	self.Title =
		tostring(Title)

	self.TitleLabel.Text =
		self.Title

	self._UpdateHeader()

	return self
end

------------------------------------------------------------
-- VERSION
------------------------------------------------------------

function Window:SetVersion(Version)

	self.Version =
		tostring(Version)

	self.VersionLabel.Text =
		self.Version

	self._UpdateHeader()

	return self
end

------------------------------------------------------------
-- WINDOW ICON
------------------------------------------------------------

function Window:SetIcon(Name)

	self.Icon = Name

	local Data =
		GetIcon(Name)

	if not Data then

		self.IconHolder.Visible =
			false

		return self
	end

	self.IconHolder.Visible =
		true

	self.IconImage.Image =
		Data.Image or ""

	self.IconImage.ImageRectSize =
		Data.ImageRectSize
		or Vector2.zero

	self.IconImage.ImageRectOffset =
		Data.ImageRectOffset
		or Vector2.zero

	return self
end

------------------------------------------------------------
-- TAGS
------------------------------------------------------------

function Window:SetTags(Tags)

	self.Tags =
		Tags or {}

	for _, Child in ipairs(
		self.TagContainer:GetChildren()
	) do

		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end

	for _, Tag in ipairs(
		self.Tags
	) do

		CreateTag(
			self,
			Tag
		)
	end

	self._UpdateHeader()

	return self
end

------------------------------------------------------------
-- ADD TAG
------------------------------------------------------------

function Window:AddTag(Tag)

	table.insert(
		self.Tags,
		Tag
	)

	CreateTag(
		self,
		Tag
	)

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

	self.Minimized =
		not self.Minimized

	if self.Minimized then

		self._MinimizedSize =
			self.Main.Size

		self.Content.Visible =
			false

		if self.ResizeHandle then
			self.ResizeHandle.Visible =
				false
		end

		Tween(
			self.Main,
			0.28,
			{
				Size =
					UDim2.new(

						self.Main.Size.X.Scale,

						self.Main.Size.X.Offset,

						0,

						self.TopbarHeight
					)
			}
		)

	else

		self.Content.Visible =
			true

		if self.ResizeHandle then
			self.ResizeHandle.Visible =
				true
		end

		Tween(
			self.Main,
			0.3,
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

	self.Maximized =
		not self.Maximized

	if self.Maximized then

		self._RestoreSize =
			self.Main.Size

		self._RestorePosition =
			self.Main.Position

		self._RestoreAnchorPoint =
			self.Main.AnchorPoint

		if self.ResizeHandle then
			self.ResizeHandle.Visible =
				false
		end

		Tween(
			self.Main,
			0.32,
			{
				AnchorPoint =
					Vector2.new(
						0,
						0
					),

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
			self.ResizeHandle.Visible =
				true
		end

		Tween(
			self.Main,
			0.32,
			{
				AnchorPoint =
					self._RestoreAnchorPoint
					or Vector2.new(
						0.5,
						0.5
					),

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
-- SET SIZE
------------------------------------------------------------

function Window:SetSize(Size)

	self.Main.Size =
		Size

	return self
end

------------------------------------------------------------
-- SET POSITION
------------------------------------------------------------

function Window:SetPosition(Position)

	self.Main.Position =
		Position

	return self
end

------------------------------------------------------------
-- VISIBILITY
------------------------------------------------------------

function Window:SetVisible(Value)

	self.ScreenGui.Enabled =
		Value == true

	return self
end

function Window:Show()

	return self:SetVisible(
		true
	)
end

function Window:Hide()

	return self:SetVisible(
		false
	)
end

------------------------------------------------------------
-- CLOSE
------------------------------------------------------------

function Window:Close()

	if self.Closed then
		return
	end

	self.Closed = true

	Tween(
		self.Main,
		0.22,
		{
			GroupTransparency = 1,

			Size =
				UDim2.new(

					self.Main.Size.X.Scale,

					self.Main.Size.X.Offset
						- 18,

					self.Main.Size.Y.Scale,

					self.Main.Size.Y.Offset
						- 18
				),
		}
	)

	task.delay(
		0.23,
		function()

			self:Destroy()

		end
	)
end

------------------------------------------------------------
-- DESTROY
------------------------------------------------------------

function Window:Destroy()

	for _, Connection in ipairs(
		self._Connections
	) do

		pcall(function()
			Connection:Disconnect()
		end)
	end

	table.clear(
		self._Connections
	)

	if self.ScreenGui then

		self.ScreenGui:Destroy()

		self.ScreenGui = nil
	end

	self.Closed = true
end

------------------------------------------------------------
-- LIBRARY API
------------------------------------------------------------

function Pebble:CreateWindow(Config)

	return Window.new(
		Config
	)
end

-- Compatibility:
-- local Window = Pebble.new({...})

function Pebble.new(Config)

	return Window.new(
		Config
	)
end

------------------------------------------------------------
-- EXPOSE
------------------------------------------------------------

Pebble.Window = Window

Pebble.Theme = Theme

Pebble.Icons = Lucide

return Pebble
