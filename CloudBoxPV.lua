-- ====================================================
--                 DIYU'S CLOUDBOX (UI Edition)
-- ====================================================
-- By default this uses DIYU'S OFFICIAL music library —
-- just copy-paste this whole file and run it, no changes
-- needed.
--
-- Want to use YOUR OWN songs instead? Edit the 3 lines
-- below in the "MUSIC SOURCE" section. Everything else
-- in this file you can leave alone.
--
-- Controls: mouse only.
--   - Tap a song to select it, tap again (or PLAY) to play
--   - Drag/tap the volume bar to change volume
--   - Scroll wheel or the scrollbar moves through the list
--
-- Requires an ADVANCED computer/pocket computer for color,
-- and a speaker block placed next to the computer.
-- ====================================================

-- ============ MUSIC SOURCE (edit this to use your own library) ============
-- These 3 lines point at a GitHub repo. To use your own:
--   1. Go to github.com and create a repo (or use an existing one).
--   2. Upload your .dfpwm song files to it.
--   3. Add a file called "index.txt" listing one song filename per line.
--   4. Look at your repo's URL: github.com/YOUR_USERNAME/YOUR_REPO
--      Put YOUR_USERNAME and YOUR_REPO below, exactly as they appear there.
--   5. GITHUB_BRANCH is almost always "main" — leave it unless you know
--      your repo uses something else (like "master").

local GITHUB_USERNAME = "DiyuWupo"   -- <-- your GitHub username goes here
local GITHUB_REPO     = "ES"         -- <-- your GitHub repo name goes here
local GITHUB_BRANCH   = "main"       -- <-- almost always "main"

-- ============ COLOR SCHEME (edit this to change how it looks) ============
-- Valid color names in CC:Tweaked: white, orange, magenta, lightBlue,
-- yellow, lime, pink, gray, lightGray, cyan, purple, blue, brown,
-- green, red, black
-- (Only matters on an Advanced computer/monitor — regular ones are
-- black-and-white no matter what you put here.)

local THEME_BACKGROUND  = colors.black      -- main background
local THEME_TEXT        = colors.white      -- normal text
local THEME_ACCENT      = colors.purple     -- header bar, selected song, volume bar, scrollbar
local THEME_DIVIDER     = colors.gray       -- divider lines, empty part of volume bar/scrollbar
local THEME_BUTTON_BG   = colors.lightGray  -- PLAY/STOP/QUIT button background
local THEME_BUTTON_TEXT = colors.black      -- PLAY/STOP/QUIT button text
local THEME_ERROR       = colors.red        -- error messages
local THEME_WARNING     = colors.yellow     -- "SETUP NEEDED" message

-- ====================================================
-- AUTO-UPDATE
-- Every launch, this checks a Pastebin paste for a newer
-- version of THIS SCRIPT and updates itself if one is found.
--
-- This is separate from your music library above — it's
-- just how Diyu pushes out bug fixes and new features.
-- ====================================================
local PASTEBIN_ID = "7rvEUn3B"   -- <-- change only if this is YOUR OWN forked paste
local scriptArgs = { ... }

local function selfUpdate()
    local url = "https://pastebin.com/raw/" .. PASTEBIN_ID
    http.request(url)
    local timer = os.startTimer(5)
    local newCode = nil

    while true do
        local event, p1, p2 = os.pullEvent()
        if event == "http_success" and p1 == url then
            newCode = p2.readAll()
            p2.close()
            break
        elseif event == "http_failure" and p1 == url then
            return false, "connection failed"
        elseif event == "timer" and p1 == timer then
            return false, "timed out"
        end
    end

    if not newCode or #newCode == 0 then
        return false, "empty paste"
    end

    -- Bail out if Pastebin gave us something that isn't actually our
    -- script (e.g. a rate-limit/"please wait" page instead of raw code).
    -- Real code always contains this marker line; a blocked page won't.
    if not newCode:find("DIYU'S CLOUDBOX", 1, true) then
        return false, "not valid script content"
    end

    local programPath = shell.getRunningProgram()
    local currentFile = fs.open(programPath, "r")
    local currentCode = currentFile.readAll()
    currentFile.close()

    if newCode ~= currentCode then
        local writeFile = fs.open(programPath, "w")
        writeFile.write(newCode)
        writeFile.close()
        return true
    end
    return false
end

if scriptArgs[1] ~= "skipupdate" then
    term.clear()
    term.setCursorPos(1,1)
    print("Checking for updates...")
    local updated, updateErr = selfUpdate()
    if updated then
        print("Update found! Restarting with new version...")
        sleep(1)
        shell.run(shell.getRunningProgram(), "skipupdate")
        return
    elseif updateErr then
        print("Update check skipped (" .. updateErr .. ")")
        sleep(1)
    end
