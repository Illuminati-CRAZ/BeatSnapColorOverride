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

local function override(notes, n, bpm)
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

    for _,starttime in pairs(starttimes) do
        --finding timing points from previous override
        local currenttp1 = map.GetTimingPointAt(starttime - SNAP_INTERVAL)
        local currenttp2 = map.GetTimingPointAt(starttime + NORMAL_INTERVAL)

        --timing points currently must be created with integer starttimes
        table.insert(snaptimingpoints, utils.CreateTimingPoint(starttime - SNAP_INTERVAL, BIG_NUMBER / n, currenttp1.Signature, hide))
        table.insert(normaltimingpoints, utils.CreateTimingPoint(starttime + NORMAL_INTERVAL, bpm, currenttp1.Signature, hide))

        if currenttp1.StartTime == starttime - SNAP_INTERVAL then
            table.insert(currenttimingpoints, currenttp1)
        end
        if currenttp2.StartTime == starttime + NORMAL_INTERVAL then
            table.insert(currenttimingpoints, currenttp2)
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

hide = true

function draw()
    imgui.Begin("Beat Snap Color Override")

    --state.IsWindowHovered = imgui.IsWindowHovered()

    local notes = state.SelectedHitObjects

    local n = state.GetValue("n") or 1
    local bpm = state.GetValue("bpm") or map.GetCommonBpm()

    SNAP_INTERVAL = .125 --Timing point influencing beat snap color will be placed .125 ms behind note
    NORMAL_INTERVAL = .125 --Timing point returning timing to "normal" will be placed 2^-3 = .125 ms after note
    BIG_NUMBER = 60000 / SNAP_INTERVAL --60k beats per minutes = 1k beats per second = 1 beat per ms

    _, n = imgui.InputInt("1/n Snap", n)
    _, bpm = imgui.InputInt("BPM", bpm)

    _, hide = imgui.Checkbox("Hide Timing Lines?", hide)

    if imgui.Button("click me") then
        override(notes, n, bpm)
    end

    --I hate this
    if utils.IsKeyPressed(81) then --qwert
        override(notes, 1, bpm)
    elseif utils.IsKeyPressed(87) then
        override(notes, 2, bpm)
    elseif utils.IsKeyPressed(69) then --nice
        override(notes, 4, bpm)
    elseif utils.IsKeyPressed(82) then
        override(notes, 8, bpm)
    elseif utils.IsKeyPressed(84) then
        override(notes, 16, bpm)
    elseif utils.IsKeyPressed(65) then --asdfg
        override(notes, 3, bpm)
    elseif utils.IsKeyPressed(83) then
        override(notes, 6, bpm)
    elseif utils.IsKeyPressed(68) then
        override(notes, 12, bpm)
    elseif utils.IsKeyPressed(70) then
        override(notes, 24, bpm)
    elseif utils.IsKeyPressed(71) then
        override(notes, 48, bpm)
    end

    imgui.Text("Press qwert to override with n = 1, 2, 4, 8, 16")
    imgui.Text("Press asdfg to override with n = 3, 6, 12, 24, 48")

    --imgui.Text(debug)

    state.SetValue("n", n)
    state.SetValue("bpm", bpm)

    imgui.End()
end