function screen_main()
	return df.global.gview.view.child	
end

--todo: transitions are not always required

function execute_with_main_mode(mode, fn)
	local ws = screen_main()
	local q = df.global.ui.main.mode
	df.global.ui.main.mode = mode

	local ok,ret = pcall(fn, ws)

    df.global.ui.main.mode = q

	if not ok then
		error (ret)
	end
    return ret	
end

function execute_with_selected_zone(bldid, fn)
	if df.global.ui.main.mode == df.ui_sidebar_mode.Zones and
	   df.global.ui_sidebar_menus.zone.selected and df.global.ui_sidebar_menus.zone.selected.id == bldid then
		return fn(screen_main(), zone)
	end

	return execute_with_main_mode(df.ui_sidebar_mode.Zones, function(ws)
		local zone = df.building.find(bldid)

		-- we assume there will be a tile belonging to the zone on y1
		local x = zone.x1
		while x < zone.x2 do
			if zone.room.extents[x-zone.x1] > 0 then
				break
			end
			x = x + 1
		end

		df.global.cursor.x = x
	    df.global.cursor.y = zone.y1
	    df.global.cursor.z = zone.z-1
	    gui.simulateInput(ws, K'CURSOR_UP_Z')

	    return fn(ws, zone)
	end)
end

function execute_with_nobles_screen(reset, fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_NOBLES')
		local noblesws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_noblelistst

		--todo: why is this here? 
		if reset then
		    noblesws.mode = df.viewscreen_layer_noblelistst.T_mode.List
		    noblesws.layer_objects[0].active = true
		    noblesws.layer_objects[0].enabled = true
		    noblesws.layer_objects[1].active = false
		    noblesws.layer_objects[1].enabled = false
		end

		local ok,ret = pcall(fn, noblesws)

		noblesws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_military_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_MILITARY')
		local milws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_layer_militaryst

		local ok,ret = pcall(fn, milws)

		milws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_units_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_UNITLIST')
		local unitsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_unitlistst

		local ok,ret = pcall(fn, unitsws)

		unitsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_jobs_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_JOBLIST')
		local jobsws = dfhack.gui.getCurViewscreen()

		local ok,ret = pcall(fn, jobsws)

		jobsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

status_pages = {
	Overview = -1,
	Animals = 0,
	Kitchen = 1,
	Stone = 2,
	Stocks = 3,
	Health = 4,
	Prices = 5,
	Currency = 6,
	Justice = 7,
}

function execute_with_status_page(pageid, fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_STATUS')
		local statusws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_overallstatusst
		
		if pageid ~= -1 then
			statusws.visible_pages:insert(0,pageid)
		    gui.simulateInput(statusws, K'SELECT')
	    end
        
        local pagews = dfhack.gui.getCurViewscreen()
		local ok,ret = pcall(fn, pagews)
        
        pagews.breakdown_level = df.interface_breakdown_types.STOPSCREEN
        statusws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
        return ret
	end)
end

function execute_with_manager_screen(fn)
	local jobsws = df.viewscreen_joblistst:new()
	gui.simulateInput(jobsws, K'UNITJOB_MANAGER')
	jobsws:delete()

	local managerws = dfhack.gui.getCurViewscreen()

	local ok,ret = pcall(fn, managerws)

	managerws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

	if not ok then
		error (ret)
	end
	return ret
end

function execute_with_manager_orders_screen(fn)
	return execute_with_manager_screen(function(ws)
		gui.simulateInput(ws, K'MANAGER_NEW_ORDER')
		local ordersws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_createquotast

		local ok,ret = pcall(fn, ordersws)

		ordersws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_locations_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_LOCATIONS')
		local locsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_locationsst

		local ok,ret = pcall(fn, locsws)

		locsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_petitions_screen(fn)
	return execute_with_main_mode(df.ui_sidebar_mode.Default, function(ws)
		gui.simulateInput(ws, K'D_PETITIONS')
		local petitionsws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_petitionsst
		if petitionsws._type ~= df.viewscreen_petitionsst then
			error('wrong screen '..tostring(petitionsws._type))
		end

		local ok,ret = pcall(fn, petitionsws)

		petitionsws.breakdown_level = df.interface_breakdown_types.STOPSCREEN

		if not ok then
			error (ret)
		end
		return ret
	end)
end

function execute_with_locations_for_building(bldid, fn)
    local bld = (bldid and bldid ~= -1 and bldid ~= 0) and df.building.find(bldid) or df.global.world.selected_building
    if not bld then
        error('no building/zone '..tostring(bldid))
    end

    if bld._type ~= df.building_civzonest and bld._type ~= df.building_bedst and bld._type ~= df.building_tablest then
	    error('wrong building type '..tostring(bldid)..' '..tostring(bld._type))
    end

    if not bld.is_room then
        error('not a room '..tostring(bldid))
    end

    if bld._type == df.building_civzonest then
	    if not bld.zone_flags.meeting_area then
	    	error('not a meeting area '..tostring(bld.zone_flags.whole))
	    end

	    return execute_with_selected_zone(bldid, function(ws)
			gui.simulateInput(ws, K'ASSIGN_LOCATION')
			local ok,ret = pcall(fn, ws, bld)
			df.global.ui.main.mode = df.ui_sidebar_mode.Zones

			if not ok then
				error (ret)
			end
			return ret
	    end)
	end

	--todo: convert this to execute_with_selected
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        error('wrong screen '..tostring(ws._type))
    end

    if df.global.ui.main.mode ~= df.ui_sidebar_mode.QueryBuilding or df.global.world.selected_building == nil then
        error('no selected building')
    end    

	gui.simulateInput(ws, K'ASSIGN_LOCATION')    
	local ok,ret = pcall(fn, ws, bld)
	df.global.ui.main.mode = df.ui_sidebar_mode.QueryBuilding

	if not ok then
		error (ret)
	end
	return ret
end

function execute_with_job_details(bldid, idx, fn)
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type ~= df.viewscreen_dwarfmodest then
        return
    end

    if df.global.ui.main.mode ~= 17 or df.global.world.selected_building == nil then
        return
    end

    local bld = df.global.world.selected_building
    --todo: check bld.id == bldid

    if idx < 0 or idx > #bld.jobs then
    	error('invalid job idx '..tostring(idx))
    end

    df.global.ui_workshop_job_cursor = idx

    gui.simulateInput(ws, K'BUILDJOB_DETAILS')
    --todo: check that df.global.ui_sidebar_menus.job_details.job ~= nil
	local ok,ret = pcall(fn, ws) 
	df.global.ui_sidebar_menus.job_details.job = nil

	if not ok then
		error (ret)
	end
	return ret
end