end

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

if not speaker then
    error("No speaker attached! Place a speaker block next to the computer.")
end

local monitor = peripheral.find("monitor")
if monitor then
    monitor.setTextScale(0.5)
    term.redirect(monitor)
end

local w, h = term.getSize()
local hasColor = term.isColor()

local function setColors(bg, fg)
    if hasColor then
        term.setBackgroundColor(bg)
        term.setTextColor(fg)
    end
end

local function clearScreen(bg)
    setColors(bg or THEME_BACKGROUND, THEME_TEXT)
    term.clear()
end

local function centerText(y, text, bg, fg)
    setColors(bg or THEME_BACKGROUND, fg or THEME_TEXT)
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    term.setCursorPos(x, y)
    term.write(text)
end

-- ============ Setup check ============
if GITHUB_USERNAME == "" or GITHUB_REPO == "" then
    clearScreen(THEME_BACKGROUND)
    centerText(math.floor(h/2) - 2, "SETUP NEEDED", THEME_BACKGROUND, THEME_WARNING)
    centerText(math.floor(h/2), "GITHUB_USERNAME or GITHUB_REPO is blank.", THEME_BACKGROUND, THEME_TEXT)
    centerText(math.floor(h/2) + 1, "Scroll to the top of this file and fill", THEME_BACKGROUND, THEME_TEXT)
    centerText(math.floor(h/2) + 2, "in the MUSIC SOURCE section.", THEME_BACKGROUND, THEME_TEXT)
    error("GITHUB_USERNAME / GITHUB_REPO can't be blank.")
end

-- ============ Loading screen ============
clearScreen(THEME_BACKGROUND)
centerText(math.floor(h/2), "Connecting to Diyu's CloudBox...", THEME_BACKGROUND, THEME_ACCENT)

local base_url = "https://raw.githubusercontent.com/" .. GITHUB_USERNAME .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/"
local response = http.get(base_url .. "index.txt")

if not response then
    clearScreen(THEME_BACKGROUND)
    centerText(math.floor(h/2) - 1, "CONNECTION ERROR", THEME_BACKGROUND, THEME_ERROR)
    centerText(math.floor(h/2), "Cannot reach index.txt", THEME_BACKGROUND, THEME_TEXT)
    centerText(math.floor(h/2) + 1, "Verify repository is PUBLIC", THEME_BACKGROUND, THEME_TEXT)
    error()
end

local songs = {}
for line in response.readLine do
    local cleanLine = line:gsub("%s+$", ""):gsub("\r", "")
    if #cleanLine > 0 and not cleanLine:match("^<!DOCTYPE") and not cleanLine:match("^<html") then
        table.insert(songs, { name = cleanLine, url = base_url .. cleanLine })
    end
end
response.close()

if #songs == 0 then
    clearScreen(THEME_BACKGROUND)
    centerText(math.floor(h/2), "index.txt is empty or malformed", THEME_BACKGROUND, THEME_ERROR)
    error()
end

-- ============ UI drawing ============
local HEADER_H = 4
local FOOTER_H = 2
local LIST_TOP = HEADER_H + 1
local LIST_BOTTOM = h - FOOTER_H
local LIST_H = LIST_BOTTOM - LIST_TOP + 1

-- button hitboxes get filled in by drawFooter each time it draws
local buttons = {}
local sliderBar = { x1 = 1, x2 = 1, y = 1 }

local volume = 1.0
local VOLUME_STEP = 0.05
local VOLUME_MIN = 0
local VOLUME_MAX = 1   -- CC:Tweaked speakers can technically go up to 3, but anything
                       -- above 1 (100%) amplifies past the audio's natural range and
                       -- clips/distorts — 1 is the loudest it can go without crackling
--
-- NOTE: even at 100% (max), some songs may still have a faint "record
-- player" hiss/crackle, especially at higher volume. That's not a bug
-- in this script — DFPWM (the audio format speakers use) is a lossy
-- 1-bit codec that bakes in a bit of quantization noise at encode time.
-- It's just replaying exactly what's in the file. If a specific song
-- is noticeably worse than others, re-encoding it at a lower/more
-- normalized volume before converting to .dfpwm usually helps.

local function statusText()
    local pct = math.floor(volume * 100 + 0.5)
    return #songs .. " tracks | Vol " .. pct .. "%"
end

