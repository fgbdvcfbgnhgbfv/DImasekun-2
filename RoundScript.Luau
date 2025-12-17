local intermissionTime = 30 -- Ожидание перед матчем
local roundTime = 300 -- Длительность раунда
local caer = game.ReplicatedStorage.Events.Guievent
local custartevent = game.ReplicatedStorage.Events.CustardEvents.Custartup
local KillersFolder = workspace.Players:WaitForChild("Killer")
local SurvivorsFolder = workspace.Players:WaitForChild("Survivors")
local minPlayers = 2
local killerIndex = 1 -- текущий индекс убийцы
local mapIndex = 1 -- текущий индекс карты
local morhpevent = game.ReplicatedStorage.Events.Morphevent
local lastgs = game.ReplicatedStorage.Events.Lastgood.GuiEventG
local Players = game:GetService("Players")
local currentMap = nil
lastmanvarible = false
local timeevent = game.ReplicatedStorage.Events.Timeevent
local guimagevent = game.ReplicatedStorage.Events.Gui.ImageMapGui
local NeutralsFolder = workspace.Players:WaitForChild("Neutral")
local PlayerChoseEvent = game.ReplicatedStorage.Events:WaitForChild("PlayerChoseEvent")
local chosenPlayers = {}
local solomusic = game.ReplicatedStorage.Events.SoloMusic
local Maps = {
	--game.ReplicatedStorage.Maps.MapForTesting,
	game.ReplicatedStorage.Maps.UltraBrawl,
	game.ReplicatedStorage.Maps.Dimamap,
	game.ReplicatedStorage.Maps.BulluTown,
	game.ReplicatedStorage.Maps.GrysaMap,
}

-- Проверка условия "последний человек" — срабатывает когда:
-- есть хотя бы 1 киллер и ровно 1 не-киллер (выживший или нейтрал) И этот не-киллер - Сергей
local function checkLastManTrigger()
	if lastmanvarible then return end -- уже сработало в этом раунде

	local k = #KillersFolder:GetChildren()
	local s = #SurvivorsFolder:GetChildren()
	local n = #NeutralsFolder:GetChildren()

	-- Условие: есть киллеры и ровно один не-киллер
	if k >= 1 and (s + n) == 1 then
		-- Находим оставшегося не-киллера
		local lastMan = nil
		if s == 1 then
			lastMan = SurvivorsFolder:GetChildren()[1]
		elseif n == 1 then
			lastMan = NeutralsFolder:GetChildren()[1]
		end

		-- Проверяем, что это Сергей
		if lastMan and lastMan:FindFirstChild("Sergay") then
			-- триггерим событие последний человек
			currentRoundTime = 194 -- продлеваем время
			lastgs:FireAllClients()
			lastmanvarible = true

			-- 🔥 Включаем сольную музыку только для Сергея
			solomusic:FireAllClients("Sergay")

			-- 🔥 Увеличиваем ХП Сергея до 165 и полностью лечим
			local humanoid = lastMan:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.MaxHealth = 200
				humanoid.Health = 200
				print("[SERGAY SOLO] ХП увеличено до 200! Сергей готов к бою!")
			else
				warn("[SERGAY SOLO] Не удалось найти Humanoid у Сергея")
			end

			print("[INFO] Сергей в соло! Активирована сольная музыка и буст ХП. " .. k .. " killer(s) vs Сергей")
		elseif lastMan and lastMan:FindFirstChild("tmugrobot") then
			currentRoundTime = 120 -- продлеваем время
			lastgs:FireAllClients()
			lastmanvarible = true

			solomusic:FireAllClients("tmugrobot")

			local humanoid = lastMan:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.MaxHealth = 140
				humanoid.Health = 140
				lastMan.Peregnev.Value = - 20
			end
		else
			-- Если последний не Сергей, просто активируем lastman без музыки и буста
			local humanoid = lastMan:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.MaxHealth = 140
				humanoid.Health = 140
			end
			currentRoundTime = 120
			solomusic:FireAllClients("OneLast")
			lastgs:FireAllClients()
			lastmanvarible = true
			print("[INFO] Last-man trigger: " .. k .. " killer(s) vs 1 non-killer (не Сергей)")
		end
	end
end

PlayerChoseEvent.OnServerEvent:Connect(function(player)
	chosenPlayers[player.UserId] = true
	print("[CHOICE] Игрок выбрал персонажа:", player.Name)
end)

