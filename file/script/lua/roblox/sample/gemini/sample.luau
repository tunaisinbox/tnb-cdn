-- StarterPlayerScripts / LocalScript (MenuController)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local SocialService = game:GetService("SocialService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- RemoteEventの待機・取得
local reportEvent = ReplicatedStorage:WaitForChild("ReportPlayerEvent", 10)

---------------------------------------------------------
-- TopbarPlus モジュール読み込み
---------------------------------------------------------
local ref = ReplicatedStorage:WaitForChild("TopbarPlusReference", 10)
local iconModule = (ref and ref:IsA("ObjectValue") and ref.Value) or ReplicatedStorage:FindFirstChild("Icon", true)
local Icon = require(iconModule)

for _, existingIcon in ipairs(Icon.getIcons()) do
	existingIcon:destroy()
end

---------------------------------------------------------
-- 状態管理
---------------------------------------------------------
local isMenuOpen = false
local currentTab = "Players"
local targetReportPlayer = nil

---------------------------------------------------------
-- プレイヤー移動・ジャンプ・視点ロック制御
---------------------------------------------------------
local playerModuleScript = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 10)
local controls = nil
if playerModuleScript then
	local success, pm = pcall(function()
		return require(playerModuleScript)
	end)
	if success and pm and pm.GetControls then
		controls = pm:GetControls()
	end
end

local savedCameraType = camera.CameraType

local function setPlayerFrozen(frozen)
	if controls then
		if frozen then
			controls:Disable()
		else
			controls:Enable()
		end
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if frozen then
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				humanoid.JumpHeight = 0
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			else
				humanoid.WalkSpeed = 16
				humanoid.JumpPower = 50
				humanoid.JumpHeight = 7.2
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			end
		end
	end

	if frozen then
		savedCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		camera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

---------------------------------------------------------
-- 白枠線付きキーバッジヘルパー関数
---------------------------------------------------------
local function createKeyBadge(keyText, parent)
	local badge = Instance.new("Frame")
	badge.Name = "KeyBadge"
	badge.Size = UDim2.new(0, 34, 0, 26)
	badge.Position = UDim2.new(0, 8, 0.5, 0)
	badge.AnchorPoint = Vector2.new(0, 0.5)
	badge.BackgroundColor3 = Color3.fromRGB(35, 42, 54)
	badge.BackgroundTransparency = 0.2
	badge.BorderSizePixel = 1
	badge.BorderColor3 = Color3.fromRGB(255, 255, 255)
	badge.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = keyText
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.BuilderSansBold
	label.Parent = badge

	return badge
end

---------------------------------------------------------
-- UI全体構造
---------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RobloxCustomEscMenu"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
mainFrame.Position = UDim2.new(0.5, 0, -0.6, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 46, 56)
mainFrame.BackgroundTransparency = 1
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainSizeConstraint = Instance.new("UISizeConstraint")
mainSizeConstraint.MaxSize = Vector2.new(680, 460)
mainSizeConstraint.MinSize = Vector2.new(280, 250)
mainSizeConstraint.Parent = mainFrame

---------------------------------------------------------
-- 確認用ダイアログ
---------------------------------------------------------
local confirmOverlay = Instance.new("Frame")
confirmOverlay.Name = "ConfirmOverlay"
confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
confirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.7
confirmOverlay.Visible = false
confirmOverlay.ZIndex = 50
confirmOverlay.Parent = screenGui

local confirmBox = Instance.new("Frame")
confirmBox.Size = UDim2.new(0.9, 0, 0.85, 0)
confirmBox.Position = UDim2.new(0.5, 0, 0.5, 0)
confirmBox.AnchorPoint = Vector2.new(0.5, 0.5)
confirmBox.BackgroundColor3 = Color3.fromRGB(35, 42, 52)
confirmBox.BackgroundTransparency = 0.25
confirmBox.BorderSizePixel = 1
confirmBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
confirmBox.ZIndex = 51
confirmBox.Parent = confirmOverlay

local confirmSizeConstraint = Instance.new("UISizeConstraint")
confirmSizeConstraint.MaxSize = Vector2.new(680, 460)
confirmSizeConstraint.MinSize = Vector2.new(280, 250)
confirmSizeConstraint.Parent = confirmBox

local confirmTitleLabel = Instance.new("TextLabel")
confirmTitleLabel.Size = UDim2.new(1, -40, 0, 70)
confirmTitleLabel.Position = UDim2.new(0, 20, 0.4, -50)
confirmTitleLabel.BackgroundTransparency = 1
confirmTitleLabel.Text = "キャラクターをリスポーンしてよろしいですか？"
confirmTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmTitleLabel.TextSize = 18
confirmTitleLabel.Font = Enum.Font.BuilderSansBold
confirmTitleLabel.TextWrapped = true
confirmTitleLabel.ZIndex = 52
confirmTitleLabel.Parent = confirmBox

