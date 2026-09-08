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

Pebble.Version = "0.2.0"

------------------------------------------------------------
-- THEME
------------------------------------------------------------

local Theme = {

	--------------------------------------------------------
	-- WINDOW
	--------------------------------------------------------

	Background = Color3.fromRGB(
		16,
		17,
		19
	),

	BackgroundTop = Color3.fromRGB(
		24,
		25,
		28
	),

	BackgroundBottom = Color3.fromRGB(
		13,
		14,
		16
	),

	Stroke = Color3.fromRGB(
		255,
		255,
		255
	),

	--------------------------------------------------------
	-- TEXT
	--------------------------------------------------------

	Text = Color3.fromRGB(
		244,
		244,
		247
	),

	SubText = Color3.fromRGB(
		146,
		147,
		157
	),

	MutedText = Color3.fromRGB(
		105,
		106,
		116
	),

	--------------------------------------------------------
	-- SIDEBAR
	--------------------------------------------------------

	Sidebar = Color3.fromRGB(
		17,
		18,
		20
	),

	SidebarHover = Color3.fromRGB(
		255,
		255,
		255
	),

	SidebarSelected = Color3.fromRGB(
		255,
		255,
		255
	),

	--------------------------------------------------------
	-- ACCENT
	--------------------------------------------------------

	Accent = Color3.fromRGB(
		103,
		76,
		255
	),

	AccentBright = Color3.fromRGB(
		124,
		96,
		255
	),

	--------------------------------------------------------
	-- ICONS
	--------------------------------------------------------

	Icon = Color3.fromRGB(
		183,
		184,
		194
	),

	IconSelected = Color3.fromRGB(
		245,
		245,
		247
	),

	--------------------------------------------------------
	-- TAG
	--------------------------------------------------------

	Tag = Color3.fromRGB(
		255,
		255,
		255
	),

	TagText = Color3.fromRGB(
		200,
		201,
		210
	),

	--------------------------------------------------------
	-- USER CARD
	--------------------------------------------------------

	UserBackground = Color3.fromRGB(
		255,
		255,
		255
	),

	--------------------------------------------------------
	-- CONTROLS
	--------------------------------------------------------

	Close = Color3.fromRGB(
		235,
		76,
		76
	),

	CloseIcon = Color3.fromRGB(
		255,
		180,
		180
	),
}

------------------------------------------------------------
-- DEFAULTS
------------------------------------------------------------

local Defaults = {

	Title = "Pebble",

	Version = "v0.2",

	Icon = "sparkles",

	Tags = {},

	Size = UDim2.fromOffset(
		760,
		500
	),

	MinSize = Vector2.new(
		560,
		360
	),

	MaxSize = Vector2.new(
		1200,
		800
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	TopbarHeight = 56,

	SidebarWidth = 218,

	CollapsedSidebarWidth = 62,

	CornerRadius = 12,

	Draggable = true,

	Resizable = true,
}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function New(
	className,
	properties,
	children
)

	local object =
		Instance.new(className)

	if properties then

		for property, value in pairs(
			properties
		) do

			object[property] =
				value

		end
	end

	if children then

		for _, child in ipairs(
			children
		) do

			child.Parent =
				object

		end
	end

	return object
end

------------------------------------------------------------
-- TWEEN
------------------------------------------------------------

local function Tween(
	object,
	duration,
	properties
)

	local tween =
		TweenService:Create(
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

------------------------------------------------------------
-- CONNECTION
------------------------------------------------------------

local function AddConnection(
	window,
	connection
)

	table.insert(
		window._Connections,
		connection
	)

	return connection
end

------------------------------------------------------------
-- GUI PARENT
------------------------------------------------------------

local function GetGuiParent()

	if typeof(gethui) == "function" then

		local success, result =
			pcall(gethui)

		if success and result then

			return result

		end

	end

	local success =
		pcall(function()

			return CoreGui.Name

		end)

	if success then

		return CoreGui

	end

	if LocalPlayer then

		return LocalPlayer:WaitForChild(
			"PlayerGui"
		)

	end

	return nil
end

------------------------------------------------------------
-- LUCIDE
------------------------------------------------------------

local LucideIcons = {}

do

	local success, result =
		pcall(function()

			return loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"
				)
			)()

		end)

	if success
		and typeof(result) == "table"
	then

		LucideIcons =
			result

	else

		warn(
			"[Pebble] Failed to load Lucide:",
			result
		)

	end
end

------------------------------------------------------------
-- ICON API
------------------------------------------------------------

local function GetIcon(name)

	if typeof(name) ~= "string" then

		return nil

	end

	if string.match(
		name,
		"^rbxassetid://"
	) then

		return name

	end

	local icon =
		LucideIcons[name]

	if not icon then

		warn(
			"[Pebble] Lucide icon not found:",
			name
		)

		return nil

	end

	return icon
end

