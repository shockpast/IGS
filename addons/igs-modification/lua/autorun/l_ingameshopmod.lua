file.CreateDir("igs")

IGS_REPO = "shockpast/IGS"
if not IGS_REPO or file.Exists("autorun/l_ingameshop.lua", "LUA") then return end

if SERVER then
	if cookie.GetString("igs_version") == nil then
		cookie.Set("igs_version", "custom")
	end
elseif CLIENT then
	CreateConVar("igs_version", "custom", {FCVAR_REPLICATED})
end
