require("locale.gen_combined.grilledham_map_gen.builders")
local Thread = require "locale.utils.Thread"


function run_init(params)
   global._tiles_hold = {}
   global._decoratives_hold = {}
   global._entities_hold = {}
end

function run_place_tiles(params)
	local surface = params.surface
   surface.set_tiles(global._tiles_hold)
end

function run_place_items(params)
	local surface = params.surface
   for _,deco in pairs(global._decoratives_hold) do
     surface.create_decoratives{check_collision=false, decoratives={deco}}
   end
   for _,deco in pairs(global._decoratives_hold) do
     surface.create_decoratives{check_collision=false, decoratives={deco}}
   end
   for _, entity in ipairs(global._entities_hold) do
      if surface.can_place_entity {name=entity.name, position=entity.position} then
         surface.create_entity {name=entity.name, position=entity.position}
      end
   end
end

function run_calc_items(params)
   local top_x = params.top_x
   local top_y = params.top_y

   for y = top_y, top_y + 31 do
      for x = top_x, top_x + 31 do

         -- local coords need to be 'centered' to allow for correct rotation and scaling.
         local tile, entity = MAP_GEN(x + 0.5, y + 0.5, x, y)

         if type(tile) == "boolean" and not tile then
            table.insert( global._tiles_hold, {name = "out-of-map", position = {x, y}} )
         elseif type(tile) == "string" then
            table.insert( global._tiles_hold, {name = tile, position = {x, y}} )

            if tile == "water" or tile == "deepwater" or tile == "water-green" or  tile == "deepwater-green" then
              local a = x + 1
              table.insert(global._tiles_hold, {name = tile, position = {a,y}})
              local a = y + 1
              table.insert(global._tiles_hold, {name = tile, position = {x,a}})
              local a = x - 1
              table.insert(global._tiles_hold, {name = tile, position = {a,y}})
              local a = y - 1
              table.insert(global._tiles_hold, {name = tile, position = {x,a}})
            end

            if map_gen_decoratives then
               tile_decoratives = check_decorative(tile, x, y)
               for _,tbl in ipairs(tile_decoratives) do
                  table.insert(global._decoratives_hold, tbl)
               end


               tile_entities = check_entities(tile, x, y)
               for _,entity in ipairs(tile_entities) do
                  table.insert(global._entities_hold, entity)
               end
            end
         end

         if entity then
            table.insert(global._entities_hold, entity)
         end

      end
   end
end

function run_chart_update(params)
	local x = params.area.left_top.x / 32
	local y = params.area.left_top.y / 32
	if game.forces.player.is_chunk_charted(params.surface, {x,y} ) then
		-- Don't use full area, otherwise adjacent chunks get charted
		game.forces.player.chart(params.surface, {{  params.area.left_top.x,  params.area.left_top.y}, { params.area.left_top.x+30,  params.area.left_top.y+30} } )
	end
end

function run_combined_module(event)

   if MAP_GEN == nil then
      game.print("MAP_GEN not set")
      return
   end

   local area = event.area
   local surface = event.surface
   MAP_GEN_SURFACE = surface


   local top_x = area.left_top.x
   local top_y = area.left_top.y

   if map_gen_decoratives then
      for _, e in pairs(surface.find_entities_filtered{area=area, type="decorative"}) do
   		e.destroy()
      end
      for _, e in pairs(surface.find_entities_filtered{area=area, type="tree"}) do
   		e.destroy()
      end
      for _, e in pairs(surface.find_entities_filtered{area=area, type="simple-entity"}) do
   		e.destroy()
      end
   end

   Thread.queue_action("run_init", {} )

   Thread.queue_action("run_calc_items", {surface = event.surface, top_x = top_x, top_y = top_y})

   Thread.queue_action("run_place_tiles", {surface = event.surface})
   Thread.queue_action("run_place_items", {surface = event.surface})
   Thread.queue_action("run_chart_update", {area = event.area, surface = event.surface} )

end