local function CreateIcon(
	name,
	size
)

	return New(
		"ImageLabel",
		{

			Name = "Icon",

			Size =
				UDim2.fromOffset(
					size or 18,
					size or 18
				),

			BackgroundTransparency = 1,

			Image =
				GetIcon(name)
				or "",

			ImageColor3 =
				Theme.Icon,

			ImageTransparency = 0,

			ScaleType =
				Enum.ScaleType.Fit,

		}
	)
end

------------------------------------------------------------
-- CLASSES
------------------------------------------------------------

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

------------------------------------------------------------
-- TAG
------------------------------------------------------------

local function CreateTag(
	window,
	data
)

	local text

	if typeof(data) == "table" then

		text =
			data.Text
			or data.Name
			or "Tag"

	else

		text =
			tostring(data)

	end

	return New(
		"Frame",
		{

			Name = "Tag",

			AutomaticSize =
				Enum.AutomaticSize.X,

			Size =
				UDim2.fromOffset(
					0,
					22
				),

			BackgroundColor3 =
				Theme.Tag,

			BackgroundTransparency =
				0.92,

			BorderSizePixel = 0,

			Parent =
				window.TagContainer,

		},
		{

			New(
				"UICorner",
				{

					CornerRadius =
						UDim.new(
							0,
							6
						),

				}
			),

			New(
				"UIStroke",
				{

					Color =
						Theme.Stroke,

					Transparency =
						0.91,

					Thickness = 1,

				}
			),

			New(
				"UIPadding",
				{

					PaddingLeft =
						UDim.new(
							0,
							7
						),

					PaddingRight =
						UDim.new(
							0,
							7
						),

				}
			),

			New(
				"TextLabel",
				{

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

					Text = text,

					TextColor3 =
						Theme.TagText,

					TextSize = 11,

					Font =
						Enum.Font.GothamMedium,

				}
			),

		}
	)
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

	local button =
		New(
			"ImageButton",
			{

				Name = name,

				Size =
					UDim2.fromOffset(
						30,
						30
					),

				BackgroundColor3 =
					isClose
					and Theme.Close
					or Theme.SidebarHover,

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				AutoButtonColor = false,

				Image = "",

				ZIndex = 20,

			},
			{

				New(
					"UICorner",
					{

						CornerRadius =
							UDim.new(
								0,
								7
							),

					}
				),

			}
		)

	local icon =
		CreateIcon(
			iconName,
			16
		)

	icon.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	icon.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	icon.ZIndex = 21

	icon.Parent =
		button

	AddConnection(
		window,

		button.MouseEnter:Connect(
			function()

				Tween(
					button,
					0.15,
					{

						BackgroundTransparency =
							isClose
							and 0.80
							or 0.93,

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

			end
		)
	)

	AddConnection(
		window,

		button.MouseLeave:Connect(
			function()

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

						ImageColor3 =
							Theme.Icon,

					}
				)

			end
		)
	)

	return button, icon
end

------------------------------------------------------------
-- WINDOW CONSTRUCTOR
------------------------------------------------------------

