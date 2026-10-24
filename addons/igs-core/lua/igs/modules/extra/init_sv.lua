--[[-------------------------------------------------------------------------
	Чат команды
---------------------------------------------------------------------------]]
scc.add("igs", IGS.UI)
for command in pairs(IGS.C.COMMANDS or {}) do
	scc.add(command, IGS.UI)
end

--[[-------------------------------------------------------------------------
	Консольная команда igs_info
---------------------------------------------------------------------------]]
local print_info = function()
	local info = {
		server_id = bib.get("igs:serverid"),
		server_ip = game.GetIPAddress(),
		igs_version = cookie.GetString("igs_version") or "unset",
		is_unpacked = file.Exists("igs/apinator.lua", "LUA"),
		-- log_tail = (file.Read("igs_errors.txt") or ""):sub(-1000)
	}
	local luainf do
		local inf = debug.getinfo(IGS.GetSign)
		luainf = {
			line_def = inf.linedefined,
			source = inf.source,
			short_src = inf.short_src,
		}
	end
	info.funcinfo = luainf
	print("\n\n" .. util.TableToJSON(info, true) .. "\n\n")

	print("Log Tail:")
	local log_lines = (file.Read("igs_errors.txt") or ""):Split("\n")
	for i = #log_lines - 100, #log_lines do
		print(i, log_lines[i])
	end
end
-- print_info()
concommand.Add("igs_info", function(pl)
	if IsValid(pl) and not pl:IsSuperAdmin() then return end
	print_info()
end)

--[[-------------------------------------------------------------------------
	Консольная команда начисления денег
---------------------------------------------------------------------------]]
concommand.Add("addfunds", function(pl, _, _, argss)
	if IsValid(pl) then
		IGS.prints(Color(240, 173, 78), "", pl:Nick(),  " пытался выполнить ", ("addfunds " .. argss),  " через игровую консоль")
		-- IGS.Notify(pl, "Команда работает только с серверной консоли")
		return
	end

	local sid, amount, note = argss:match("(STEAM_%d:%d:%d+) (%d+) ?(.*)")
	amount = tonumber(amount)
	if note == "" then note = nil end

	if not amount then
		IGS.prints("Формат команды нарушен. Пример:\n", "addfunds STEAM_0:1:2345678 10 Необязательное примечание")
		return
	end

	local targ = player.GetBySteamID(sid)
	if targ then
		targ:AddIGSFunds(amount, note, function()
			IGS.prints("Транзакция успешно проведена. ", "Баланс игрока: " .. PL_MONEY( targ:IGSFunds() ))
		end)

	-- Игрок оффлайн
	else
		IGS.Transaction(util.SteamIDTo64(sid), amount, note, function()
			IGS.prints("Транзакция успешно проведена, но игрок не на сервере")
		end)

	end
end)


concommand.Add("igs_reload", function(pl, _, args)
	if pl == NULL then -- console only
		IGS.prints(args[1] and "Super Reload" or "Casual Reload")
		IGS.sh(args[1] and "autorun/l_ingameshop.lua" or "igs/launcher.lua")
	end
end)


--[[-------------------------------------------------------------------------
	Открытие интерфейса кнопкой на клаве
---------------------------------------------------------------------------]]
-- https://wiki.facepunch.com/gmod/Enums/KEY
hook.Add("PlayerButtonDown", "IGS.UI", function(pl, iButton)
	if iButton == IGS.C.MENUBUTTON then
		scc.run(pl, "igs")
	end
end)


--[[-------------------------------------------------------------------------
	Глобальное оповещение о покупке итемов
	https://trello.com/c/SvZ8UE0F/472-сообщение-о-покупке
---------------------------------------------------------------------------]]
hook.Add("IGS.PlayerPurchasedItem", "IGS.BroadcastPurchase", function(pl, ITEM)
	if IGS.C.BroadcastPurchase == false then return end -- TODO сделать модулем

	IGS.NotifyAll(pl:Nick() .. " купил " .. ITEM:Name())
end)


--[[-------------------------------------------------------------------------
	Оповещение о пополнении счета
	https://trello.com/c/6rMMH3cn/483-сообщение-о-пополнении-счета
---------------------------------------------------------------------------]]

hook.Add("IGS.PlayerDonate", "ThanksForDonate", function(pl, rub)
	local score = pl.igs_score -- TODO: make netvar

	IGS.Notify(pl, Format("Спасибо вам за пополнение счета. " ..
		"Ваш новый Score на всех проектах - %d. " ..
		"Что такое Score: vk.cc/caHTZi", score))

	local rub_str  = PL_MONEY(rub)
	local full_str = Format("%s пополнил счет на %s. Его новый Score: %s", pl:Nick(), rub_str, score)

	IGS.NotifyAll(full_str)
end)

hook.Add("IGS.PlayerPurchasesLoaded", "BalanceRemember", function(pl)
	local balance = pl:IGSFunds()
	if balance >= 10 then
		timer.Simple(10, function()
			if not IsValid(pl) then return end
			IGS.Notify(pl, "Вы можете потратить " .. IGS.SignPrice(balance) .. " через /donate")
			IGS.Notify(pl, "Ваш Score " .. (pl.igs_score or 0) .. ". Подробнее: vk.cc/caHTZi") -- or 0 на всякий случай
		end)
	end
end)