local function checkWinner()
	local killers = KillersFolder:GetChildren()
	local survivors = SurvivorsFolder:GetChildren()
	local neutrals = NeutralsFolder:GetChildren()

	-- 🏆 Функция начисления награды победителю
	local function giveWin(player)
		if not player then return end

		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			warn("[giveWin] " .. player.Name .. " не имеет leaderstats!")
			return
		end

		local wins = leaderstats:FindFirstChild("Wins")
		local tokens = leaderstats:FindFirstChild("Tokens")

		if wins then
			wins.Value += 1
			print("🏆 " .. player.Name .. " получил победу! Теперь Wins =", wins.Value)
		else
			warn("[giveWin] У " .. player.Name .. " нет Wins!")
		end

		if tokens then
			tokens.Value += 500
			print("💰 " .. player.Name .. " получил 30 токенов за победу! Теперь Tokens =", tokens.Value)
		else
			warn("[giveWin] У " .. player.Name .. " нет Tokens!")
		end
	end

	-- 🧩 Безопасная функция для получения игрока из персонажа
	local function safeGetPlayerFromCharacter(character)
		local player = game.Players:GetPlayerFromCharacter(character)
		if not player then
			warn("[safeGetPlayerFromCharacter] Не найден игрок для персонажа:", character.Name)
		end
		return player
	end

	-- ⚪ Ничья — никто не выжил
	if #killers == 0 and #survivors == 0 and #neutrals == 0 then
		print("⚪ Ничья — никто не выжил.")
		return
	end

	-- 🟢 Победа выживших (киллер мёртв и выжившие живы)
	if #killers == 0 and #survivors > 0 then
		print("🟢 Победа выживших!")
		for _, plr in ipairs(survivors) do
			giveWin(safeGetPlayerFromCharacter(plr))
		end
		return
	end

	-- 😐 Победа нейтрала (если киллер мёртв, выживших нет и остался один нейтрал)
	if #killers == 0 and #survivors == 0 and #neutrals == 1 then
		print("😐 Победа нейтрала!")
		giveWin(safeGetPlayerFromCharacter(neutrals[1]))
		return
	end

	-- 🔴 Победа киллера (если остался один)
	if #killers > 0 and #survivors == 0 and #neutrals == 0 then
		print("🔴 Победа киллера!")
		for _, plr in ipairs(killers) do
			giveWin(safeGetPlayerFromCharacter(plr))
		end
		return
	end

	-- 🕒 Победа выживших по таймеру (если время вышло и есть выжившие)
	if currentRoundTime and currentRoundTime <= 0 then
		if #survivors > 0 then
			print("🕒 Время вышло — выжившие победили!")
			for _, plr in ipairs(survivors) do
				giveWin(safeGetPlayerFromCharacter(plr))
			end
		elseif #killers > 0 and #survivors == 0 and #neutrals == 0 then
			-- 🔴 ДОБАВЛЕНО: Победа киллера по таймеру, если нет выживших и нейтралов
			print("🕒 Время вышло — киллеры победили!")
			for _, plr in ipairs(killers) do
				giveWin(safeGetPlayerFromCharacter(plr))
			end
		end
		return
	end
end

local function trashdestroy()
	game.Workspace.trash:Destroy()
	task.wait(0.1)
	local newtrash = Instance.new("Folder")
	newtrash.Name = "trash"
	newtrash.Parent = game.Workspace
end

local function getSpawnParts(name)
	local spawns = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == name then
			table.insert(spawns, obj)
		end
	end
	return spawns
end

