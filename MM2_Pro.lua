--// CONTINUACIÓN DE LAS PÁGINAS (CONTENIDO)
local pg1, pg2, pg3, pg4, pg5, pg6 = pages[1], pages[2], pages[3], pages[4], pages[5], pages[6]

-- PÁGINA 1: MAIN (COMBAT)
makeSection(pg1, "Combate Principal")
makeToggle(pg1, "Aimbot Murder", "Apunta automáticamente al asesino", false, function(v) Toggles.Aimbot = v end)
makeToggle(pg1, "Auto Gun", "Recoge el arma automáticamente", false, function(v) Toggles.AutoGun = v end)
makeToggle(pg1, "Auto Dodge", "Esquiva al asesino si se acerca", false, function(v) Toggles.AutoDodge = v end)

-- PÁGINA 2: PLAYER
makeSection(pg2, "Movimiento")
makeSlider(pg2, "WalkSpeed", true, 16, 200, 16, function(v) 
    Settings.WalkSpeed = v 
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = v
    end
end)
makeSlider(pg2, "JumpPower", true, 50, 250, 50, function(v) 
    Settings.JumpPower = v 
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = v
    end
end)
makeToggle(pg2, "Fly Mode", "Volar (WASD + Espacio/Ctrl)", true, function(v) 
    Toggles.Fly = v 
    if v then startFly() else stopFly() end
end)
makeSlider(pg2, "Fly Speed", true, 10, 300, 60, function(v) Settings.FlySpeed = v end)
makeToggle(pg2, "Noclip", "Atravesar paredes", true, function(v) Toggles.Noclip = v end)

-- PÁGINA 3: ESP (VISUALS)
makeSection(pg3, "Revelar Jugadores")
makeToggle(pg3, "ESP Murder", "Resaltar al asesino en Rojo", false, function(v) Toggles.ESP_Murder = v end)
makeToggle(pg3, "ESP Sheriff", "Resaltar al sheriff en Azul", true, function(v) Toggles.ESP_Sheriff = v end)
makeToggle(pg3, "ESP Innocent", "Resaltar inocentes en Verde", false, function(v) Toggles.ESP_Innocent = v end)
makeSection(pg3, "Detalles")
makeToggle(pg3, "Nombres", "Mostrar nombres sobre la cabeza", false, function(v) Toggles.ESP_Names = v end)
makeToggle(pg3, "Líneas (Tracers)", "Líneas hacia los jugadores", false, function(v) Toggles.ESP_Lines = v end)

-- PÁGINA 4: KILL (MURDER ONLY)
makeSection(pg4, "Funciones de Asesino")
makeToggle(pg4, "Auto Kill Sheriff", "Mata al sheriff instantáneamente", false, function(v) Toggles.AutoKillSheriff = v end)
makeToggle(pg4, "Auto Kill All", "Mata a todos (Riesgo de Ban)", false, function(v) Toggles.AutoKillAll = v end)
makeButton(pg4, "Equipar Cuchillo", "Saca el cuchillo rápidamente", false, function()
    local k = getKnife()
    if k then k.Parent = player.Character end
end)

-- PÁGINA 5: MISC
makeSection(pg5, "Utilidad")
makeToggle(pg5, "Auto Coins", "Farmear monedas automáticamente", true, function(v) Toggles.AutoCoins = v end)
makeToggle(pg5, "Anti-AFK", "Evita que el juego te saque", true, function(v) Toggles.AntiAFK = v end)
makeToggle(pg5, "Auto Hide", "Huye del asesino automáticamente", true, function(v) Toggles.AutoHide = v end)

-- PÁGINA 6: TROLL
makeSection(pg6, "Diversión")
makeToggle(pg6, "Spin Bot", "Girar como loco", false, function(v) Toggles.Spinner = v end)
makeSlider(pg6, "Spin Speed", false, 1, 100, 8, function(v) Settings.SpinSpeed = v end)
makeToggle(pg6, "Headless (Local)", "Te quita la cabeza visualmente", false, function(v) 
    Toggles.Headless = v 
    if not v then removeHeadless() end
end)

-- NOTIFICACIÓN DE CARGA
print("══════════════════════════════")
print("PRO MM2 CARGADO EXITOSAMENTE")
print("Desarrollado para Gemini User")
print("══════════════════════════════")