local decorative_options = {
   ["concrete"] = {},
   ["deepwater"] = {},
   ["deepwater-green"] = {},
   ["dirt"] = {},
   ["dirt-dark"] = {},
   ["grass"] = {
      {"green-carpet-grass", 3},
      {"green-hairy-grass", 7},
      {"green-bush-mini", 10},
      {"green-pita", 6},
      {"green-small-grass", 12},
      {"green-asterisk", 25},
      {"green-bush-mini", 7},
   },
   ["grass-medium"] = {
      {"green-carpet-grass", 12},
      {"green-hairy-grass", 28},
      {"green-bush-mini", 40},
      {"green-pita", 24},
      {"green-small-grass", 48},
      {"green-asterisk", 100},
      {"green-bush-mini", 28},
   },
   ["grass-dry"] = {
      {"green-carpet-grass", 24},
      {"green-hairy-grass", 56},
      {"green-bush-mini", 80},
      {"green-pita", 48},
      {"green-small-grass", 96},
      {"green-asterisk", 200},
      {"green-bush-mini", 56},
   },
   ["hazard-concrete-left"] = {},
   ["hazard-concrete-right"] = {},
   ["lab-dark-1"] = {},
   ["lab-dark-2"] = {},
   ["red-desert"] = {
      {"brown-carpet-grass", 35},
      {"orange-coral-mini", 45},
      {"red-asterisk", 45},
      {"red-desert-bush", 12},
      {"red-desert-rock-medium", 375},
      {"red-desert-rock-small", 200},
      {"red-desert-rock-tiny", 30},
   },
   ["red-desert-dark"] = {
      {"brown-carpet-grass", 70},
      {"orange-coral-mini", 90},
      {"red-asterisk", 90},
      {"red-desert-bush", 35},
      {"red-desert-rock-medium", 375},
      {"red-desert-rock-small", 200},
      {"red-desert-rock-tiny", 150},
   },
   ["sand-dark"] = {},
   ["stone-path"] = {},
   ["water"] = {},
   ["water-green"] = {},
   ["out-of-map"] = {},
}

function check_decorative(tile, x, y)
   local options = decorative_options[tile]
   local tile_decoratives = {}

   for _,e in ipairs(options) do
      name = e[1]
      high_roll = e[2]
      if math.random(1, high_roll) == 1 then
         table.insert(tile_decoratives, {name=name, amount=1, position={x,y}})
      end
   end

   return tile_decoratives
end

local entity_options = {
   ["concrete"] = {},
   ["deepwater"] = {},
   ["deepwater-green"] = {},
   ["dirt"] = {},
   ["dirt-dark"] = {},
   ["grass"] = {
      {"tree-04", 400},
      {"tree-06", 150},
      {"tree-07", 400},
      {"tree-09", 1000},
      {"stone-rock", 400},
      {"green-coral", 10000},
   },
   ["grass-dry"] = {},
   ["grass-medium"] = {},
   ["hazard-concrete-left"] = {},
   ["hazard-concrete-right"] = {},
   ["lab-dark-1"] = {},
   ["lab-dark-2"] = {},
   ["red-desert"] = {
      {"dry-tree", 400},
      {"dry-hairy-tree", 400},
      {"tree-06", 500},
      {"tree-06", 500},
      {"tree-01", 500},
      {"tree-02", 500},
      {"tree-03", 500},
      {"red-desert-rock-big-01", 200},
      {"red-desert-rock-huge-01", 400},
      {"red-desert-rock-huge-02", 400},
   },
   ["red-desert-dark"] = {
      {"dry-tree", 400},
      {"dry-hairy-tree", 400},
      {"tree-06", 500},
      {"tree-06", 500},
      {"tree-01", 500},
      {"tree-02", 500},
      {"tree-03", 500},
      {"red-desert-rock-big-01", 200},
      {"red-desert-rock-huge-01", 400},
      {"red-desert-rock-huge-02", 400},
   },
   ["sand"] = {},
   ["sand-dark"] = {},
   ["stone-path"] = {},
   ["water"] = {},
   ["water-green"] = {},
   ["out-of-map"] = {},
}

function check_entities(tile, x, y)
   local options = entity_options[tile]
   local tile_entity_list = {}

   for _,e in ipairs(options) do
      name = e[1]
      high_roll = e[2]
      if math.random(1, high_roll) == 1 then
         table.insert(tile_entity_list, {name=name, position={x,y}})
      end
   end

   return tile_entity_list

end
