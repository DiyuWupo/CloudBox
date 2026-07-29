-- ====================================================
--                 DIYU'S CLOUDBOX (UI Edition)
-- ====================================================
-- Requires an ADVANCED computer/pocket computer for color.
-- Mouse click support included.
-- ====================================================
--
-- >>>>>>>>>>>>>>>>>> SETUP - READ ME <<<<<<<<<<<<<<<<<<
-- >>>  Change the 3 lines below to point at YOUR    <<<
-- >>>  own GitHub repo, then you're good to go!      <<<
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

local GITHUB_USERNAME = "DiyuWupo"   -- <-- CHANGE THIS
local GITHUB_REPO     = "ES"         -- <-- CHANGE THIS
local GITHUB_BRANCH   = "main"                 -- <-- usually "main" or "master"

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Your repo also needs a file called index.txt in its
-- root folder, listing one .dfpwm filename per line.
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ====================================================
-- AUTO-UPDATE
-- Checks this Pastebin paste every launch. If you've
-- edited/republished the paste, this file rewrites
-- itself and restarts automatically.
-- ====================================================
local PASTEBIN_ID = "7rvEUn3B"   -- <-- change if you make a new paste

local function selfUpdate()
    local pasteResponse = http.get("https://pastebin.com/raw/" .. PASTEBIN_ID)
    if not pasteResponse then
        return false, "no connection"
    end
    local newCode = pasteResponse.readAll()
    pasteResponse.close()

    if not newCode or #newCode == 0 then
        return false, "empty paste"
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

term.clear()
term.setCursorPos(1,1)
print("Checking for updates...")
local updated, updateErr = selfUpdate()
if updated then
    print("Update found! Restarting with new version...")
    sleep(1)
    shell.run(shell.getRunningProgram())
    return
end

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

if not speaker then
    error("No speaker attached! Place a speaker block next to the computer.")
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
    setColors(bg or colors.black, colors.white)
    term.clear()
end

local function centerText(y, text, bg, fg)
    setColors(bg or colors.black, fg or colors.white)
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    term.setCursorPos(x, y)
    term.write(text)
end

-- ============ Setup check ============
if GITHUB_USERNAME == "YOUR_USERNAME_HERE" or GITHUB_REPO == "YOUR_REPO_HERE" then
    clearScreen(colors.black)
    centerText(math.floor(h/2) - 2, "SETUP NEEDED", colors.black, colors.yellow)
    centerText(math.floor(h/2), "Open this file and edit the 3 lines", colors.black, colors.white)
    centerText(math.floor(h/2) + 1, "under 'SETUP - READ ME' near the top.", colors.black, colors.white)
    centerText(math.floor(h/2) + 3, "Put in your own GitHub username + repo.", colors.black, colors.lightGray)
    error("Edit GITHUB_USERNAME / GITHUB_REPO near the top of this file.")
end

-- ============ Loading screen ============
clearScreen(colors.black)
centerText(math.floor(h/2), "Connecting to Diyu's CloudBox...", colors.black, colors.magenta)

local base_url = "https://raw.githubusercontent.com/" .. GITHUB_USERNAME .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/"
local response = http.get(base_url .. "index.txt")

if not response then
    clearScreen(colors.black)
    centerText(math.floor(h/2) - 1, "CONNECTION ERROR", colors.black, colors.red)
    centerText(math.floor(h/2), "Cannot reach index.txt", colors.black, colors.white)
    centerText(math.floor(h/2) + 1, "Verify repository is PUBLIC", colors.black, colors.white)
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
    clearScreen(colors.black)
    centerText(math.floor(h/2), "index.txt is empty or malformed", colors.black, colors.red)
    error()
end

-- ============ UI drawing ============
local HEADER_H = 3
local FOOTER_H = 2
local LIST_TOP = HEADER_H + 1
local LIST_BOTTOM = h - FOOTER_H
local LIST_H = LIST_BOTTOM - LIST_TOP + 1

-- button hitboxes get filled in by drawFooter each time it draws
local buttons = {}

local function drawHeader(status)
    setColors(colors.purple, colors.white)
    for y = 1, HEADER_H - 1 do
        term.setCursorPos(1, y)
        term.write(string.rep(" ", w))
    end
    centerText(1, "== DIYU'S CLOUDBOX ==", colors.purple, colors.white)
    centerText(2, status or "", colors.purple, colors.magenta)

    setColors(colors.gray, colors.white)
    term.setCursorPos(1, HEADER_H)
    term.write(string.rep("-", w))