local confirmOkBtn = Instance.new("TextButton")
confirmOkBtn.Size = UDim2.new(0.35, 0, 0, 44)
confirmOkBtn.Position = UDim2.new(0.12, 0, 0.5, 30)
confirmOkBtn.BackgroundColor3 = Color3.fromRGB(55, 75, 120)
confirmOkBtn.BackgroundTransparency = 0.2
confirmOkBtn.BorderSizePixel = 1
confirmOkBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
confirmOkBtn.Text = ""
confirmOkBtn.ZIndex = 52
confirmOkBtn.Parent = confirmBox

local okBtnText = Instance.new("TextLabel")
okBtnText.Size = UDim2.new(1, 0, 1, 0)
okBtnText.BackgroundTransparency = 1
okBtnText.Text = "リセット"
okBtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
okBtnText.TextSize = 14
okBtnText.Font = Enum.Font.BuilderSansBold
okBtnText.TextXAlignment = Enum.TextXAlignment.Center
okBtnText.ZIndex = 53
okBtnText.Parent = confirmOkBtn

local confirmCancelBtn = Instance.new("TextButton")
confirmCancelBtn.Size = UDim2.new(0.35, 0, 0, 44)
confirmCancelBtn.Position = UDim2.new(0.53, 0, 0.5, 30)
confirmCancelBtn.BackgroundColor3 = Color3.fromRGB(50, 56, 68)
confirmCancelBtn.BackgroundTransparency = 0.2
confirmCancelBtn.BorderSizePixel = 1
confirmCancelBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
confirmCancelBtn.Text = ""
confirmCancelBtn.ZIndex = 52
confirmCancelBtn.Parent = confirmBox

local cancelBtnText = Instance.new("TextLabel")
cancelBtnText.Size = UDim2.new(1, 0, 1, 0)
cancelBtnText.BackgroundTransparency = 1
cancelBtnText.Text = "リセットしない"
cancelBtnText.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtnText.TextSize = 14
cancelBtnText.Font = Enum.Font.BuilderSansBold
cancelBtnText.TextXAlignment = Enum.TextXAlignment.Center
cancelBtnText.ZIndex = 53
cancelBtnText.Parent = confirmCancelBtn

local activeConfirmAction = nil

local function showFullConfirm(message, okText, cancelText, onOk)
	confirmTitleLabel.Text = message
	okBtnText.Text = okText
	cancelBtnText.Text = cancelText
	activeConfirmAction = onOk
	mainFrame.Visible = false
	confirmOverlay.Visible = true
end

local function hideFullConfirm(restoreMain)
	confirmOverlay.Visible = false
	activeConfirmAction = nil
	if restoreMain and isMenuOpen then
		mainFrame.Visible = true
	end
end

confirmCancelBtn.MouseButton1Click:Connect(function()
	hideFullConfirm(true)
end)

confirmOkBtn.MouseButton1Click:Connect(function()
	local action = activeConfirmAction
	hideFullConfirm(false)
	if action then
		action()
	end
end)

