

local timers = {}
local timerintervals = {}
local timerfuncs = {}

winter.register_timer = function(name, interval, func)
	timers[name] = 0
	timerintervals[name] = interval
	timerfuncs[name] = func
end


core.register_globalstep(function(dtime)
	for name, timer in pairs(timers) do
		timers[name] = timer + dtime
		if timers[name] > timerintervals[name] then
			timerfuncs[name](timers[name])
			timers[name] = 0
		end
	end
end)
