--!strict
-- Obby Checkpoint module for Roblox
-- Returns a table with .new(config) method

local Players = game:GetService("Players")

export type Config = {
	checkpointTag: string?,
	respawnDelay: number?,
	antiSkip: boolean?,
	spawnOnJoin: boolean?,
	resetOnDeath: boolean?,
}

type PlayerData = {
	checkpoint: BasePart?,
	connection: RBXScriptConnection?,
}

local ObbyCheckpoint = {}
ObbyCheckpoint.__index = ObbyCheckpoint

local DEFAULTS = {
	checkpointTag = "Checkpoint",
	respawnDelay = 0.5,
	antiSkip = true,
	spawnOnJoin = true,
	resetOnDeath = true,
}

function ObbyCheckpoint.new(config: Config?): any
	local self = setmetatable({}, ObbyCheckpoint)
	self._config = {}
	for k, v in pairs(DEFAULTS) do
		self._config[k] = v
	end
	if config then
		for k, v in pairs(config) do
			if DEFAULTS[k] ~= nil then
				self._config[k] = v
			end
		end
	end

	self._playerData = {}
	self._connections = {}

	-- Setup checkpoint parts
	self._checkpoints = {}
	self:_collectCheckpoints()

	-- Player joining
	table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end))

	-- Player leaving
	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end))

	-- Existing players
	for _, player in ipairs(Players:GetPlayers()) do
		self:_onPlayerAdded(player)
	end

	return self
end

function ObbyCheckpoint:_collectCheckpoints()
	self._checkpoints = {}
	local workspace = game:GetService("Workspace")
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute(self._config.checkpointTag) then
			local order = obj:GetAttribute("CheckpointOrder") or 0
			table.insert(self._checkpoints, { part = obj, order = order })
		end
	end
	table.sort(self._checkpoints, function(a, b)
		return a.order < b.order
	end)
end

function ObbyCheckpoint:_onPlayerAdded(player: Player)
	local data: PlayerData = { checkpoint = nil, connection = nil }
	self._playerData[player] = data

	-- Character added connection
	data.connection = player.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(player, character)
	end)

	-- If character already exists
	local character = player.Character
	if character then
		self:_onCharacterAdded(player, character)
	elseif self._config.spawnOnJoin then
		task.defer(function()
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end
end

function ObbyCheckpoint:_onPlayerRemoving(player: Player)
	local data = self._playerData[player]
	if data then
		if data.connection then
			data.connection:Disconnect()
			data.connection = nil
		end
		self._playerData[player] = nil
	end
end

function ObbyCheckpoint:_onCharacterAdded(player: Player, character: Model)
	local data = self._playerData[player]
	if not data then return end

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then return end

	-- Teleport to checkpoint if exists
	if data.checkpoint and data.checkpoint.Parent then
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if hrp and hrp:IsA("BasePart") then
			hrp.CFrame = data.checkpoint.CFrame + Vector3.new(0, 5, 0)
		end
	end

	-- Handle death reset
	if self._config.resetOnDeath then
		local deathConn: RBXScriptConnection? = nil
		deathConn = humanoid.Died:Connect(function()
			if deathConn then
				deathConn:Disconnect()
				deathConn = nil
			end
			if data.checkpoint then
				local d = data.checkpoint
				task.delay(self._config.respawnDelay, function()
					if player.Parent and d and d.Parent then
						local hrp2 = character:FindFirstChild("HumanoidRootPart")
						if hrp2 and hrp2:IsA("BasePart") then
							hrp2.CFrame = d.CFrame + Vector3.new(0, 5, 0)
						end
					end
				end)
			end
		end)
		table.insert(self._connections, deathConn)
	end
end

function ObbyCheckpoint:RegisterCheckpoint(part: BasePart)
	if not part:IsA("BasePart") then return end
	if not part:GetAttribute(self._config.checkpointTag) then return end

	local order = part:GetAttribute("CheckpointOrder") or 0
	table.insert(self._checkpoints, { part = part, order = order })
	table.sort(self._checkpoints, function(a, b)
		return a.order < b.order
	end)

	-- Connect touch event
	local conn = part.Touched:Connect(function(hit)
		self:_onCheckpointTouched(part, hit)
	end)
	table.insert(self._connections, conn)
end

function ObbyCheckpoint:_onCheckpointTouched(checkpointPart: BasePart, hit: BasePart)
	local character = hit.Parent
	if not character then return end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local data = self._playerData[player]
	if not data then return end

	-- Anti-skip: only allow next checkpoint or same
	if self._config.antiSkip then
		local currentOrder = 0
		if data.checkpoint then
			for _, cp in ipairs(self._checkpoints) do
				if cp.part == data.checkpoint then
					currentOrder = cp.order
					break
				end
			end
		end
		local newOrder = 0
		for _, cp in ipairs(self._checkpoints) do
			if cp.part == checkpointPart then
				newOrder = cp.order
				break
			end
		end
		if newOrder > currentOrder + 1 then
			return
		end
	end

	-- Update checkpoint
	data.checkpoint = checkpointPart
end

function ObbyCheckpoint:Destroy()
	for _, conn in ipairs(self._connections) do
		if conn and typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	self._connections = {}

	for player, data in pairs(self._playerData) do
		if data.connection then
			data.connection:Disconnect()
			data.connection = nil
		end
		self._playerData[player] = nil
	end
	self._playerData = {}
	self._checkpoints = {}
end

return ObbyCheckpoint