---------------------------------------------------------
-- ヘッダータブ & スライド移動インジケーター
---------------------------------------------------------
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, 0, 0, 45)
headerFrame.BackgroundColor3 = Color3.fromRGB(60, 68, 82)
headerFrame.BackgroundTransparency = 0.3
headerFrame.BorderSizePixel = 1
headerFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
headerFrame.Parent = mainFrame

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -20, 1, 0)
tabContainer.Position = UDim2.new(0, 10, 0, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = headerFrame

local tabIndicator = Instance.new("Frame")
tabIndicator.Name = "ActiveIndicator"
tabIndicator.Size = UDim2.new(0.25, 0, 0, 3)
tabIndicator.Position = UDim2.new(0, 0, 1, -3)
tabIndicator.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
tabIndicator.BorderSizePixel = 0
tabIndicator.ZIndex = 5
tabIndicator.Parent = tabContainer

local tabFrames = {}
local tabButtons = {}
local tabList = { "Players", "Settings", "Report", "Help" }
local tabTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function switchTab(tabName)
	currentTab = tabName
	for name, frame in pairs(tabFrames) do
		frame.Visible = (name == tabName)
	end
	for name, btn in pairs(tabButtons) do
		btn.TextColor3 = (name == tabName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 188, 200)
	end

	local index = table.find(tabList, tabName) or 1
	local targetPosition = UDim2.new((index - 1) * 0.25, 0, 1, -3)
	TweenService:Create(tabIndicator, tabTweenInfo, { Position = targetPosition }):Play()
end

for i, name in ipairs(tabList) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.25, 0, 1, 0)
	btn.Position = UDim2.new((i - 1) * 0.25, 0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(180, 188, 200)
	btn.TextSize = 14
	btn.Font = Enum.Font.BuilderSansBold
	btn.Parent = tabContainer

	tabButtons[name] = btn
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

---------------------------------------------------------
-- 1. Players タブ
---------------------------------------------------------
local playersFrame = Instance.new("Frame")
playersFrame.Name = "PlayersFrame"
playersFrame.Size = UDim2.new(1, -20, 1, -110)
playersFrame.Position = UDim2.new(0, 10, 0, 55)
playersFrame.BackgroundTransparency = 1
playersFrame.Parent = mainFrame
tabFrames["Players"] = playersFrame

local inviteBar = Instance.new("TextButton")
inviteBar.Size = UDim2.new(1, 0, 0, 35)
inviteBar.BackgroundColor3 = Color3.fromRGB(55, 62, 75)
inviteBar.BackgroundTransparency = 0.3
inviteBar.BorderSizePixel = 1
inviteBar.BorderColor3 = Color3.fromRGB(255, 255, 255)
inviteBar.Text = "  Invite friends to play"
inviteBar.TextColor3 = Color3.fromRGB(255, 255, 255)
inviteBar.TextSize = 14
inviteBar.Font = Enum.Font.BuilderSansMedium
inviteBar.TextXAlignment = Enum.TextXAlignment.Left
inviteBar.Parent = playersFrame

inviteBar.MouseButton1Click:Connect(function()
	pcall(function()
		SocialService:PromptGameInvite(player)
	end)
end)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, 0, 1, -45)
playerScroll.Position = UDim2.new(0, 0, 0, 45)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 6
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
playerScroll.Parent = playersFrame

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 6)
playerLayout.Parent = playerScroll

---------------------------------------------------------
-- アバター閲覧モーダル
---------------------------------------------------------
local avatarModal = Instance.new("Frame")
avatarModal.Size = UDim2.new(0.85, 0, 0.8, 0)
avatarModal.Position = UDim2.new(0.5, 0, 0.5, 0)
avatarModal.AnchorPoint = Vector2.new(0.5, 0.5)
avatarModal.BackgroundColor3 = Color3.fromRGB(35, 42, 52)
avatarModal.BackgroundTransparency = 0.2
avatarModal.BorderSizePixel = 1
avatarModal.BorderColor3 = Color3.fromRGB(255, 255, 255)
avatarModal.Visible = false
avatarModal.ZIndex = 30
avatarModal.Parent = screenGui

local avatarSizeConstraint = Instance.new("UISizeConstraint")
avatarSizeConstraint.MaxSize = Vector2.new(320, 380)
avatarSizeConstraint.Parent = avatarModal

local avTitle = Instance.new("TextLabel")
avTitle.Size = UDim2.new(1, 0, 0, 40)
avTitle.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
avTitle.BackgroundTransparency = 0.2
avTitle.BorderSizePixel = 0
avTitle.Text = "アバター詳細"
avTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
avTitle.TextSize = 15
avTitle.Font = Enum.Font.BuilderSansBold
avTitle.ZIndex = 31
avTitle.Parent = avatarModal

local avImage = Instance.new("ImageLabel")
avImage.Size = UDim2.new(0, 180, 0, 180)
avImage.Position = UDim2.new(0.5, 0, 0.15, 0)
avImage.AnchorPoint = Vector2.new(0.5, 0)
avImage.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
avImage.BackgroundTransparency = 0.3
avImage.BorderSizePixel = 1
avImage.BorderColor3 = Color3.fromRGB(255, 255, 255)
avImage.ZIndex = 31
avImage.Parent = avatarModal

local avName = Instance.new("TextLabel")
avName.Size = UDim2.new(1, -20, 0, 40)
avName.Position = UDim2.new(0, 10, 0.68, 0)
avName.BackgroundTransparency = 1
avName.TextColor3 = Color3.fromRGB(255, 255, 255)
avName.TextSize = 13
avName.Font = Enum.Font.BuilderSansMedium
avName.ZIndex = 31
avName.Parent = avatarModal