function Window.new(config)

	config =
		config or {}

	local self =
		setmetatable(
			{},
			Window
		)

	--------------------------------------------------------
	-- CONFIG
	--------------------------------------------------------

	self.Title =
		config.Title
		or Defaults.Title

	self.Version =
		config.Version
		or Defaults.Version

	self.Icon =
		config.Icon
		or Defaults.Icon

	self.Tags =
		config.Tags
		or {}

	self.Size =
		config.Size
		or Defaults.Size

	self.MinSize =
		config.MinSize
		or Defaults.MinSize

	self.MaxSize =
		config.MaxSize
		or Defaults.MaxSize

	self.Position =
		config.Position
		or Defaults.Position

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

	self.Draggable =
		config.Draggable
		~= false

	self.Resizable =
		config.Resizable
		~= false

	self.SidebarCollapsed = false

	self.Minimized = false

	self.Maximized = false

	self.Closed = false

	self.Tabs = {}

	self.SelectedTab = nil

	self._Connections = {}

	--------------------------------------------------------
	-- SCREEN GUI
	--------------------------------------------------------

	local screenGui =
		New(
			"ScreenGui",
			{

				Name =
					"Pebble_"
					.. tostring(
						math.random(
							100000,
							999999
						)
					),

				ResetOnSpawn = false,

				IgnoreGuiInset = false,

				ZIndexBehavior =
					Enum.ZIndexBehavior.Sibling,

				DisplayOrder = 999999,

			}
		)

	screenGui.Parent =
		GetGuiParent()

	self.ScreenGui =
		screenGui

	--------------------------------------------------------
	-- WINDOW CONTAINER
	--------------------------------------------------------

	local main =
		New(
			"Frame",
			{

				Name = "Window",

				Size =
					self.Size,

				Position =
					self.Position,

				AnchorPoint =
					Vector2.new(
						0.5,
						0.5
					),

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				Parent =
					screenGui,

			}
		)

	self.Main =
		main

	--------------------------------------------------------
	-- WINDOW SURFACE
	--------------------------------------------------------

	local surface =
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
					0.08,

				BorderSizePixel = 0,

				ClipsDescendants = true,

				ZIndex = 1,

				Parent =
					main,

			},
			{

				New(
					"UICorner",
					{

						CornerRadius =
							UDim.new(
								0,
								self.CornerRadius
							),

					}
				),

				New(
					"UIStroke",
					{

						Color =
							Theme.Stroke,

						Transparency =
							0.87,

						Thickness = 1,

					}
				),

				New(
					"UIGradient",
					{

						Rotation = 110,

						Color =
							ColorSequence.new(
								{

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

								}
							),

					}
				),

			}
		)

	self.Surface =
		surface

	--------------------------------------------------------
	-- TOPBAR
	--------------------------------------------------------

	local topbar =
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

				BorderSizePixel = 0,

				Active = true,

				ZIndex = 10,

				Parent =
					main,

			}
		)

	self.Topbar =
		topbar

	--------------------------------------------------------
	-- APP ICON
	--------------------------------------------------------

	local appIcon =
		CreateIcon(
			self.Icon,
			20
		)

	appIcon.Name =
		"AppIcon"

	appIcon.AnchorPoint =
		Vector2.new(
			0,
			0.5
		)

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

	appIcon.Parent =
		topbar

	self.IconImage =
		appIcon

	--------------------------------------------------------
	-- HEADER
	--------------------------------------------------------

	local header =
		New(
			"Frame",
			{

				Name = "Header",

				Position =
					UDim2.fromOffset(
						48,
						0
					),

				Size =
					UDim2.new(
						1,
						-230,
						1,
						0
					),

				BackgroundTransparency = 1,

				ZIndex = 12,

				Parent =
					topbar,

			}
		)

	self.Header =
		header

	--------------------------------------------------------
	-- TITLE
	--------------------------------------------------------

	local title =
		New(
			"TextLabel",
			{

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
					self.Title,

				TextColor3 =
					Theme.Text,

				TextSize = 15,

				Font =
					Enum.Font.GothamSemibold,

				ZIndex = 13,

				Parent =
					header,

			}
		)

	self.TitleLabel =
		title

	--------------------------------------------------------
	-- VERSION
	--------------------------------------------------------

	local version =
		New(
			"TextLabel",
			{

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
					self.Version,

				TextColor3 =
					Theme.SubText,

				TextSize = 11,

				Font =
					Enum.Font.GothamMedium,

				ZIndex = 13,

				Parent =
					header,

			}
		)

	self.VersionLabel =
		version

	--------------------------------------------------------
	-- TAGS
	--------------------------------------------------------

	local tagContainer =
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

				ZIndex = 13,

				Parent =
					header,

			},
			{

				New(
					"UIListLayout",
					{

						FillDirection =
							Enum.FillDirection.Horizontal,

						VerticalAlignment =
							Enum.VerticalAlignment.Center,

						Padding =
							UDim.new(
								0,
								5
							),

					}
				),

			}
		)

	self.TagContainer =
		tagContainer

	--------------------------------------------------------
	-- HEADER POSITION UPDATE
	--------------------------------------------------------

	local function UpdateHeader()

		task.defer(
			function()

				if not title.Parent then
					return
				end

				version.Position =
					UDim2.new(
						0,
						title.TextBounds.X
							+ 8,
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

			end
		)

	end

	self._UpdateHeader =
		UpdateHeader

	AddConnection(
		self,

		title:GetPropertyChangedSignal(
			"TextBounds"
		):Connect(
			UpdateHeader
		)
	)

	AddConnection(
		self,

		version:GetPropertyChangedSignal(
			"TextBounds"
		):Connect(
			UpdateHeader
		)
	)

	--------------------------------------------------------
	-- WINDOW CONTROLS
	--------------------------------------------------------

	local controls =
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

				ZIndex = 20,

				Parent =
					topbar,

			},
			{

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
								3
							),

					}
				),

			}
		)

	self.Controls =
		controls

	--------------------------------------------------------
	-- SIDEBAR TOGGLE
	--------------------------------------------------------

	local sidebarButton,
		sidebarButtonIcon =
			CreateControlButton(
				self,
				"SidebarToggle",
				"panel-left-close",
				false
			)

	sidebarButton.Parent =
		controls

	self.SidebarButton =
		sidebarButton

	self.SidebarButtonIcon =
		sidebarButtonIcon

	--------------------------------------------------------
	-- MINIMIZE
	--------------------------------------------------------

	local minimizeButton =
		CreateControlButton(
			self,
			"Minimize",
			"minus",
			false
		)

	minimizeButton.Parent =
		controls

	--------------------------------------------------------
	-- MAXIMIZE
	--------------------------------------------------------

	local maximizeButton =
		CreateControlButton(
			self,
			"Maximize",
			"square",
			false
		)

	maximizeButton.Parent =
		controls

	--------------------------------------------------------
	-- CLOSE
	--------------------------------------------------------

	local closeButton =
		CreateControlButton(
			self,
			"Close",
			"x",
			true
		)

	closeButton.Parent =
		controls

	self.MinimizeButton =
		minimizeButton

	self.MaximizeButton =
		maximizeButton

	self.CloseButton =
		closeButton

	--------------------------------------------------------
	-- SIDEBAR
	--------------------------------------------------------

	local sidebar =
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

				BackgroundColor3 =
					Theme.Sidebar,

				BackgroundTransparency =
					0.30,

				BorderSizePixel = 0,

				ClipsDescendants = true,

				ZIndex = 6,

				Parent =
					main,

			}
		)

	self.Sidebar =
		sidebar

	--------------------------------------------------------
	-- SIDEBAR RIGHT BORDER
	--------------------------------------------------------

	local sidebarBorder =
		New(
			"Frame",
			{

				Name = "SidebarBorder",

				Size =
					UDim2.new(
						0,
						1,
						1,
						-20
					),

				AnchorPoint =
					Vector2.new(
						1,
						0.5
					),

				Position =
					UDim2.new(
						1,
						0,
						0.5,
						0
					),

				BackgroundColor3 =
					Theme.Stroke,

				BackgroundTransparency =
					0.94,

				BorderSizePixel = 0,

				ZIndex = 7,

				Parent =
					sidebar,

			}
		)

	self.SidebarBorder =
		sidebarBorder

	--------------------------------------------------------
	-- TAB SCROLLER
	--------------------------------------------------------

	local tabScroller =
		New(
			"ScrollingFrame",
			{

				Name = "Tabs",

				Position =
					UDim2.fromOffset(
						8,
						10
					),

				Size =
					UDim2.new(
						1,
						-16,
						1,
						-94
					),

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				CanvasSize =
					UDim2.new(),

				AutomaticCanvasSize =
					Enum.AutomaticSize.Y,

				ScrollBarThickness = 2,

				ScrollBarImageColor3 =
					Theme.SubText,

				ScrollBarImageTransparency =
					0.6,

				ZIndex = 8,

				Parent =
					sidebar,

			},
			{

				New(
					"UIListLayout",
					{

						FillDirection =
							Enum.FillDirection.Vertical,

						HorizontalAlignment =
							Enum.HorizontalAlignment.Left,

						SortOrder =
							Enum.SortOrder.LayoutOrder,

						Padding =
							UDim.new(
								0,
								4
							),

					}
				),

			}
		)

	self.TabScroller =
		tabScroller

	--------------------------------------------------------
	-- USER PANEL
	--------------------------------------------------------

	local userPanel =
		New(
			"Frame",
			{

				Name = "UserPanel",

				Size =
					UDim2.new(
						1,
						-16,
						0,
						64
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
						-10
					),

				BackgroundColor3 =
					Theme.UserBackground,

				BackgroundTransparency =
					0.95,

				BorderSizePixel = 0,

				ClipsDescendants = true,

				ZIndex = 9,

				Parent =
					sidebar,

			},
			{

				New(
					"UICorner",
					{

						CornerRadius =
							UDim.new(
								0,
								9
							),

					}
				),

				New(
					"UIStroke",
					{

						Color =
							Theme.Stroke,

						Transparency =
							0.91,

						Thickness = 1,

					}
				),

			}
		)

	self.UserPanel =
		userPanel

	--------------------------------------------------------
	-- HEADSHOT
	--------------------------------------------------------

	local headshot =
		New(
			"ImageLabel",
			{

				Name = "Headshot",

				Size =
					UDim2.fromOffset(
						38,
						38
					),

				AnchorPoint =
					Vector2.new(
						0,
						0.5
					),

				Position =
					UDim2.new(
						0,
						10,
						0.5,
						0
					),

				BackgroundColor3 =
					Theme.Background,

				BackgroundTransparency =
					0.15,

				BorderSizePixel = 0,

				Image = "",

				ZIndex = 10,

				Parent =
					userPanel,

			},
			{

				New(
					"UICorner",
					{

						CornerRadius =
							UDim.new(
								1,
								0
							),

					}
				),

			}
		)

	self.UserHeadshot =
		headshot

	--------------------------------------------------------
	-- USER INFO
	--------------------------------------------------------

	local displayName =
		New(
			"TextLabel",
			{

				Name = "DisplayName",

				Position =
					UDim2.fromOffset(
						58,
						13
					),

				Size =
					UDim2.new(
						1,
						-68,
						0,
						18
					),

				BackgroundTransparency = 1,

				Text =
					LocalPlayer
					and LocalPlayer.DisplayName
					or "Player",

				TextColor3 =
					Theme.Text,

				TextSize = 13,

				Font =
					Enum.Font.GothamSemibold,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				TextTruncate =
					Enum.TextTruncate.AtEnd,

				ZIndex = 10,

				Parent =
					userPanel,

			}
		)

	local username =
		New(
			"TextLabel",
			{

				Name = "Username",

				Position =
					UDim2.fromOffset(
						58,
						32
					),

				Size =
					UDim2.new(
						1,
						-68,
						0,
						16
					),

				BackgroundTransparency = 1,

				Text =
					LocalPlayer
					and ("@" .. LocalPlayer.Name)
					or "@Player",

				TextColor3 =
					Theme.SubText,

				TextSize = 11,

				Font =
					Enum.Font.Gotham,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				TextTruncate =
					Enum.TextTruncate.AtEnd,

				ZIndex = 10,

				Parent =
					userPanel,

			}
		)

	self.UserDisplayName =
		displayName

	self.UserUsername =
		username

	--------------------------------------------------------
	-- LOAD HEADSHOT
	--------------------------------------------------------

	if LocalPlayer then

		task.spawn(
			function()

				local success, image =
					pcall(
						function()

							return Players:GetUserThumbnailAsync(
								LocalPlayer.UserId,

								Enum.ThumbnailType.HeadShot,

								Enum.ThumbnailSize.Size150x150
							)

						end
					)

				if success
					and self.UserHeadshot
				then

					self.UserHeadshot.Image =
						image

				end

			end
		)

	end

	--------------------------------------------------------
	-- CONTENT HOLDER
	--------------------------------------------------------

	local contentHolder =
		New(
			"Frame",
			{

				Name = "ContentHolder",

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

				BorderSizePixel = 0,

				ClipsDescendants = true,

				ZIndex = 5,

				Parent =
					main,

			}
		)

	self.Content =
		contentHolder

	self.ContentHolder =
		contentHolder

	--------------------------------------------------------
	-- TAGS
	--------------------------------------------------------

	self:SetTags(
		self.Tags
	)

	UpdateHeader()

	--------------------------------------------------------
	-- BUTTONS
	--------------------------------------------------------

	AddConnection(
		self,

		sidebarButton.MouseButton1Click:Connect(
			function()

				self:ToggleSidebar()

			end
		)
	)

	AddConnection(
		self,

		minimizeButton.MouseButton1Click:Connect(
			function()

				self:ToggleMinimize()

			end
		)
	)

	AddConnection(
		self,

		maximizeButton.MouseButton1Click:Connect(
			function()

				self:ToggleMaximize()

			end
		)
	)

	AddConnection(
		self,

		closeButton.MouseButton1Click:Connect(
			function()

				self:Close()

			end
		)
	)

	--------------------------------------------------------
	-- INTERACTION
	--------------------------------------------------------

	self:_SetupDrag()

	if self.Resizable then

		self:_SetupResize()

	end

	--------------------------------------------------------
	-- INTRO
	--------------------------------------------------------

	local normalSize =
		main.Size

	main.Size =
		UDim2.new(
			normalSize.X.Scale,
			normalSize.X.Offset - 12,

			normalSize.Y.Scale,
			normalSize.Y.Offset - 12
		)

	Tween(
		main,
		0.28,
		{

			Size =
				normalSize,

		}
	)

	return self
