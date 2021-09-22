--debug = "hi"

--why did i do this
local function not_has(table, val)
    for _, value in pairs(table) do
        if value == val then
            return false
        end
    end

    return true
end

local function override(notes, n, bpm, signature)
    local snaptimingpoints = {}
    local normaltimingpoints = {}
    local currenttimingpoints = {}

    --maybe jank way of removing redundant notes copied from that other plugin
    local starttimes = {}

    for _,note in pairs(notes) do
        if not_has(starttimes, note.StartTime) then
            table.insert(starttimes, note.StartTime)
        end
    end

    for _, starttime in pairs(starttimes) do
        --remove timing points within time interval of new timing points
        for _, tp in pairs(map.TimingPoints) do
            if starttime - SNAP_INTERVAL <= tp.StartTime and tp.StartTime <= starttime + NORMAL_INTERVAL then
                table.insert(currenttimingpoints, tp)
            end
            
            if tp.StartTime > starttime + NORMAL_INTERVAL then break end
        end
        
        if n == 1 and signature == 3 then
            table.insert(snaptimingpoints, utils.CreateTimingPoint(starttime, bpm, time_signature.Triple, hide))
        elseif n == 1 then
            table.insert(snaptimingpoints, utils.CreateTimingPoint(starttime, bpm, time_signature.Quadruple, hide))
        elseif signature == 3 then
            table.insert(snaptimingpoints, utils.CreateTimingPoint(starttime - SNAP_INTERVAL, BIG_NUMBER / n, time_signature.Triple, hide))
            table.insert(normaltimingpoints, utils.CreateTimingPoint(starttime + NORMAL_INTERVAL, bpm, time_signature.Triple, hide))
        else
            table.insert(snaptimingpoints, utils.CreateTimingPoint(starttime - SNAP_INTERVAL, BIG_NUMBER / n, time_signature.Quadruple, hide))
            table.insert(normaltimingpoints, utils.CreateTimingPoint(starttime + NORMAL_INTERVAL, bpm, time_signature.Quadruple, hide))
        end
    end

    --remove any timing points from a previous override
    if #currenttimingpoints != 0 then
        actions.RemoveTimingPointBatch(currenttimingpoints)
    end

    local queue = {}
    --place normal timing points first so that game doesn't lag like hell from 60000 BPM timing points
    --actions.PlaceTimingPointBatch(normaltimingpoints)
    table.insert(queue, utils.CreateEditorAction(action_type.AddTimingPointBatch, normaltimingpoints))

    --actions.PlaceTimingPointBatch(snaptimingpoints)
    table.insert(queue, utils.CreateEditorAction(action_type.AddTimingPointBatch, snaptimingpoints))

    actions.PerformBatch(queue)
end

function signatureToInt(signature)
    if signature == time_signature.Quadruple then return 4
    elseif signature == time_signature.Triple then return 3
    else return 4 end
end

hide = true

function draw()
    imgui.Begin("Beat Snap Color Override")

    --state.IsWindowHovered = imgui.IsWindowHovered()

    local notes = state.SelectedHitObjects

    local n = state.GetValue("n") or 1
    local bpm = state.GetValue("bpm") or map.GetCommonBpm()
    local signature = state.GetValue("signature") or 4
    local useCurrentBpm = state.GetValue("useCurrentBpm")
    if useCurrentBpm == null then useCurrentBpm = true end
    
    if utils.IsKeyDown(keys.LeftAlt) then hide = false end
    if utils.IsKeyUp(keys.LeftAlt) then hide = true end

    SNAP_INTERVAL = .125 --Timing point influencing beat snap color will be placed .125 ms behind note
    NORMAL_INTERVAL = .125 --Timing point returning timing to "normal" will be placed 2^-3 = .125 ms after note
    BIG_NUMBER = 60000 / SNAP_INTERVAL --60k beats per minutes = 1k beats per second = 1 beat per ms

    _, n = imgui.InputInt("1/n Snap", n)
    _, bpm = imgui.InputFloat("BPM", bpm, 1)
    _, signature = imgui.InputInt("Signature", signature, 1)
    if signature < 3 then signature = 3 end
    if signature > 4 then signature = 4 end

    _, hide = imgui.Checkbox("Hide Timing Lines?", hide)
    _, useCurrentBpm = imgui.Checkbox("Use current BPM?", useCurrentBpm)
    
    if useCurrentBpm and notes[1] then
        local tp = map.GetTimingPointAt(notes[1].StartTime + 1)
        bpm = tp.Bpm
        signature = signatureToInt(tp.Signature)
    end

    if imgui.Button("click me") then
        override(notes, n, bpm, signature)
    end

    --I hate this
    if not utils.IsKeyDown(keys.LeftControl) and not utils.IsKeyDown(keys.RightControl) then
        if utils.IsKeyPressed(81) then --qwert
            override(notes, 1, bpm, signature)
        elseif utils.IsKeyPressed(87) then
            override(notes, 2, bpm, signature)
        elseif utils.IsKeyPressed(69) then --nice
            override(notes, 4, bpm, signature)
        elseif utils.IsKeyPressed(82) then
            override(notes, 8, bpm, signature)
        elseif utils.IsKeyPressed(84) then
            override(notes, 16, bpm, signature)
        elseif utils.IsKeyPressed(65) then --asdfg
            override(notes, 3, bpm, signature)
        elseif utils.IsKeyPressed(83) then
            override(notes, 6, bpm, signature)
        elseif utils.IsKeyPressed(68) then
            override(notes, 12, bpm, signature)
        elseif utils.IsKeyPressed(70) then
            override(notes, 24, bpm, signature)
        elseif utils.IsKeyPressed(71) then
            override(notes, 48, bpm, signature)
        end
    end

    imgui.Text("Press qwert to override with n = 1, 2, 4, 8, 16")
    imgui.Text("Press asdfg to override with n = 3, 6, 12, 24, 48")
    imgui.Text("Hold Alt to toggle Hide Timing Lines option")

    --imgui.Text(debug)

    state.SetValue("n", n)
    state.SetValue("bpm", bpm)
    state.SetValue("signature", signature)
    state.SetValue("useCurrentBpm", useCurrentBpm)

    imgui.End()
end