-- Назначение ролей и телепорт
local function assignPlayersToFolders()
	for _, folder in pairs({KillersFolder, SurvivorsFolder}) do
		for _, model in ipairs(folder:GetChildren()) do
			model.Parent = workspace
		end
	end

	local allPlayers = Players:GetPlayers()
	if #allPlayers == 0 then return end

	local killer = allPlayers[killerIndex]
	killerIndex += 1
	if killerIndex > #allPlayers then
		killerIndex = 1
	end
	local neutral
	if #allPlayers > 3 then
		neutral = allPlayers[math.random(1, #allPlayers)]
		while neutral == killer do
			neutral = allPlayers[math.random(1, #allPlayers)]
		end
	end

	-- Находим спавны
	local survivorSpawns = getSpawnParts("spawnpartsurvavor")
	local killerSpawns = getSpawnParts("spawnpartkiller")

	local survSpawnIndex = 1
	local killerSpawnIndex = 1

	for _, player in ipairs(allPlayers) do
		local char = player.Character or player.CharacterAdded:Wait()
		wait(0.5)
		if player == killer then
			char.Parent = KillersFolder
			caer:FireClient(player, "killer")

		elseif player == neutral then
			char.Parent = NeutralsFolder
			caer:FireClient(player, "neutral")
		else
			char.Parent = SurvivorsFolder
			caer:FireClient(player, "survivor")
		end
	end

	-- 🕐 Ждём, пока все выберут, или максимум 40 секунд
	local allPlayers = Players:GetPlayers()
	local totalPlayers = #allPlayers
	local elapsed = 0
	local maxWait = 30

	print("[INFO] Ожидание выбора персонажей (макс. 40 сек)...")

	while elapsed < maxWait do
		local chosenCount = 0
		for _, plr in ipairs(allPlayers) do
			if chosenPlayers[plr.UserId] then
				chosenCount += 1
			end
		end

		if chosenCount >= totalPlayers then
			print("[INFO] Все игроки выбрали персонажей!")
			break
		end

		task.wait(1)
		elapsed += 1
	end

	-- после ожидания телепортируем всех
	for _, player in ipairs(allPlayers) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			if char.Parent == KillersFolder and #killerSpawns > 0 then
				local spawn = killerSpawns[killerSpawnIndex]
				char:WaitForChild("HumanoidRootPart").CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
				killerSpawnIndex = killerSpawnIndex % #killerSpawns + 1
			elseif char.Parent == SurvivorsFolder and #survivorSpawns > 0 then
				local spawn = survivorSpawns[survSpawnIndex]
				char:WaitForChild("HumanoidRootPart").CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
				survSpawnIndex = survSpawnIndex % #survivorSpawns + 1
			elseif char.Parent == NeutralsFolder and #survivorSpawns > 0 then
				local spawn = survivorSpawns[survSpawnIndex]
				char:WaitForChild("HumanoidRootPart").CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
				survSpawnIndex = survSpawnIndex % #survivorSpawns + 1
			end
		end
	end

	print("[INFO] Телепорт завершён.")
	-- После телепорта морфим игроков
	for _, player in ipairs(allPlayers) do
		morhpevent:FireClient(player)
	end
	chosenPlayers = {}
	print("🗡 Убийца: " .. killer.Name)
end

-- Событие кастомного уменьшения времени
custartevent.Event:Connect(function(timed)
	print("[EVENT] Custartevent fired, reducing round time by 40")
	currentRoundTime = math.max(currentRoundTime - timed, 0)
end)

-- Главный игровой цикл
while true do
	while #Players:GetPlayers() < minPlayers do
		timeevent:FireAllClients(0) -- можно передавать, что таймер = 0
		task.wait(1) -- даём 1 секунду паузы
	end

	-- ⏳ Интермиссия
	for i = intermissionTime, 1, -1 do
		wait(1)
		visibletime.Value = i
		timeevent:FireAllClients(i)
	end

	-- ⌛ Фаза загрузки (карта + персонажи)
	print("[INFO] Ожидание загрузки персонажей игроков...")

	for _, player in ipairs(Players:GetPlayers()) do
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			player.CharacterAdded:Wait()
			repeat wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		end
	end

	print("[INFO] Все персонажи загружены.")

	-- ⌛ Подгружаем карту
	lastmanvarible = false
	currentMap = Maps[mapIndex]:Clone()
	mapIndex += 1
	if mapIndex > #Maps then
		mapIndex = 1
	end
	currentMap.Parent = game.Workspace
	guimagevent:FireAllClients(currentMap.Name)
	print("[INFO] Карта загружена:", currentMap.Name)

	wait(2)
	assignPlayersToFolders()
	-- ▶️ Старт раунда
	currentRoundTime = roundTime

	-- ⏱ Раунд идёт
	while currentRoundTime > 0 do
		wait(1)
		currentRoundTime -= 1
		timeevent:FireAllClients(currentRoundTime)
		visibletime.Value = currentRoundTime

		checkLastManTrigger()

		-- Проверка победы во время раунда
		if #KillersFolder:GetChildren() == 0 then break end
		if #SurvivorsFolder:GetChildren() == 0 and #NeutralsFolder:GetChildren() == 0 then
			break 
		end
	end

	-- 🔚 Конец раунда
	checkWinner()
	trashdestroy()
	currentMap:Destroy()
	wait(2)

	-- Ресет всех игроков
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			player:LoadCharacter()
		end
	end

	wait(3)
end

