cam = {
    inAnimationCam = false,
    cams = {},
    camsCache = {},

    create = function(name)
        if cam.cams[name] == nil then
            local c = CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
            cam.cams[name] = c
            cam.camsCache[name] = {
                pos = vector3(0.0, 0.0, 0.0)
            }
        end
    end,

    Get = function(name)
        return cam.cams[name], cam.camsCache[name]
    end,

    delete = function(name)
        if cam.cams[name] ~= nil then
            if IsCamActive(cam.cams[name]) then
                RenderScriptCams(0, 0, 0, 0, 1)
                ClearFocus()
            end
            SetCamActive(cam.cams[name], false)
            DestroyCam(cam.cams[name], false)
            cam.cams[name] = nil
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (delete)")
        end
    end,    

    setActive = function(name, bool)
        if cam.cams[name] ~= nil then
            SetCamActive(cam.cams[name], bool)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (setActive)")
        end
    end,

    setPos = function(name, pos)
        if cam.cams[name] ~= nil then
            SetFocusPosAndVel(pos.xyz, 0.0, 0.0, 0.0)
            SetCamCoord(cam.cams[name], pos.xyz)
            cam.camsCache[name].pos = pos
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (setPos)")
        end
    end,

    GetPos = function(name)
        if cam.cams[name] ~= nil then
            return cam.camsCache[name].pos
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (GetPos)")
        end
    end,

    setFov = function(name, fov)
        if cam.cams[name] ~= nil then
            SetCamFov(cam.cams[name], fov)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (setFov)")
        end
    end,

    lookAtCoords = function(name, pos)
        if cam.cams[name] ~= nil then
            PointCamAtCoord(cam.cams[name], pos.xyz)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (lookAtCoords)")
        end
    end,

    lookAtEntity = function(name, entity, offsets)
        if cam.cams[name] ~= nil then
            if offsets == nil then
                offsets = {1, 1, 1}
            end
            PointCamAtEntity(cam.cams[name], entity, offsets[1], offsets[2], offsets[3])
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (lookAtEntity)")
        end
    end,

    attachToEntity = function(name, entity, xOffset, yOffset, zOffset, isRelative)
        if cam.cams[name] ~= nil then
            AttachCamToEntity(cam.cams[name], entity, xOffset, yOffset, zOffset, isRelative)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (attachToEntity)")
        end
    end,

    attachToEntityBone = function(name, ped, boneIndex, x, y, z, heading)
        if cam.cams[name] ~= nil then
            AttachCamToPedBone(cam.cams[name], ped, boneIndex, x, y, z, heading)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (attachToEntityBone)")
        end
    end,

    attachToVehicleBone = function(name, vehicle, boneIndex, relativeRotation, rotX, rotY, rotZ, offX, offY, offZ, fixedDirection)
        if cam.cams[name] ~= nil then
            AttachCamToVehicleBone(cam.cams[name], vehicle, boneIndex, relativeRotation, rotX, rotY, rotZ, offX, offY, offZ, fixedDirection)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (attachToVehicleBone)")
        end
    end,

    render = function(name, render, animation, time)
        if cam.cams[name] ~= nil then
            SetCamActive(cam.cams[name], true)
            RenderScriptCams(render, animation, time, 1, 1)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (render)")
        end
    end,

    switchToCam = function(name, oldCam, time)
        if cam.cams[name] ~= nil then
            if cam.cams[oldCam] ~= nil then
                SetCamActive(cam.cams[name], true)
                if time and time > 0 then
                    SetCamActiveWithInterp(cam.cams[name], cam.cams[oldCam], time, 1, 1)
                else
                    SetCamActive(cam.cams[oldCam], false)
                end
            end
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (switchToCam)")
        end
    end,

    rotation = function(name, rotX, rotY, rotZ)
        if cam.cams[name] ~= nil then
            SetCamRot(cam.cams[name], rotX, rotY, rotZ, 2)
        else
            print("^2WARNING: ^7La cam "..name.." n'éxiste pas ! (rotation)")
        end
    end,
}
