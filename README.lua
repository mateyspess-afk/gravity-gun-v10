-- [[ Gravity Gun FE V10 - Proximity Verification & First Person Camera Lock ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local enabled = false
local selectedPart = nil
local holdDistance = 12
local maxReachDistance = 25
local throwPower = 300
local isMinimized = false

-- Physics Elements
local bodyPos = nil
local bodyGyro = nil
local renderConnection = nil

-- Create Stylized ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GravityGunV10Gui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 260)
mainFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(130, 40, 255)
stroke.Thickness = 2
stroke.Parent = mainFrame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 38)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 16))
})
gradient.Rotation = 45
gradient.Parent = mainFrame

-- TopBar Header
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundTransparency = 1
topBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0.05, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ GRAVITY GUN"
title.TextColor3 = Color3.fromRGB(240, 220, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Animated Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
minimizeBtn.Position = UDim2.new(1, -34, 0.15, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 16
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Parent = topBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -35)
contentContainer.Position = UDim2.new(0, 0, 0, 35)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 24)
statusLabel.Position = UDim2.new(0, 0, 0, 2)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Disabled"
statusLabel.TextColor3 = Color3.fromRGB(170, 170, 190)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.Parent = contentContainer

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.88, 0, 0, 32)
toggleBtn.Position = UDim2.new(0.06, 0, 0.22, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(190, 40, 55)
toggleBtn.Text = "ENABLE SCRIPT"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 12
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = contentContainer
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local dropBtn = Instance.new("TextButton")
dropBtn.Size = UDim2.new(0.88, 0, 0, 32)
dropBtn.Position = UDim2.new(0.06, 0, 0.40, 0)
dropBtn.BackgroundColor3 = Color3.fromRGB(170, 110, 25)
dropBtn.Text = "✋ DROP OBJECT"
dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropBtn.TextSize = 12
dropBtn.Font = Enum.Font.GothamBold
dropBtn.Parent = contentContainer
Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 8)

local throwBtn = Instance.new("TextButton")
throwBtn.Size = UDim2.new(0.88, 0, 0, 32)
throwBtn.Position = UDim2.new(0.06, 0, 0.58, 0)
throwBtn.BackgroundColor3 = Color3.fromRGB(35, 100, 190)
throwBtn.Text = "🚀 THROW OBJECT"
throwBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
throwBtn.TextSize = 12
throwBtn.Font = Enum.Font.GothamBold
throwBtn.Parent = contentContainer
Instance.new("UICorner", throwBtn).CornerRadius = UDim.new(0, 8)

-- Distance Control Frame
local distFrame = Instance.new("Frame")
distFrame.Size = UDim2.new(0.88, 0, 0, 28)
distFrame.Position = UDim2.new(0.06, 0, 0.77, 0)
distFrame.BackgroundTransparency = 1
distFrame.Parent = contentContainer

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0.28, 0, 1, 0)
minusBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
minusBtn.Text = "━"
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.Parent = distFrame
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0.4, 0, 1, 0)
distLabel.Position = UDim2.new(0.3, 0, 0, 0)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Dist: 12"
distLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
distLabel.Font = Enum.Font.GothamBold
distLabel.TextSize = 11
distLabel.Parent = distFrame

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0.28, 0, 1, 0)
plusBtn.Position = UDim2.new(0.72, 0, 0, 0)
plusBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
plusBtn.Text = "╋"
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.Parent = distFrame
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)

-- Smooth Minimize Tween Animation
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	if isMinimized then
		minimizeBtn.Text = "+"
		contentContainer.Visible = false
		local tween = TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 230, 0, 35)})
		tween:Play()
	else
		minimizeBtn.Text = "-"
		local tween = TweenService:Create(mainFrame, tweenInfo, {Size = UDim2.new(0, 230, 0, 260)})
		tween:Play()
		tween.Completed:Connect(function()
			if not isMinimized then
				contentContainer.Visible = true
			end
		end)
	end
end)

-- Proximity Object Compatibility Check
local function checkGameCompatibility()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	
	local validFound = false
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj.Anchored and not obj:IsDescendantOf(player.Character) then
			if (obj.Position - hrp.Position).Magnitude <= 60 then
				validFound = true
				break
			end
		end
	end
	return validFound
end