local avCloseBtn = Instance.new("TextButton")
avCloseBtn.Size = UDim2.new(0, 120, 0, 35)
avCloseBtn.Position = UDim2.new(0.5, 0, 0.86, 0)
avCloseBtn.AnchorPoint = Vector2.new(0.5, 0)
avCloseBtn.BackgroundColor3 = Color3.fromRGB(60, 68, 82)
avCloseBtn.BackgroundTransparency = 0.2
avCloseBtn.BorderSizePixel = 1
avCloseBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
avCloseBtn.Text = "閉じる"
avCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
avCloseBtn.Font = Enum.Font.BuilderSansBold
avCloseBtn.ZIndex = 31
avCloseBtn.Parent = avatarModal

avCloseBtn.MouseButton1Click:Connect(function()
	avatarModal.Visible = false
end)

local function openAvatarView(targetP)
	avName.Text = targetP.DisplayName .. "\n(@" .. targetP.Name .. ")"
	avImage.Image = "rbxthumb://type=AvatarBust&id=" .. targetP.UserId .. "&w=420&h=420"
	avatarModal.Visible = true
end

---------------------------------------------------------
-- プレイヤーリスト動的生成
---------------------------------------------------------
local function refreshPlayerList()
	for _, child in ipairs(playerScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 42)
		row.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 1
		row.BorderColor3 = Color3.fromRGB(255, 255, 255)
		row.Parent = playerScroll

		local iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.new(0, 32, 0, 32)
		iconImg.Position = UDim2.new(0, 5, 0.5, 0)
		iconImg.AnchorPoint = Vector2.new(0, 0.5)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150"
		iconImg.Parent = row

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.35, 0, 1, 0)
		nameLbl.Position = UDim2.new(0, 42, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = p.DisplayName .. (p == player and " (自分)" or "")
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextSize = 13
		nameLbl.Font = Enum.Font.BuilderSansMedium
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Parent = row

		if p == player then
			local viewBtn = Instance.new("TextButton")
			viewBtn.Size = UDim2.new(0, 70, 0, 28)
			viewBtn.Position = UDim2.new(1, -75, 0.5, 0)
			viewBtn.AnchorPoint = Vector2.new(0, 0.5)
			viewBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 96)
			viewBtn.BackgroundTransparency = 0.2
			viewBtn.BorderSizePixel = 1
			viewBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
			viewBtn.Text = "View"
			viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			viewBtn.TextSize = 12
			viewBtn.Font = Enum.Font.BuilderSansBold
			viewBtn.Parent = row

			viewBtn.MouseButton1Click:Connect(function()
				openAvatarView(p)
			end)
		else
			local flagBtn = Instance.new("TextButton")
			flagBtn.Size = UDim2.new(0, 50, 0, 28)
			flagBtn.Position = UDim2.new(1, -185, 0.5, 0)
			flagBtn.AnchorPoint = Vector2.new(0, 0.5)
			flagBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 96)
			flagBtn.BackgroundTransparency = 0.2
			flagBtn.BorderSizePixel = 1
			flagBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
			flagBtn.Text = "Report"
			flagBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			flagBtn.TextSize = 10
			flagBtn.Font = Enum.Font.BuilderSansBold
			flagBtn.Parent = row

			flagBtn.MouseButton1Click:Connect(function()
				targetReportPlayer = p
				switchTab("Report")
			end)

			local viewBtn = Instance.new("TextButton")
			viewBtn.Size = UDim2.new(0, 55, 0, 28)
			viewBtn.Position = UDim2.new(1, -130, 0.5, 0)
			viewBtn.AnchorPoint = Vector2.new(0, 0.5)
			viewBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 96)
			viewBtn.BackgroundTransparency = 0.2
			viewBtn.BorderSizePixel = 1
			viewBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
			viewBtn.Text = "View"
			viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			viewBtn.TextSize = 11
			viewBtn.Font = Enum.Font.BuilderSansBold
			viewBtn.Parent = row

			viewBtn.MouseButton1Click:Connect(function()
				openAvatarView(p)
			end)

			local addBtn = Instance.new("TextButton")
			addBtn.Size = UDim2.new(0, 70, 0, 28)
			addBtn.Position = UDim2.new(1, -72, 0.5, 0)
			addBtn.AnchorPoint = Vector2.new(0, 0.5)
			addBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 96)
			addBtn.BackgroundTransparency = 0.2
			addBtn.BorderSizePixel = 1
			addBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
			addBtn.Text = "Add Friend"
			addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			addBtn.TextSize = 10
			addBtn.Font = Enum.Font.BuilderSansBold
			addBtn.Parent = row

			addBtn.MouseButton1Click:Connect(function()
				pcall(function()
					StarterGui:SetCore("PromptSendFriendRequest", p)
				end)
			end)
		end
	end
end

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)
refreshPlayerList()