end

------------------------------------------------------------
-- SIDEBAR TOGGLE
------------------------------------------------------------

function Window:ToggleSidebar()

	self.SidebarCollapsed =
		not self.SidebarCollapsed

	local targetWidth =
		self.SidebarCollapsed
		and self.CollapsedSidebarWidth
		or self.SidebarWidth

	--------------------------------------------------------
	-- SIDEBAR
	--------------------------------------------------------

	Tween(
		self.Sidebar,
		0.32,
		{

			Size =
				UDim2.new(
					0,
					targetWidth,
					1,
					-self.TopbarHeight
				),

		}
	)

	--------------------------------------------------------
	-- CONTENT
	--------------------------------------------------------

	Tween(
		self.ContentHolder,
		0.32,
		{

			Position =
				UDim2.fromOffset(
					targetWidth,
					self.TopbarHeight
				),

			Size =
				UDim2.new(
					1,
					-targetWidth,
					1,
					-self.TopbarHeight
				),

		}
	)

	--------------------------------------------------------
	-- USER CARD
	--------------------------------------------------------

	if self.SidebarCollapsed then

		Tween(
			self.UserDisplayName,
			0.15,
			{

				TextTransparency = 1,

			}
		)

		Tween(
			self.UserUsername,
			0.15,
			{

				TextTransparency = 1,

			}
		)

		Tween(
			self.UserHeadshot,
			0.32,
			{

				Position =
					UDim2.new(
						0.5,
						-19,
						0.5,
						0
					),

			}
		)

	else

		Tween(
			self.UserHeadshot,
			0.32,
			{

				Position =
					UDim2.new(
						0,
						10,
						0.5,
						0
					),

			}
		)

		task.delay(
			0.12,
			function()

				if self.Closed then
					return
				end

				Tween(
					self.UserDisplayName,
					0.18,
					{

						TextTransparency = 0,

					}
				)

				Tween(
					self.UserUsername,
					0.18,
					{

						TextTransparency = 0,

					}
				)

			end
		)

	end

	--------------------------------------------------------
	-- TAB LABELS
	--------------------------------------------------------

	for _, tab in ipairs(
		self.Tabs
	) do

		if tab.TitleLabel then

			Tween(
				tab.TitleLabel,
				0.18,
				{

					TextTransparency =
						self.SidebarCollapsed
						and 1
						or 0,

				}
			)

		end

		if tab.LockIcon then

			Tween(
				tab.LockIcon,
				0.18,
				{

					ImageTransparency =
						self.SidebarCollapsed
						and 1
						or 0,

				}
			)

		end

	end

	--------------------------------------------------------
	-- TOGGLE ICON
	--------------------------------------------------------

	local icon =
		self.SidebarCollapsed
		and GetIcon("panel-left-open")
		or GetIcon("panel-left-close")

	if icon then

		self.SidebarButtonIcon.Image =
			icon

	end

	return self