-- Physics Functions
local function stopDragging()
	if bodyPos then bodyPos:Destroy() bodyPos = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if renderConnection then renderConnection:Disconnect() renderConnection = nil end
	
	if selectedPart then
		pcall(function()
			selectedPart:SetNetworkOwner(nil)
		end)
		selectedPart = nil
	end
	
	if enabled then
		statusLabel.Text = "Ready to grab..."
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
	else
		statusLabel.Text = "Status: Disabled"
		statusLabel.TextColor3 = Color3.fromRGB(170, 170, 190)
	end
end

local function startDragging(part)
	if not part or part.Anchored or part:IsDescendantOf(player.Character) then return end
	
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and (part.Position - hrp.Position).Magnitude > maxReachDistance then
		statusLabel.Text = "⚠️ Object too far!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end
	
	stopDragging()
	selectedPart = part
	
	pcall(function()
		if selectedPart:IsA("BasePart") then
			selectedPart:SetNetworkOwner(player)
		end
	end)
	
	bodyPos = Instance.new("BodyPosition")
	bodyPos.MaxForce = Vector3.new(40000, 40000, 40000)
	bodyPos.P = 3000
	bodyPos.D = 300
	bodyPos.Position = part.Position
	bodyPos.Parent = part
	
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(20000, 20000, 20000)
	bodyGyro.P = 3000
	bodyGyro.CFrame = part.CFrame
	bodyGyro.Parent = part
	
	statusLabel.Text = "✅ Holding object!"
	statusLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
	
	renderConnection = RunService.RenderStepped:Connect(function()
		if selectedPart and selectedPart.Parent and not selectedPart.Anchored and bodyPos then
			if hrp and (selectedPart.Position - hrp.Position).Magnitude > (maxReachDistance + 15) then
				stopDragging()
				return
			end
			
			local targetPos = camera.CFrame.Position + (camera.CFrame.LookVector * holdDistance)
			bodyPos.Position = targetPos
			bodyGyro.CFrame = camera.CFrame
		else
			stopDragging()
		end
	end)
end

local function throwObject()
	if selectedPart and bodyPos then
		local partToThrow = selectedPart
		
		pcall(function()
			partToThrow:SetNetworkOwner(nil)
		end)
		
		stopDragging()
		
		if partToThrow:IsA("BasePart") then
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(30000, 30000, 30000)
			bv.Velocity = camera.CFrame.LookVector * throwPower
			bv.Parent = partToThrow
			
			task.delay(0.2, function()
				if bv then bv:Destroy() end
			end)
		end
		statusLabel.Text = "🚀 Object thrown!"
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	end
end

-- Toggle Button Listener with Verification & Camera Lock
toggleBtn.MouseButton1Click:Connect(function()
	if not enabled then
		statusLabel.Text = "Checking game..."
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		task.wait(0.4)
		
		if not checkGameCompatibility() then
			statusLabel.Text = "❌ No unanchored objects!"
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			return
		end
		
		enabled = true
		toggleBtn.Text = "DISABLE SCRIPT"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(35, 160, 80)
		statusLabel.Text = "Ready to grab..."
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
		
		-- Lock camera in First Person Mode
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		enabled = false
		toggleBtn.Text = "ENABLE SCRIPT"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(190, 40, 55)
		stopDragging()
		statusLabel.Text = "Status: Disabled"
		statusLabel.TextColor3 = Color3.fromRGB(170, 170, 190)
		
		-- Unlock camera back to Classic Mode
		player.CameraMode = Enum.CameraMode.Classic
	end
end)

dropBtn.MouseButton1Click:Connect(function()
	if selectedPart then
		stopDragging()
		statusLabel.Text = "✋ Object dropped!"
		statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	else
		statusLabel.Text = "⚠️ No object held"
		statusLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
	end
end)

throwBtn.MouseButton1Click:Connect(function()
	if selectedPart then
		throwObject()
	else
		statusLabel.Text = "⚠️ No object to throw"
		statusLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
	end
end)

plusBtn.MouseButton1Click:Connect(function()
	holdDistance = math.clamp(holdDistance + 3, 4, maxReachDistance)
	distLabel.Text = "Dist: " .. tostring(holdDistance)
end)

minusBtn.MouseButton1Click:Connect(function()
	holdDistance = math.clamp(holdDistance - 3, 4, maxReachDistance)
	distLabel.Text = "Dist: " .. tostring(holdDistance)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not enabled or gameProcessed or isMinimized then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if not selectedPart then
			local target = mouse.Target
			if target and not target.Anchored then
				startDragging(target)
			end
		end
	end
end)
