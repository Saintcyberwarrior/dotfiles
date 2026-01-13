--------------------------------------------------
-- Safe tiling presets (macOS-friendly)
--------------------------------------------------

hs.window.animationDuration = 0

local mash = { "alt" }

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function focused()
	return hs.window.focusedWindow()
end

local function screenFrame(win)
	return win:screen():frame()
end

--------------------------------------------------
-- Basic tiling
--------------------------------------------------

-- Left half
hs.hotkey.bind(mash, "h", function()
	local win = focused()
	if not win then
		return
	end
	local f = screenFrame(win)
	win:setFrame({ x = f.x, y = f.y, w = f.w / 2, h = f.h })
end)

-- Right half
hs.hotkey.bind(mash, "l", function()
	local win = focused()
	if not win then
		return
	end
	local f = screenFrame(win)
	win:setFrame({ x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h })
end)

-- Center (useful for terminals)
hs.hotkey.bind(mash, "c", function()
	local win = focused()
	if not win then
		return
	end
	local f = screenFrame(win)
	win:setFrame({
		x = f.x + f.w * 0.15,
		y = f.y + f.h * 0.10,
		w = f.w * 0.70,
		h = f.h * 0.80,
	})
end)

--------------------------------------------------
-- Fullscreen toggle (safe, no Spaces hacks)
--------------------------------------------------

hs.hotkey.bind(mash, "f", function()
	local win = focused()
	if win then
		win:toggleFullScreen()
	end
end)

--------------------------------------------------
-- Window cycling (like focus east/west)
--------------------------------------------------

hs.hotkey.bind(mash, "j", function()
	hs.window.focusedWindow():focusWindowBelow()
end)

hs.hotkey.bind(mash, "k", function()
	hs.window.focusedWindow():focusWindowAbove()
end)

--------------------------------------------------
-- Move window to next screen
--------------------------------------------------

hs.hotkey.bind(mash, "n", function()
	local win = focused()
	if win then
		win:moveToScreen(win:screen():next())
	end
end)

--------------------------------------------------
-- Reload config
--------------------------------------------------

hs.hotkey.bind(mash, "r", function()
	hs.reload()
	hs.alert.show("Hammerspoon reloaded")
end)
