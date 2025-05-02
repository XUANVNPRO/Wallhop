-- WallHop V3 Finalized – Clean Camera, Pro Jump Rotation

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local cam = Workspace.CurrentCamera

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.ResetOnSpawn = false

-- Toggle button
local toggleBtn = Instance.new("TextButton", screenGui)
toggleBtn.Size = UDim2.new(0, 30, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -15)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
toggleBtn.Text = "≡"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Active = true
toggleBtn.Draggable = true

-- Menu
local menu = Instance.new("Frame", screenGui)
menu.Size = UDim2.new(0, 180, 0, 80)
menu.Position = UDim2.new(0.5, -90, 0.5, -40)
menu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
menu.Visible = false
menu.Active = true
menu.Draggable = true

-- WallHop Button
local wallhopToggle = false
local wallhopBtn = Instance.new("TextButton", menu)
wallhopBtn.Size = UDim2.new(0.8, 0, 0, 35)
wallhopBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
wallhopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
wallhopBtn.Text = "WallHop: OFF"
wallhopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
wallhopBtn.TextScaled = true

wallhopBtn.MouseButton1Click:Connect(function()
	wallhopToggle = not wallhopToggle
	if wallhopToggle then
		wallhopBtn.Text = "WallHop: ON"
		wallhopBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 80)
	else
		wallhopBtn.Text = "WallHop: OFF"
		wallhopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	menu.Visible = not menu.Visible
end)

-- Core WallHop
local InfiniteJumpEnabled = true
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function getWallHit()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	rayParams.FilterDescendantsInstances = {char}
	local closest = nil
	local minDist = 2.5

	for i = 0, 7 do
		local dir = (root.CFrame * CFrame.Angles(0, math.rad(i * 45), 0)).LookVector
		local ray = Workspace:Raycast(root.Position, dir * 2, rayParams)
		if ray and ray.Distance < minDist then
			closest = ray
			minDist = ray.Distance
		end
	end

	local blockResult = Workspace:Blockcast(root.CFrame * CFrame.new(0, -1, -0.5), Vector3.new(1.5,1,0.5), root.CFrame.LookVector * 1.5, rayParams)
	if blockResult and blockResult.Distance < minDist then
		closest = blockResult
	end

	return closest
end

UIS.JumpRequest:Connect(function()
	if not wallhopToggle or not InfiniteJumpEnabled then return end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and root and cam and hum:GetState() ~= Enum.HumanoidStateType.Dead) then return end

	local wall = getWallHit()
	if wall then
		InfiniteJumpEnabled = false

		local wallNormal = wall.Normal
		local away = Vector3.new(wallNormal.X, 0, wallNormal.Z).Unit
		if away.Magnitude < 0.1 then away = -root.CFrame.LookVector end

		local camDir = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit
		if camDir.Magnitude < 0.1 then camDir = away end

		local dot = math.clamp(away:Dot(camDir), -1, 1)
		local angle = math.acos(dot)
		local cross = away:Cross(camDir)
		local sign = -math.sign(cross.Y)
		local angleLimit = sign == 1 and math.rad(20) or math.rad(100)
		local finalRot = CFrame.Angles(0, math.min(angle, angleLimit) * sign, 0)
		local jumpDir = (finalRot * away).Unit

		-- Tween xoay nhân vật
		local tween = TweenService:Create(root, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(root.Position, root.Position + jumpDir)
		})
		tween:Play()
		tween.Completed:Wait()

		hum:ChangeState(Enum.HumanoidStateType.Jumping)

		root.CFrame *= CFrame.Angles(0, -1, 0)
		task.wait(0.15)
		root.CFrame *= CFrame.Angles(0, 1, 0)
		task.wait(0.05)
		root.CFrame = CFrame.lookAt(root.Position, root.Position - away)

		InfiniteJumpEnabled = true
	end
end)