end

------------------------------------------------------------
-- TAB
------------------------------------------------------------

function Window:Tab(config)

	config =
		config or {}

	local title =
		config.Title
		or "Tab"

	local iconName =
		config.Icon

	local locked =
		config.Locked
		== true

	local tab =
		setmetatable(
			{},
			Tab
		)

	tab.Window =
		self

	tab.Title =
		title

	tab.Icon =
		iconName

	tab.Locked =
		locked

	tab.Selected =
		false

	--------------------------------------------------------
	-- BUTTON
	--------------------------------------------------------

	local button =
		New(
			"TextButton",
			{

				Name =
					"Tab_"
					.. title,

				Size =
					UDim2.new(
						1,
						0,
						0,
						38
					),

				BackgroundColor3 =
					Theme.SidebarSelected,

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				AutoButtonColor = false,

				Text = "",

				ZIndex = 10,

				Parent =
					self.TabScroller,

			},
			{

				New(
					"UICorner",
					{

						CornerRadius =
							UDim.new(
								0,
								8
							),

					}
				),

			}
		)

	tab.Button =
		button

	--------------------------------------------------------
	-- ACCENT
	--------------------------------------------------------

	local accent =
		New(
			"Frame",
			{

				Name = "Accent",

				Size =
					UDim2.new(
						0,
						3,
						0,
						20
					),

				AnchorPoint =
					Vector2.new(
						1,
						0.5
					),

				Position =
					UDim2.new(
						1,
						-3,
						0.5,
						0
					),

				BackgroundColor3 =
					Theme.AccentBright,

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				ZIndex = 12,

				Parent =
					button,

			},
			{

				New(
					"UICorner",
					{

						CornerRadius =
							UDim.new(
								1,
								0
							),

					}
				),

			}
		)

	tab.Accent =
		accent

	--------------------------------------------------------
	-- ICON
	--------------------------------------------------------

	local tabIcon

	if iconName then

		tabIcon =
			CreateIcon(
				iconName,
				17
			)

	else

		tabIcon =
			CreateIcon(
				"circle",
				17
			)

	end

	tabIcon.AnchorPoint =
		Vector2.new(
			0,
			0.5
		)

	tabIcon.Position =
		UDim2.new(
			0,
			13,
			0.5,
			0
		)

	tabIcon.ZIndex = 12

	tabIcon.Parent =
		button

	tab.IconImage =
		tabIcon

	--------------------------------------------------------
	-- TITLE
	--------------------------------------------------------

	local titleLabel =
		New(
			"TextLabel",
			{

				Name = "Title",

				Position =
					UDim2.fromOffset(
						40,
						0
					),

				Size =
					UDim2.new(
						1,
						-70,
						1,
						0
					),

				BackgroundTransparency = 1,

				Text =
					title,

				TextColor3 =
					Theme.SubText,

				TextSize = 12,

				Font =
					Enum.Font.GothamMedium,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				TextTruncate =
					Enum.TextTruncate.AtEnd,

				ZIndex = 12,

				Parent =
					button,

			}
		)

	tab.TitleLabel =
		titleLabel

	--------------------------------------------------------
	-- LOCK ICON
	--------------------------------------------------------

	if locked then

		local lockIcon =
			CreateIcon(
				"lock",
				13
			)

		lockIcon.AnchorPoint =
			Vector2.new(
				1,
				0.5
			)

		lockIcon.Position =
			UDim2.new(
				1,
				-12,
				0.5,
				0
			)

		lockIcon.ImageColor3 =
			Theme.MutedText

		lockIcon.ZIndex = 12

		lockIcon.Parent =
			button

		tab.LockIcon =
			lockIcon

	end

	--------------------------------------------------------
	-- CONTENT PAGE
	--------------------------------------------------------

	local page =
		New(
			"ScrollingFrame",
			{

				Name =
					"Page_"
					.. title,

				Size =
					UDim2.fromScale(
						1,
						1
					),

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				Visible = false,

				CanvasSize =
					UDim2.new(),

				AutomaticCanvasSize =
					Enum.AutomaticSize.Y,

				ScrollBarThickness = 3,

				ScrollBarImageColor3 =
					Theme.SubText,

				ScrollBarImageTransparency =
					0.55,

				ZIndex = 6,

				Parent =
					self.ContentHolder,

			},
			{

				New(
					"UIPadding",
					{

						PaddingTop =
							UDim.new(
								0,
								18
							),

						PaddingBottom =
							UDim.new(
								0,
								18
							),

						PaddingLeft =
							UDim.new(
								0,
								18
							),

						PaddingRight =
							UDim.new(
								0,
								18
							),

					}
				),

				New(
					"UIListLayout",
					{

						FillDirection =
							Enum.FillDirection.Vertical,

						HorizontalAlignment =
							Enum.HorizontalAlignment.Left,

						SortOrder =
							Enum.SortOrder.LayoutOrder,

						Padding =
							UDim.new(
								0,
								8
							),

					}
				),

			}
		)

	tab.Container =
		page

	tab.Page =
		page

	--------------------------------------------------------
	-- EVENTS
	--------------------------------------------------------

	AddConnection(
		self,

		button.MouseEnter:Connect(
			function()

				if tab.Selected then
					return
				end

				Tween(
					button,
					0.14,
					{

						BackgroundTransparency =
							0.95,

					}
				)

				Tween(
					titleLabel,
					0.14,
					{

						TextColor3 =
							Theme.Text,

					}
				)

				Tween(
					tabIcon,
					0.14,
					{

						ImageColor3 =
							Theme.Text,

					}
				)

			end
		)
	)

	AddConnection(
		self,

		button.MouseLeave:Connect(
			function()

				if tab.Selected then
					return
				end

				Tween(
					button,
					0.14,
					{

						BackgroundTransparency = 1,

					}
				)

				Tween(
					titleLabel,
					0.14,
					{

						TextColor3 =
							Theme.SubText,

					}
				)

				Tween(
					tabIcon,
					0.14,
					{

						ImageColor3 =
							Theme.Icon,

					}
				)

			end
		)
	)

	AddConnection(
		self,

		button.MouseButton1Click:Connect(
			function()

				if tab.Locked then
					return
				end

				tab:Select()

			end
		)
	)

	table.insert(
		self.Tabs,
		tab
	)

	--------------------------------------------------------
	-- FIRST TAB
	--------------------------------------------------------

	if not self.SelectedTab
		and not tab.Locked
	then

		tab:Select()

	end

	return tab
