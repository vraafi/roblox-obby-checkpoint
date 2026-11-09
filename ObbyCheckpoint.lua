local Players = game:GetService("Players")

local ObbyCheckpoint = {}
ObbyCheckpoint.__index = ObbyCheckpoint

type Config = {
	AntiSkip: boolean,
	AutoTeleportOnSpawn: boolean,
	InitialStage: number,
	TeleportOffsetY: number,
	TeleportOffsetZ: number,
}

local DEFAULT_CONFIG: Config = {
	AntiSkip = true,
	AutoTeleportOnSpawn = true,
	InitialStage = 1,
	TeleportOffsetY = 3,
	TeleportOffsetZ = 0,
}

function ObbyCheckpoint.new(checkpointsFolder: Instance, config: Config?)
	local self = setmetatable({}, ObbyCheckpoint)

	local mergedConfig = {}
	for key, value in pairs(DEFAULT_CONFIG) do
		mergedConfig[key] = value
	end
	if config then
		for key, value in pairs(config) do
			mergedConfig[key] = value
		end
	end

	self._config = mergedConfig
	self._checkpointsFolder = checkpointsFolder
	self._checkpoints = {} :: { [number]: BasePart }
	self._playerData = {} :: {
		[Player]: {
			stage: number,
			connections: { [string]: RBXScriptConnection },
		},
	}
	self._connections = {} :: { RBXScriptConnection }

	self:_indexCheckpoints()
	self:_init()

	return self
end

function ObbyCheckpoint:_indexCheckpoints()
	local parts = {}
	for _, child in ipairs(self._checkpointsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local stageNum = tonumber(child.Name)
			if stageNum then
				parts[stageNum] = child
			end
		end
	end
	self._checkpoints = parts
end

function ObbyCheckpoint:_init()
	for stageIndex, part in pairs(self._checkpoints) do
		local conn = part.Touched:Connect(function(hit)
			self:_onCheckpointTouched(stageIndex, hit)
		end)
		table.insert(self._connections, conn)
	end

	local playerAddedConn = Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
		end)
	table.insert(self._connections, playerAddedConn)

	local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
		end)
	table.insert(self._connections, playerRemovingConn)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_onPlayerAdded(player)
	end
end

function ObbyCheckpoint:_onPlayerAdded(player: Player)
	if self._playerData[player] then
		return
	end

	self._playerData[player] = {
		stage = self._config.InitialStage,
		connections = {},
	}

	local charAddedConn = player.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(player, character)
		end)
	self._playerData[player].connections["CharacterAdded"] = charAddedConn

	if player.Character then
		self:_onCharacterAdded(player, player.Character)
	end
end

function ObbyCheckpoint:_onPlayerRemoving(player: Player)
	local data = self._playerData[player]
	if data then
		for _, conn in pairs(data.connections) do
			conn:Disconnect()
		end
		self._playerData[player] = nil
	end
end

function ObbyCheckpoint:_onCharacterAdded(player: Player, character: Model)
	if not self._config.AutoTeleportOnSpawn then
		return
	end

	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not root then
		return
	end

	task.wait(0.1)

	if character and character:IsDescendantOf(workspace) then
		self:TeleportToStage(player, self:GetPlayerStage(player))
	end
end

function ObbyCheckpoint:_onCheckpointTouched(stageIndex: number, hit: Instance)
	local character = hit.Parent
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local data = self._playerData[player]
	if not data then
		return
	end

	local currentStage = data.stage
	if stageIndex <= currentStage then
		return
	end

	if self._config.AntiSkip and stageIndex > currentStage + 1 then
		return
	end

	data.stage = stageIndex
end

function ObbyCheckpoint:GetPlayerStage(player: Player): number
	local data = self._playerData[player]
	return data and data.stage or self._config.InitialStage
end

function ObbyCheckpoint:SetPlayerStage(player: Player, stage: number)
	local data = self._playerData[player]
	if data then
		data.stage = stage
	end
end

function ObbyCheckpoint:TeleportToStage(player: Player, stage: number)
	local part = self._checkpoints[stage]
	if not part then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local offset = Vector3.new(0, self._config.TeleportOffsetY, self._config.TeleportOffsetZ)
		root.CFrame = part.CFrame + offset
	end
end

function ObbyCheckpoint:Destroy()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)

	for _, data in pairs(self._playerData) do
		for _, conn in pairs(data.connections) do
			conn:Disconnect()
		end
	end
	table.clear(self._playerData)
end

return ObbyCheckpoint