---------------------------------------------------------
-- 2. Settings タブ
---------------------------------------------------------
local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Size = UDim2.new(1, -20, 1, -110)
settingsFrame.Position = UDim2.new(0, 10, 0, 55)
settingsFrame.BackgroundTransparency = 1
settingsFrame.Visible = false
settingsFrame.Parent = mainFrame
tabFrames["Settings"] = settingsFrame

local noSettingsLabel = Instance.new("TextLabel")
noSettingsLabel.Size = UDim2.new(1, 0, 1, 0)
noSettingsLabel.BackgroundTransparency = 1
noSettingsLabel.Text = "設定はまだ何もありません"
noSettingsLabel.TextColor3 = Color3.fromRGB(200, 210, 225)
noSettingsLabel.TextSize = 15
noSettingsLabel.Font = Enum.Font.BuilderSansMedium
noSettingsLabel.TextXAlignment = Enum.TextXAlignment.Center
noSettingsLabel.TextYAlignment = Enum.TextYAlignment.Center
noSettingsLabel.Parent = settingsFrame

---------------------------------------------------------
-- 3. Report タブ
---------------------------------------------------------
local reportFrame = Instance.new("Frame")
reportFrame.Name = "ReportFrame"
reportFrame.Size = UDim2.new(1, -20, 1, -110)
reportFrame.Position = UDim2.new(0, 10, 0, 55)
reportFrame.BackgroundTransparency = 1
reportFrame.Visible = false
reportFrame.Parent = mainFrame
tabFrames["Report"] = reportFrame

local uLabel = Instance.new("TextLabel")
uLabel.Size = UDim2.new(1, 0, 0, 20)
uLabel.BackgroundTransparency = 1
uLabel.Text = "1. 通報するユーザーを選択:"
uLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
uLabel.TextSize = 13
uLabel.Font = Enum.Font.BuilderSansBold
uLabel.TextXAlignment = Enum.TextXAlignment.Left
uLabel.Parent = reportFrame

local uBtn = Instance.new("TextButton")
uBtn.Size = UDim2.new(1, 0, 0, 35)
uBtn.Position = UDim2.new(0, 0, 0, 22)
uBtn.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
uBtn.BackgroundTransparency = 0.3
uBtn.BorderSizePixel = 1
uBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
uBtn.Text = "  プレイヤーを選択してください"
uBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
uBtn.TextSize = 13
uBtn.Font = Enum.Font.BuilderSansMedium
uBtn.TextXAlignment = Enum.TextXAlignment.Left
uBtn.Parent = reportFrame

local uListFrame = Instance.new("ScrollingFrame")
uListFrame.Size = UDim2.new(1, 0, 0, 120)
uListFrame.Position = UDim2.new(0, 0, 0, 58)
uListFrame.BackgroundColor3 = Color3.fromRGB(35, 42, 52)
uListFrame.BackgroundTransparency = 0.1
uListFrame.BorderSizePixel = 1
uListFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
uListFrame.Visible = false
uListFrame.ZIndex = 5
uListFrame.Parent = reportFrame

local uListLayout = Instance.new("UIListLayout")
uListLayout.Parent = uListFrame

local selectedReportUser = nil