end

local function drawButton(label, x, y)
    local text = "[ " .. label .. " ]"
    setColors(colors.lightGray, colors.black)
    term.setCursorPos(x, y)
    term.write(text)
    buttons[label] = { x1 = x, x2 = x + #text - 1, y = y }
end

local function drawFooter()
    buttons = {}
    setColors(colors.gray, colors.white)
    term.setCursorPos(1, h - FOOTER_H + 1)
    term.write(string.rep("-", w))

    setColors(colors.black, colors.lightGray)
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
    clearScreen(colors.black)
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
            setColors(colors.magenta, colors.black)
        else
            setColors(colors.black, colors.white)
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
                setColors(colors.white, colors.white)
            else
                setColors(colors.gray, colors.gray)
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

-- ============ Playback ============
local currentAudio = nil
local stopRequested = false
local jumpToIndex = nil   -- set if the user clicks a different song mid-playback

local function playSong(index, selected, startIdx, endIdx)
    stopRequested = false
    jumpToIndex = nil
    drawList(selected, "Streaming: " .. songs[index].name)

    local audioResponse = http.get(songs[index].url, nil, true)
    if not audioResponse then
        drawList(selected, "Error downloading song file.")
        sleep(2)
        return
    end

    currentAudio = audioResponse
    local decoder = dfpwm.make_decoder()

    while not stopRequested do
        local chunk = audioResponse.read(16 * 1024)
        if not chunk then break end

        local decoded = decoder(chunk)
        local sent = speaker.playAudio(decoded)
        while not sent and not stopRequested do
            os.startTimer(0.05)
            local ev = { os.pullEvent() }

            if ev[1] == "speaker_audio_empty" then
                sent = speaker.playAudio(decoded)

            elseif ev[1] == "mouse_click" then
                local _, x, y = ev[2], ev[3], ev[4]
                if clickedButton("STOP", x, y) then
                    stopRequested = true
                elseif clickedButton("QUIT", x, y) then
                    stopRequested = true
                    jumpToIndex = "QUIT"
                elseif startIdx and y >= LIST_TOP and y <= LIST_BOTTOM then
                    local clickedIndex = startIdx + (y - LIST_TOP)
                    if clickedIndex >= startIdx and clickedIndex <= endIdx and clickedIndex ~= index then
                        stopRequested = true
                        jumpToIndex = clickedIndex
                    end
                end
            end
        end
    end
    audioResponse.close()
    currentAudio = nil
end

-- ============ Main loop ============
local selected = 1
local startIdx, endIdx = drawList(selected, #songs .. " tracks loaded")
local quitRequested = false

-- runs playSong, and if the user clicked a different track mid-song,
-- keeps chaining into that track instead of dropping the click
local function runPlayback(index)
    while true do
        playSong(index, index, startIdx, endIdx)
        if jumpToIndex == "QUIT" then
            quitRequested = true
            return
        elseif jumpToIndex then
            index = jumpToIndex
            selected = index
        else
            return
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
            startIdx, endIdx = drawList(selected, #songs .. " tracks loaded")
        elseif direction == 1 and selected < #songs then
            selected = selected + 1
            startIdx, endIdx = drawList(selected, #songs .. " tracks loaded")
        end

    elseif event == "mouse_click" then
        local button, x, y = e[2], e[3], e[4]

        if clickedButton("PLAY", x, y) then
            runPlayback(selected)
            if quitRequested then
                clearScreen(colors.black)
                break
            end
            startIdx, endIdx = drawList(selected, #songs .. " tracks loaded")
        elseif clickedButton("STOP", x, y) then
            stopRequested = true
        elseif clickedButton("QUIT", x, y) then
            clearScreen(colors.black)
            break
        elseif y >= LIST_TOP and y <= LIST_BOTTOM then
            local clickedIndex = startIdx + (y - LIST_TOP)
            if clickedIndex >= startIdx and clickedIndex <= endIdx then
                if clickedIndex == selected then
                    runPlayback(selected)
                    if quitRequested then
                        clearScreen(colors.black)
                        break
                    end
                    startIdx, endIdx = drawList(selected, #songs .. " tracks loaded")
                else
                    selected = clickedIndex
                    startIdx, endIdx = drawList(selected, #songs .. " tracks loaded")
                end
            end
        end
    end
end
