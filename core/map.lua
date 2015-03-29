if not Map then
	Map = setmetatable({
		instances = {}
	}, {
		__call = function (self, id, fromPosition, toPosition)
			local object = self.instances[id]
			if not object then
				self.instances[id] = setmetatable({
					id = id,
					exist = true,
					layers = {},
					borders = {},
					delay = 100,
					status = MAP_STATUS_NONE
				}, {
					__index = Map
				})
				object = self.instances[id]
				object:setPosition(fromPosition, toPosition)
			end
			return object
		end
	})
end

function Map:getId()
	return self.exist and self.id
end

function Map:remove()
	if not self.exist then return false end
	local from = self.fromPosition
	local to = self.toPosition
	
	if from and to then
		from:iterateArea(to,
			function(position)
				local tile = Tile(position)
				if tile then
					local items = tile:getItems()
					if items then
						for index = 1, #items do
							items[index]:remove()
						end
					end
					
					local creatures = tile:getCreatures()
					if creatures then
						for index = 1, #creatures do
							local creature = creatures[index]
							if creature:isPlayer() then
								creature:teleportTo(creature:getTown():getTemplePosition())
								creature:sendTextMessage(MapGeneratorConfig.msgType, MapGeneratorConfig.prefix .. "Area closed.")
							else
								creature:remove()
							end
						end
					end
					
					local ground = tile:getGround()
					if ground then
						ground:remove()
					end
				end
			end
		)
	end
	
	self.exist = false
	Map.instances[self.id] = nil
	collectgarbage()
	collectgarbage()
end

function Map:isRemoved()
	return not self.exist
end

function Map:reset()
	self.exist = true
	self.layers = {}
	self.borders = {}
	self.delay = 100
	self.status = MAP_STATUS_NONE
	self.seed = nil
end

function Map:setPosition(fromPosition, toPosition)
	self.fromPosition = Position(fromPosition) or Position()
	self.toPosition = Position(toPosition) or Position()
end

function Map:setSeed(seed)
	if not seed then return false end

	local strseed = tostring(seed)
	local numseed = tonumber(seed)
	if numseed then
		self.seed = numseed
		return true
	elseif strseed then
		self.seed = strseed:toSeed()
		return true
	end
end

function Map:getSeed()
	return self.exist and self.seed
end

function Map:setStatus(status)
	self.status = status
end

function Map:getStatus()
	return self.exist and self.status
end

function Map:addLayer(callback, arguments)
	if not self.exist then return false end
	
	local layers = self.layers
	layers[#layers + 1] = {callback = callback, arguments = arguments}
	return true
end

function Map:removeLayer(layer_index)
	table.remove(self.layers, layer_index)
end

function Map:getLayers()
	return self.exist and self.layers
end

function Map:debugOutput(...)
	if MapGeneratorConfig.debugOutput then
		io.write(MapGeneratorConfig.prefix .. self.id .. " >> ")
		print(...)
	end
	return true
end