end

------------------------------------------------------------
-- SELECT TAB
------------------------------------------------------------

function Tab:Select()

	if self.Locked then
		return self
	end

	local window =
		self.Window

	if window.SelectedTab == self then
		return self
	end

	--------------------------------------------------------
	-- OLD TAB
	--------------------------------------------------------

	if window.SelectedTab then

		local old =
			window.SelectedTab

		old.Selected =
			false

		old.Container.Visible =
			false

		Tween(
			old.Button,
			0.20,
			{

				BackgroundTransparency = 1,

			}
		)

		Tween(
			old.Accent,
			0.20,
			{

				BackgroundTransparency = 1,

			}
		)

		Tween(
			old.IconImage,
			0.20,
			{

				ImageColor3 =
					Theme.Icon,

			}
		)

		Tween(
			old.TitleLabel,
			0.20,
			{

				TextColor3 =
					Theme.SubText,

			}
		)

	end

	--------------------------------------------------------
	-- NEW TAB
	--------------------------------------------------------

	window.SelectedTab =
		self

	self.Selected =
		true

	self.Container.Visible =
		true

	Tween(
		self.Button,
		0.22,
		{

			BackgroundTransparency =
				0.91,

		}
	)

	Tween(
		self.Accent,
		0.22,
		{

			BackgroundTransparency = 0,

		}
	)

	Tween(
		self.IconImage,
		0.22,
		{

			ImageColor3 =
				Theme.IconSelected,

		}
	)

	Tween(
		self.TitleLabel,
		0.22,
		{

			TextColor3 =
				Theme.Text,

		}
	)

	return self