local function drawVolumeSlider()
    local y = 3
    local label = " Vol "
    local pctText = math.floor(volume * 100 + 0.5) .. "% "
    local barX1 = 1 + #label
    local barX2 = w - #pctText
    local barWidth = math.max(1, barX2 - barX1 + 1)

    setColors(THEME_BACKGROUND, THEME_TEXT)
    term.setCursorPos(1, y)
    term.write(label)

    local fillWidth = math.floor((volume - VOLUME_MIN) / (VOLUME_MAX - VOLUME_MIN) * barWidth + 0.5)
    fillWidth = math.max(0, math.min(barWidth, fillWidth))

    if fillWidth > 0 then
        setColors(THEME_ACCENT, THEME_TEXT)
        term.setCursorPos(barX1, y)
        term.write(string.rep(" ", fillWidth))
    end
    if fillWidth < barWidth then
        setColors(THEME_DIVIDER, THEME_TEXT)
        term.setCursorPos(barX1 + fillWidth, y)
        term.write(string.rep(" ", barWidth - fillWidth))
    end

    setColors(THEME_BACKGROUND, THEME_TEXT)
    term.setCursorPos(barX2 + 1, y)
    term.write(pctText)

    sliderBar = { x1 = barX1, x2 = barX2, y = y }
end

local function drawHeader(status)
    setColors(THEME_ACCENT, THEME_TEXT)
    for y = 1, HEADER_H - 1 do
        term.setCursorPos(1, y)
        term.write(string.rep(" ", w))
    end
    centerText(1, "== DIYU'S CLOUDBOX ==", THEME_ACCENT, THEME_TEXT)
    centerText(2, status or "", THEME_ACCENT, THEME_TEXT)

    drawVolumeSlider()

    setColors(THEME_DIVIDER, THEME_TEXT)
    term.setCursorPos(1, HEADER_H)
    term.write(string.rep("-", w))
end

