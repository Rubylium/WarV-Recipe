LoadAnimation = {}
LoadAnimation.AnimationStarted = false


function LoadAnimation.StartLoadAnimation()
    if Matchmaking.selectedMap.NewCamAnimations ~= nil then
        LoadAnimation.AnimationStarted = true
        local map = Matchmaking.selectedMap
        local camsInfo = map.NewCamAnimations

        StopAllSounds()
        PlayCustomSound("loading_music/warv_StaticHorizon.mp3", Settings.MusicsVolume, true)


        cam.create("MAP_ANIM_1")
        cam.create("MAP_ANIM_2")

        if not MapEnv.ApplyClock(map) then
            NetworkOverrideClockTime(Matchmaking.data.gamemode == "TRON DEATHMATCH" and 23 or 12, 0, 0)
        end
        TriggerScreenblurFadeOut(0)
        while UiHandler.IsPageActive("map_loading") do

            for k,v in pairs(camsInfo) do
                SetFocusArea(v.cam1Pos, 0.0, 0.0, 0.0)
                cam.setPos("MAP_ANIM_1", v.cam1Pos)
                cam.setFov("MAP_ANIM_1", v.cam1Fov)
                cam.lookAtCoords("MAP_ANIM_1", v.cam1LookAt)
                cam.render("MAP_ANIM_1", true, false, 0)

                cam.setPos("MAP_ANIM_2", v.cam2Pos)
                cam.setFov("MAP_ANIM_2", v.cam2Fov)
                cam.lookAtCoords("MAP_ANIM_2", v.cam2LookAt)
                cam.switchToCam("MAP_ANIM_2", "MAP_ANIM_1", v.time + 3000)

                RealWait(v.time, function(cb)

                    if not MapEnv.ApplyClock(map) then
                        NetworkOverrideClockTime(Matchmaking.data.gamemode == "TRON DEATHMATCH" and 23 or 12, 0, 0)
                    end

                    if UiHandler.IsPageActive("map_loading") then
                        cb(false)
                    else
                        cb(true)
                    end
                    DisableAllControlActions(0)
                end)
                ClearFocus()
            end
            Wait(0)
        end

        LoadAnimation.AnimationStarted = false
        cam.delete("MAP_ANIM_1")
        cam.delete("MAP_ANIM_2")
    else
        LoadAnimation.AnimationStarted = false
    end
end