end

------------------------------------------------------------
-- TAB DIVIDER
------------------------------------------------------------

function Tab:Divider()

	local divider =
		New(
			"Frame",
			{

				Name = "Divider",

				Size =
					UDim2.new(
						1,
						0,
						0,
						19
					),

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				LayoutOrder =
					#self.Window.Tabs
					+ 1000,

				Parent =
					self.Window.TabScroller,

			}
		)

	local line =
		New(
			"Frame",
			{

				Name = "Line",

				Size =
					UDim2.new(
						1,
						-12,
						0,
						1
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

				BackgroundColor3 =
					Theme.Stroke,

				BackgroundTransparency =
					0.93,

				BorderSizePixel = 0,

				Parent =
					divider,

			}
		)

	return divider
end

------------------------------------------------------------
-- TITLE / VERSION / TAGS
------------------------------------------------------------

function Window:SetTitle(value)

	self.Title =
		tostring(value)

	self.TitleLabel.Text =
		self.Title

	self._UpdateHeader()

	return self
end

function Window:SetVersion(value)

	self.Version =
		tostring(value)

	self.VersionLabel.Text =
		self.Version

	self._UpdateHeader()

	return self
end

function Window:SetIcon(name)

	self.Icon =
		name

	local image =
		GetIcon(name)

	if not image then

		self.IconImage.Visible =
			false

		return self

	end

	self.IconImage.Visible =
		true

	self.IconImage.Image =
		image

	return self
end

function Window:SetTags(tags)

	self.Tags =
		tags or {}

	for _, child in ipairs(
		self.TagContainer:GetChildren()
	) do

		if child:IsA("Frame") then

			child:Destroy()

		end

	end

	for _, tag in ipairs(
		self.Tags
	) do

		CreateTag(
			self,
			tag
		)

	end

	self._UpdateHeader()

	return self
end

function Window:AddTag(tag)

	table.insert(
		self.Tags,
		tag
	)

	CreateTag(
		self,
		tag
	)

	self._UpdateHeader()

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

		self.Topbar.InputBegan:Connect(
			function(input)

				if self.Maximized then
					return
				end

				if input.UserInputType
						== Enum.UserInputType.MouseButton1
					or input.UserInputType
						== Enum.UserInputType.Touch
				then

					dragging = true

					dragStart =
						input.Position

					startPosition =
						self.Main.Position

				end

			end
		)
	)

	AddConnection(
		self,

		UserInputService.InputChanged:Connect(
			function(input)

				if not dragging then
					return
				end

				if input.UserInputType
						~= Enum.UserInputType.MouseMovement
					and input.UserInputType
						~= Enum.UserInputType.Touch
				then

					return

				end

				local delta =
					input.Position
					- dragStart

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
		)
	)

	AddConnection(
		self,

		UserInputService.InputEnded:Connect(
			function(input)

				if input.UserInputType
						== Enum.UserInputType.MouseButton1
					or input.UserInputType
						== Enum.UserInputType.Touch
				then

					dragging = false

				end

			end
		)
	)