local function updateReportUserDropdown()
	for _, c in ipairs(uListFrame:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local item = Instance.new("TextButton")
			item.Size = UDim2.new(1, 0, 0, 30)
			item.BackgroundColor3 = Color3.fromRGB(45, 52, 65)
			item.BorderSizePixel = 0
			item.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")"
			item.TextColor3 = Color3.fromRGB(255, 255, 255)
			item.TextSize = 13
			item.Font = Enum.Font.BuilderSansMedium
			item.TextXAlignment = Enum.TextXAlignment.Left
			item.ZIndex = 6
			item.Parent = uListFrame

			item.MouseButton1Click:Connect(function()
				selectedReportUser = p.Name
				uBtn.Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")"
				uListFrame.Visible = false
			end)
		end
	end
end

uBtn.MouseButton1Click:Connect(function()
	if targetReportPlayer then return end
	updateReportUserDropdown()
	uListFrame.Visible = not uListFrame.Visible
end)

local rLabel = Instance.new("TextLabel")
rLabel.Size = UDim2.new(1, 0, 0, 20)
rLabel.Position = UDim2.new(0, 0, 0, 65)
rLabel.BackgroundTransparency = 1
rLabel.Text = "2. 通報の理由を選択:"
rLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rLabel.TextSize = 13
rLabel.Font = Enum.Font.BuilderSansBold
rLabel.TextXAlignment = Enum.TextXAlignment.Left
rLabel.Parent = reportFrame

local rBtn = Instance.new("TextButton")
rBtn.Size = UDim2.new(1, 0, 0, 35)
rBtn.Position = UDim2.new(0, 0, 0, 87)
rBtn.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
rBtn.BackgroundTransparency = 0.3
rBtn.BorderSizePixel = 1
rBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
rBtn.Text = "  理由を選択してください"
rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rBtn.TextSize = 13
rBtn.Font = Enum.Font.BuilderSansMedium
rBtn.TextXAlignment = Enum.TextXAlignment.Left
rBtn.Parent = reportFrame

local rListFrame = Instance.new("Frame")
rListFrame.Size = UDim2.new(1, 0, 0, 120)
rListFrame.Position = UDim2.new(0, 0, 0, 123)
rListFrame.BackgroundColor3 = Color3.fromRGB(35, 42, 52)
rListFrame.BackgroundTransparency = 0.1
rListFrame.BorderSizePixel = 1
rListFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
rListFrame.Visible = false
rListFrame.ZIndex = 5
rListFrame.Parent = reportFrame

local rListLayout = Instance.new("UIListLayout")
rListLayout.Parent = rListFrame

local reasons = { "チート / ハッキング", "暴言 / 不適切な言葉", "不快な行為 / スパム", "その他" }
local selectedReason = nil

for _, re in ipairs(reasons) do
	local item = Instance.new("TextButton")
	item.Size = UDim2.new(1, 0, 0, 30)
	item.BackgroundColor3 = Color3.fromRGB(45, 52, 65)
	item.BorderSizePixel = 0
	item.Text = "  " .. re
	item.TextColor3 = Color3.fromRGB(255, 255, 255)
	item.TextSize = 13
	item.Font = Enum.Font.BuilderSansMedium
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.ZIndex = 6
	item.Parent = rListFrame

	item.MouseButton1Click:Connect(function()
		selectedReason = re
		rBtn.Text = "  " .. re
		rListFrame.Visible = false
	end)
end

rBtn.MouseButton1Click:Connect(function()
	rListFrame.Visible = not rListFrame.Visible
end)

local dLabel = Instance.new("TextLabel")
dLabel.Size = UDim2.new(1, 0, 0, 20)
dLabel.Position = UDim2.new(0, 0, 0, 130)
dLabel.BackgroundTransparency = 1
dLabel.Text = "3. 詳細内容:"
dLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dLabel.TextSize = 13
dLabel.Font = Enum.Font.BuilderSansBold
dLabel.TextXAlignment = Enum.TextXAlignment.Left
dLabel.Parent = reportFrame

local dBox = Instance.new("TextBox")
dBox.Size = UDim2.new(1, 0, 0, 60)
dBox.Position = UDim2.new(0, 0, 0, 152)
dBox.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
dBox.BackgroundTransparency = 0.3
dBox.BorderSizePixel = 1
dBox.BorderColor3 = Color3.fromRGB(255, 255, 255)
dBox.Text = ""
dBox.PlaceholderText = "具体的な状況を入力してください..."
dBox.TextColor3 = Color3.fromRGB(255, 255, 255)
dBox.TextSize = 13
dBox.Font = Enum.Font.BuilderSansMedium
dBox.TextXAlignment = Enum.TextXAlignment.Left
dBox.TextYAlignment = Enum.TextYAlignment.Top
dBox.ClearTextOnFocus = false
dBox.Parent = reportFrame

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0, 150, 0, 35)
submitBtn.Position = UDim2.new(0.5, 0, 0, 222)
submitBtn.AnchorPoint = Vector2.new(0.5, 0)
submitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
submitBtn.BackgroundTransparency = 0.2
submitBtn.BorderSizePixel = 1
submitBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Text = "通報を送信"
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.TextSize = 14
submitBtn.Font = Enum.Font.BuilderSansBold
submitBtn.Parent = reportFrame

submitBtn.MouseButton1Click:Connect(function()
	local targetName = targetReportPlayer and targetReportPlayer.Name or selectedReportUser
	if not targetName then
		submitBtn.Text = "ユーザーを選択してください"
		task.wait(1.5)
		submitBtn.Text = "通報を送信"
		return
	end
	if not selectedReason then
		submitBtn.Text = "理由を選択してください"
		task.wait(1.5)
		submitBtn.Text = "通報を送信"
		return
	end

	if reportEvent then
		reportEvent:FireServer(targetName, selectedReason, dBox.Text)
	end

	submitBtn.Text = "送信完了！"
	task.wait(1.5)
	submitBtn.Text = "通報を送信"

	targetReportPlayer = nil
	selectedReportUser = nil
	selectedReason = nil
	uBtn.Text = "  プレイヤーを選択してください"
	rBtn.Text = "  理由を選択してください"
	dBox.Text = ""
end)