local function drawButton(label, x, y)
    local text = "[ " .. label .. " ]"
    setColors(THEME_BUTTON_BG, THEME_BUTTON_TEXT)
    term.setCursorPos(x, y)
    term.write(text)
    buttons[label] = { x1 = x, x2 = x + #text - 1, y = y }
end

local function drawFooter()
    buttons = {}
    setColors(THEME_DIVIDER, THEME_TEXT)
    term.setCursorPos(1, h - FOOTER_H + 1)
    term.write(string.rep("-", w))

    setColors(THEME_BACKGROUND, THEME_BUTTON_BG)
    term.setCursorPos(1, h)
    term.write(string.rep(" ", w))

    local labels = { "PLAY", "STOP", "QUIT" }
    local totalLen = 0
    for _, l in ipairs(labels) do totalLen = totalLen + #("[ " .. l .. " ]") + 2 end
    local x = math.max(1, math.floor((w - totalLen) / 2) + 1)

    for _, l in ipairs(labels) do
        drawButton(l, x, h)
        x = x + #("[ " .. l .. " ]") + 2
    end
end

local function drawList(selected, status)
    clearScreen(THEME_BACKGROUND)
    drawHeader(status)
    drawFooter()

    local startIdx = math.max(1, selected - math.floor(LIST_H/2))
    local endIdx = math.min(#songs, startIdx + LIST_H - 1)
    startIdx = math.max(1, endIdx - LIST_H + 1)

    for i = startIdx, endIdx do
        local y = LIST_TOP + (i - startIdx)
        local song = songs[i]
        local label = " " .. song.name .. string.rep(" ", math.max(0, w - #song.name - 1))
        if #label > w then label = label:sub(1, w) end

        if i == selected then
            setColors(THEME_ACCENT, THEME_TEXT)
        else
            setColors(THEME_BACKGROUND, THEME_TEXT)
        end
        term.setCursorPos(1, y)
        term.write(label)
    end

    -- simple scrollbar
    if #songs > LIST_H and hasColor then
        local barHeight = math.max(1, math.floor(LIST_H * LIST_H / #songs))
        local barPos = math.floor((LIST_H - barHeight) * (selected - 1) / math.max(1, #songs - 1))
        for i = 0, LIST_H - 1 do
            term.setCursorPos(w, LIST_TOP + i)
            if i >= barPos and i < barPos + barHeight then
                setColors(THEME_ACCENT, THEME_ACCENT)
            else
                setColors(THEME_DIVIDER, THEME_DIVIDER)
            end
            term.write(" ")
        end
    end

    return startIdx, endIdx
end

local function clickedButton(label, x, y)
    local b = buttons[label]
    if not b then return false end
    return y == b.y and x >= b.x1 and x <= b.x2
end

local function onSlider(x, y)
    return y == sliderBar.y and x >= sliderBar.x1 and x <= sliderBar.x2
end

local function volumeFromX(x)
    local barWidth = math.max(1, sliderBar.x2 - sliderBar.x1)
    local rel = (x - sliderBar.x1) / barWidth
    rel = math.max(0, math.min(1, rel))
    return VOLUME_MIN + rel * (VOLUME_MAX - VOLUME_MIN)
end

-- ============ Playback ============
local currentAudio = nil
local stopRequested = false
local jumpToIndex = nil   -- set if the user clicks a different song mid-playback
local selected = 1
local startIdx, endIdx = drawList(selected, statusText())
local quitRequested = false

local function scrollBarIndexFromY(y)
    local rel = (y - LIST_TOP) / math.max(1, (LIST_BOTTOM - LIST_TOP))
    rel = math.max(0, math.min(1, rel))
    return math.floor(rel * (#songs - 1) + 0.5) + 1
end

local function playSong(index)
    stopRequested = false
    jumpToIndex = nil
    selected = index
    startIdx, endIdx = drawList(selected, "Streaming: " .. songs[index].name)

    local audioResponse = http.get(songs[index].url, nil, true)
    if not audioResponse then
        drawList(selected, "Error downloading song file.")
        sleep(2)
        return
    end

    currentAudio = audioResponse
    local decoder = dfpwm.make_decoder()

    -- Peek at the start of the file before decoding anything. If GitHub
    -- served us a Git LFS pointer (happens automatically for large files)
    -- or an HTML error page instead of real audio, decoding it as DFPWM
    -- produces a harsh screech and dies almost instantly. Catch that here
    -- instead and skip the track with a clear message.
    local chunk = audioResponse.read(16 * 1024)
    if chunk then
        local head = chunk:sub(1, 200)
        if head:find("git%-lfs") or head:find("<!DOCTYPE") or head:find("<html") then
            audioResponse.close()
            currentAudio = nil
            drawList(selected, "Skipped: not a real audio file (check Git LFS on this repo)")
            sleep(3)
            return
        end
    end

    while not stopRequested do
        if not chunk then break end

        local decoded = decoder(chunk)
        local sent = speaker.playAudio(decoded, volume)
        while not sent and not stopRequested do
            os.startTimer(0.05)
            local ev = { os.pullEvent() }

            if ev[1] == "speaker_audio_empty" then
                sent = speaker.playAudio(decoded, volume)

            elseif ev[1] == "mouse_scroll" then
                local direction = ev[2]
                if direction == -1 and selected > 1 then
                    selected = selected - 1
                    startIdx, endIdx = drawList(selected, "Streaming: " .. songs[index].name)
                elseif direction == 1 and selected < #songs then
                    selected = selected + 1
                    startIdx, endIdx = drawList(selected, "Streaming: " .. songs[index].name)
                end

            elseif ev[1] == "mouse_drag" then
                local _, x, y = ev[2], ev[3], ev[4]
                if #songs > LIST_H and x == w and y >= LIST_TOP and y <= LIST_BOTTOM then
                    local newSelected = scrollBarIndexFromY(y)
                    if newSelected ~= selected then
                        selected = newSelected
                        startIdx, endIdx = drawList(selected, "Streaming: " .. songs[index].name)
                    end
                elseif onSlider(x, y) then
                    volume = volumeFromX(x)
                    drawHeader(statusText())
                    drawFooter()
                end

            elseif ev[1] == "mouse_click" or ev[1] == "monitor_touch" then
                local _, x, y = ev[2], ev[3], ev[4]
                if clickedButton("STOP", x, y) then
                    stopRequested = true
                elseif onSlider(x, y) then
                    volume = volumeFromX(x)
                    drawHeader(statusText())
                    drawFooter()
                elseif clickedButton("QUIT", x, y) then
                    stopRequested = true
                    jumpToIndex = "QUIT"
                elseif #songs > LIST_H and x == w and y >= LIST_TOP and y <= LIST_BOTTOM then
                    selected = scrollBarIndexFromY(y)
                    startIdx, endIdx = drawList(selected, "Streaming: " .. songs[index].name)
                elseif startIdx and y >= LIST_TOP and y <= LIST_BOTTOM then
                    local clickedIndex = startIdx + (y - LIST_TOP)
                    if clickedIndex >= startIdx and clickedIndex <= endIdx and clickedIndex ~= index then
                        stopRequested = true
                        jumpToIndex = clickedIndex
                    end
                end
            end
        end

        chunk = audioResponse.read(16 * 1024)
    end
    audioResponse.close()
    currentAudio = nil
end

-- ============ Main loop ============

-- runs playSong, and if the user clicked a different track mid-song,
-- keeps chaining into that track instead of dropping the click
local function waitBetweenSongs(nextIndex)
    selected = nextIndex
    local deadline = os.clock() + 3

    while true do
        local remaining = math.max(0, math.ceil(deadline - os.clock()))
        startIdx, endIdx = drawList(selected, "Next up: " .. songs[nextIndex].name .. " (" .. remaining .. "s)")
        if remaining <= 0 then
            return nextIndex
        end

        local timer = os.startTimer(0.25)
        local advancing = false
        while not advancing do
            local ev = { os.pullEvent() }
            if ev[1] == "timer" and ev[2] == timer then
                advancing = true

            elseif ev[1] == "mouse_drag" then
                local _, x, y = ev[2], ev[3], ev[4]
                if onSlider(x, y) then
                    volume = volumeFromX(x)
                    drawHeader(statusText())
                    drawFooter()
                end

            elseif ev[1] == "mouse_click" or ev[1] == "monitor_touch" then
                local _, x, y = ev[2], ev[3], ev[4]
                if clickedButton("STOP", x, y) then
                    return nil
                elseif clickedButton("QUIT", x, y) then
                    quitRequested = true
                    return nil
                elseif onSlider(x, y) then
                    volume = volumeFromX(x)
                    drawHeader(statusText())
                    drawFooter()
                elseif y >= LIST_TOP and y <= LIST_BOTTOM then
                    local clickedIndex = startIdx + (y - LIST_TOP)
                    if clickedIndex >= startIdx and clickedIndex <= endIdx then
                        selected = clickedIndex
                        return clickedIndex
                    end
                end
            end
        end
    end
end

local function runPlayback(index)
    while true do
        playSong(index)
        if jumpToIndex == "QUIT" then
            quitRequested = true
            return
        elseif jumpToIndex then
            index = jumpToIndex
            selected = index
        elseif stopRequested then
            return
        else
            -- song finished naturally (not stopped by the user) —
            -- wait a few seconds, then auto-advance, looping back
            -- to the first song after the last one
            local nextIndex = index + 1
            if nextIndex > #songs then nextIndex = 1 end
            local chosen = waitBetweenSongs(nextIndex)
            if quitRequested then
                return
            elseif chosen == nil then
                return
            end
            index = chosen
            selected = index
        end
    end
end

while true do
    local e = { os.pullEvent() }
    local event = e[1]

    if event == "mouse_scroll" then
        local direction = e[2]
        if direction == -1 and selected > 1 then
            selected = selected - 1
            startIdx, endIdx = drawList(selected, statusText())
        elseif direction == 1 and selected < #songs then
            selected = selected + 1
            startIdx, endIdx = drawList(selected, statusText())
        end

    elseif event == "mouse_drag" then
        local button, x, y = e[2], e[3], e[4]
        if #songs > LIST_H and x == w and y >= LIST_TOP and y <= LIST_BOTTOM then
            local newSelected = scrollBarIndexFromY(y)
            if newSelected ~= selected then
                selected = newSelected
                startIdx, endIdx = drawList(selected, statusText())
            end
        elseif onSlider(x, y) then
            volume = volumeFromX(x)
            drawHeader(statusText())
            drawFooter()
        end

    elseif event == "mouse_click" or event == "monitor_touch" then
        local button, x, y = e[2], e[3], e[4]

        if clickedButton("PLAY", x, y) then
            runPlayback(selected)
            if quitRequested then
                clearScreen(THEME_BACKGROUND)
                break
            end
            startIdx, endIdx = drawList(selected, statusText())
        elseif clickedButton("STOP", x, y) then
            stopRequested = true
        elseif onSlider(x, y) then
            volume = volumeFromX(x)
            drawHeader(statusText())
            drawFooter()
        elseif clickedButton("QUIT", x, y) then
            clearScreen(THEME_BACKGROUND)
            break
        elseif #songs > LIST_H and x == w and y >= LIST_TOP and y <= LIST_BOTTOM then
            selected = scrollBarIndexFromY(y)
            startIdx, endIdx = drawList(selected, statusText())
        elseif y >= LIST_TOP and y <= LIST_BOTTOM then
            local clickedIndex = startIdx + (y - LIST_TOP)
            if clickedIndex >= startIdx and clickedIndex <= endIdx then
                if clickedIndex == selected then
                    runPlayback(selected)
                    if quitRequested then
                        clearScreen(THEME_BACKGROUND)
                        break
                    end
                    startIdx, endIdx = drawList(selected, statusText())
                else
                    selected = clickedIndex
                    startIdx, endIdx = drawList(selected, statusText())
                end
            end
        end
    end
end