end

------------------------------------------------------------
-- RESIZE
------------------------------------------------------------

function Window:_SetupResize()

	local handle =
		New(
			"ImageButton",
			{

				Name = "ResizeHandle",

				Size =
					UDim2.fromOffset(
						22,
						22
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

				Image = "",

				AutoButtonColor = false,

				ZIndex = 50,

				Parent =
					self.Main,

			}
		)

	self.ResizeHandle =
		handle

	local resizing = false

	local startMouse

	local startSize

	AddConnection(
		self,

		handle.InputBegan:Connect(
			function(input)

				if self.Maximized
					or self.Minimized
				then

					return

				end

				if input.UserInputType
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
	)

	AddConnection(
		self,

		UserInputService.InputChanged:Connect(
			function(input)

				if not resizing then
					return
				end

				if input.UserInputType
						~= Enum.UserInputType.MouseMovement
					and input.UserInputType
						~= Enum.UserInputType.Touch
				then

					return

				end

				local delta =
					input.Position
					- startMouse

				local width =
					math.clamp(
						startSize.X
							+ delta.X,

						self.MinSize.X,

						self.MaxSize.X
					)

				local height =
					math.clamp(
						startSize.Y
							+ delta.Y,

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
	)

	AddConnection(
		self,

		UserInputService.InputEnded:Connect(
			function(input)

				if input.UserInputType
						== Enum.UserInputType.MouseButton1
					or input.UserInputType
						== Enum.UserInputType.Touch
				then

					resizing = false

				end

			end
		)
	)

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

		self.Sidebar.Visible =
			false

		self.ContentHolder.Visible =
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
					),

			}
		)

	else

		self.Sidebar.Visible =
			true

		self.ContentHolder.Visible =
			true

		if self.ResizeHandle then

			self.ResizeHandle.Visible =
				true

		end

		Tween(
			self.Main,
			0.30,
			{

				Size =
					self._MinimizedSize
					or self.Size,

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

		self._RestoreAnchor =
			self.Main.AnchorPoint

		if self.ResizeHandle then

			self.ResizeHandle.Visible =
				false

		end

		self.Main.AnchorPoint =
			Vector2.new(
				0,
				0
			)

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

			self.ResizeHandle.Visible =
				true

		end

		self.Main.AnchorPoint =
			self._RestoreAnchor
			or Vector2.new(
				0.5,
				0.5
			)

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
-- SHOW / HIDE
------------------------------------------------------------

function Window:SetVisible(value)

	self.ScreenGui.Enabled =
		value == true

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

	self.Closed =
		true

	local currentSize =
		self.Main.Size

	Tween(
		self.Main,
		0.18,
		{

			Size =
				UDim2.new(
					currentSize.X.Scale,

					currentSize.X.Offset
						- 12,

					currentSize.Y.Scale,

					currentSize.Y.Offset
						- 12
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

	task.delay(
		0.19,
		function()

			self:Destroy()

		end
	)

end

------------------------------------------------------------
-- DESTROY
------------------------------------------------------------

function Window:Destroy()

	for _, connection in ipairs(
		self._Connections
	) do

		pcall(
			function()

				connection:Disconnect()

			end
		)

	end

	table.clear(
		self._Connections
	)

	if self.ScreenGui then

		self.ScreenGui:Destroy()

		self.ScreenGui = nil

	end

	self.Closed =
		true

end

------------------------------------------------------------
-- API
------------------------------------------------------------

function Pebble:CreateWindow(config)

	return Window.new(
		config
	)

end

function Pebble.new(config)

	return Window.new(
		config
	)

end

Pebble.Window =
	Window

Pebble.Tab =
	Tab

Pebble.Theme =
	Theme

Pebble.Icons =
	LucideIcons

return Pebble