---------------------------------------------------------
-- 4. Help タブ
---------------------------------------------------------
local helpFrame = Instance.new("Frame")
helpFrame.Name = "HelpFrame"
helpFrame.Size = UDim2.new(1, -20, 1, -110)
helpFrame.Position = UDim2.new(0, 10, 0, 55)
helpFrame.BackgroundTransparency = 1
helpFrame.Visible = false
helpFrame.Parent = mainFrame
tabFrames["Help"] = helpFrame

local helpText = Instance.new("TextLabel")
helpText.Size = UDim2.new(1, 0, 1, 0)
helpText.BackgroundTransparency = 1
helpText.Text = "【操作ガイド】\n\n- [Q] / [Esc] キー: メニュー開閉・再開\n- [R] キー: キャラクターリセット\n- [L] キー: ゲーム離脱ダイアログ\n- [Enter] キー: 確認ダイアログの決定\n\nご不明な点がございましたら開発者までお問い合わせください。"
helpText.TextColor3 = Color3.fromRGB(255, 255, 255)
helpText.TextSize = 13
helpText.Font = Enum.Font.BuilderSansMedium
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Top
helpText.TextWrapped = true
helpText.Parent = helpFrame

---------------------------------------------------------
-- フッター (下部アクションボタン)
---------------------------------------------------------
local footerFrame = Instance.new("Frame")
footerFrame.Size = UDim2.new(1, 0, 0, 50)
footerFrame.Position = UDim2.new(0, 0, 1, -50)
footerFrame.BackgroundColor3 = Color3.fromRGB(30, 36, 44)
footerFrame.BackgroundTransparency = 0.3
footerFrame.BorderSizePixel = 1
footerFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
footerFrame.Parent = mainFrame

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.3, 0, 0, 34)
resetBtn.Position = UDim2.new(0.02, 0, 0.5, 0)
resetBtn.AnchorPoint = Vector2.new(0, 0.5)
resetBtn.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
resetBtn.BackgroundTransparency = 0.2
resetBtn.BorderSizePixel = 1
resetBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Text = ""
resetBtn.Parent = footerFrame

local btn1Constraint = Instance.new("UISizeConstraint")
btn1Constraint.MaxSize = Vector2.new(180, 34)
btn1Constraint.Parent = resetBtn

createKeyBadge("R", resetBtn)

local resetLbl = Instance.new("TextLabel")
resetLbl.Size = UDim2.new(1, -40, 1, 0)
resetLbl.Position = UDim2.new(0, 40, 0, 0)
resetLbl.BackgroundTransparency = 1
resetLbl.Text = "リセット"
resetLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
resetLbl.TextSize = 12
resetLbl.Font = Enum.Font.BuilderSansBold
resetLbl.TextXAlignment = Enum.TextXAlignment.Center
resetLbl.Parent = resetBtn

resetBtn.MouseButton1Click:Connect(function()
	showFullConfirm("キャラクターをリスポーンしてよろしいですか？", "リセット", "キャンセル", function()
		confirmOverlay.Visible = false
		mainFrame.Visible = false
		overlay.Visible = true
		overlay.BackgroundTransparency = 0.3

		local tween = TweenService:Create(overlay, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Connect(function()
			overlay.Visible = false
			setPlayerFrozen(false)
			isMenuOpen = false
			topbarIcon:deselect()

			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = 0
				end
				char:BreakJoints()
			end
		end)
	end)
end)

local leaveBtn = Instance.new("TextButton")
leaveBtn.Size = UDim2.new(0.3, 0, 0, 34)
leaveBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
leaveBtn.AnchorPoint = Vector2.new(0.5, 0.5)
leaveBtn.BackgroundColor3 = Color3.fromRGB(50, 58, 70)
leaveBtn.BackgroundTransparency = 0.2
leaveBtn.BorderSizePixel = 1
leaveBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
leaveBtn.Text = ""
leaveBtn.Parent = footerFrame

local btn2Constraint = Instance.new("UISizeConstraint")
btn2Constraint.MaxSize = Vector2.new(180, 34)
btn2Constraint.Parent = leaveBtn

createKeyBadge("L", leaveBtn)

local leaveLbl = Instance.new("TextLabel")
leaveLbl.Size = UDim2.new(1, -40, 1, 0)
leaveLbl.Position = UDim2.new(0, 40, 0, 0)
leaveLbl.BackgroundTransparency = 1
leaveLbl.Text = "退出"
leaveLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
leaveLbl.TextSize = 12
leaveLbl.Font = Enum.Font.BuilderSansBold
leaveLbl.TextXAlignment = Enum.TextXAlignment.Center
leaveLbl.Parent = leaveBtn

leaveBtn.MouseButton1Click:Connect(function()
	showFullConfirm("ゲームを退出してよろしいですか？", "退出", "キャンセル", function()
		confirmOverlay.Visible = false
		mainFrame.Visible = false
		overlay.Visible = true
		overlay.BackgroundTransparency = 0.3

		local tweenIn = TweenService:Create(overlay, TweenInfo.new(0.4), { BackgroundTransparency = 0 })
		tweenIn:Play()
		tweenIn.Completed:Connect(function()
			task.wait(0.2)
			player:Kick("ゲームから退出しました")
		end)
	end)
end)

local resumeBtn = Instance.new("TextButton")
resumeBtn.Size = UDim2.new(0.3, 0, 0, 34)
resumeBtn.Position = UDim2.new(0.98, 0, 0.5, 0)
resumeBtn.AnchorPoint = Vector2.new(1, 0.5)
resumeBtn.BackgroundColor3 = Color3.fromRGB(55, 75, 120)
resumeBtn.BackgroundTransparency = 0.2
resumeBtn.BorderSizePixel = 1
resumeBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
resumeBtn.Text = ""
resumeBtn.Parent = footerFrame

local btn3Constraint = Instance.new("UISizeConstraint")
btn3Constraint.MaxSize = Vector2.new(180, 34)
btn3Constraint.Parent = resumeBtn

createKeyBadge("Q", resumeBtn)

local resumeLbl = Instance.new("TextLabel")
resumeLbl.Size = UDim2.new(1, -40, 1, 0)
resumeLbl.Position = UDim2.new(0, 40, 0, 0)
resumeLbl.BackgroundTransparency = 1
resumeLbl.Text = "再開"
resumeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
resumeLbl.TextSize = 12
resumeLbl.Font = Enum.Font.BuilderSansBold
resumeLbl.TextXAlignment = Enum.TextXAlignment.Center
resumeLbl.Parent = resumeBtn

---------------------------------------------------------
-- メニュー表示 / 非表示 トグル処理
---------------------------------------------------------
local topbarIcon = Icon.new()
topbarIcon:setImage("rbxassetid://6031097225")

local menuTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local function toggleMenu(visible)
	isMenuOpen = (visible ~= nil and visible) or not isMenuOpen

	if isMenuOpen then
		setPlayerFrozen(true)
		mainFrame.Position = UDim2.new(0.5, 0, -0.6, 0)
		mainFrame.BackgroundTransparency = 1
		overlay.BackgroundTransparency = 1
		overlay.Visible = true
		mainFrame.Visible = true

		TweenService:Create(overlay, menuTweenInfo, { BackgroundTransparency = 0.3 }):Play()
		TweenService:Create(mainFrame, menuTweenInfo, {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0.35
		}):Play()

		topbarIcon:select()
		switchTab(currentTab)
	else
		setPlayerFrozen(false)
		local tweenOverlay = TweenService:Create(overlay, menuTweenInfo, { BackgroundTransparency = 1 })
		local tweenMain = TweenService:Create(mainFrame, menuTweenInfo, {
			Position = UDim2.new(0.5, 0, -0.6, 0),
			BackgroundTransparency = 1
		})

		tweenOverlay:Play()
		tweenMain:Play()

		tweenMain.Completed:Connect(function()
			if not isMenuOpen then
				overlay.Visible = false
				mainFrame.Visible = false
				confirmOverlay.Visible = false
				avatarModal.Visible = false
				uListFrame.Visible = false
				rListFrame.Visible = false
			end
		end)

		topbarIcon:deselect()
	end
end

resumeBtn.MouseButton1Click:Connect(function()
	toggleMenu(false)
end)

topbarIcon.selected:Connect(function()
	if not isMenuOpen then
		toggleMenu(true)
	end
end)

topbarIcon.deselected:Connect(function()
	if isMenuOpen then
		toggleMenu(false)
	end
end)

---------------------------------------------------------
-- キーボードショートカット対応
---------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
	if UserInputService:GetFocusedTextBox() then return end

	if confirmOverlay.Visible then
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			confirmOkBtn.MouseButton1Click:Fire()
			return
		end
	end

	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.Escape then
		toggleMenu()
		return
	end

	if isMenuOpen then
		if input.KeyCode == Enum.KeyCode.R then
			resetBtn.MouseButton1Click:Fire()
		elseif input.KeyCode == Enum.KeyCode.L then
			leaveBtn.MouseButton1Click:Fire()
		end
	end
end)

switchTab("Players")
