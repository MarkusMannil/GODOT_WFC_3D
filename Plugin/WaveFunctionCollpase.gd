extends Node


# objects
var objects : Array

# for every object 6 rules
# y+
# y-
# x+ 
# x- 
# z+ 
# z-
var rules : Array

var neighbour_shifts : Array

var adjacency_objects : Array

export var object_path : String = "res://wfc_objects/"
# size of every object
export var object_size : Vector3

# grid start cordinate
export var start_pos : Vector3 

# pos - min bound lowest x y z cords : inclusive
export var min_bound : Vector3

# pos + max bound highest x y z cords : inclusive 
export var max_bound : Vector3

var all : int

var rnd : RandomNumberGenerator

var map : Array

var debug_string = ""

var grid_map : GridMap

var mesh_lib : MeshLibrary

func _ready():
	rnd = RandomNumberGenerator.new()
	ready_grid_map()
	_ready_objects()
	fill_base_with_obj(0)
	wave_function_collapse()
	pass
# 0 wall
# 1 sky 

func ready_grid_map():
	grid_map = $GridMap
	
	grid_map.mesh_library.clear()
	
	grid_map.cell_size = object_size
	
	

# later get all objects from somewhere
# and set the rules
func _ready_objects():
	
	# get all objects paths
	var object_paths = getFilePathsByExtension(object_path,"tscn",false)
		
	objects = []
	rules = []
	adjacency_objects = []
	var self_adj = []
	
	
	
	# get rules for each object
	for index in range(object_paths.size()):
		
		var path = object_paths[index]
		# load object
		var obj = load(path)
		# instance the object
		var instance = obj.instance()
		var rot = []
		var temp_rule = []
		
		# get object rules
		if instance.has_method("get_rule_as_int"):
			temp_rule = instance.get_rule_as_int()
			rules.append(temp_rule)
			adjacency_objects.append([0,0,0,0,0,0])
			objects.append([obj,instance.rotation_degrees])
			print(instance.rotation_degrees)
			add_mesh_to_mesh_lib(instance.get_child(0).mesh)
			self_adj.append(false)
			
		else:
			push_error("Object missing rules script")
		if instance.has_method("get_rotations"):
			rot = instance.get_rotations()
		else:
			push_error("Object missing rules script")
		
		if rot[0]:
			objects.append([obj,Vector3(0,90,0)])
			rules.append(rotate_rules_y90(temp_rule))
			adjacency_objects.append([0,0,0,0,0,0])
			add_mesh_to_mesh_lib(instance.get_child(0).mesh)
			self_adj.append(true)
		if rot[1]:
			objects.append([obj,Vector3(0,270,0)])
			rules.append(rotate_rules_y270(temp_rule))
			adjacency_objects.append([0,0,0,0,0,0])
			add_mesh_to_mesh_lib(instance.get_child(0).mesh)
			self_adj.append(true)
		if rot[2]:
			objects.append([obj,Vector3(0,180,0)])
			rules.append(rotate_rules_y180(temp_rule))
			adjacency_objects.append([0,0,0,0,0,0])
			add_mesh_to_mesh_lib(instance.get_child(0).mesh)
			self_adj.append(true)
	
	for i in range(rules.size()):
		var rule = rules[i]
		print(rule)
		get_object_adjacency_objects(rule, i, self_adj[i]) 
	
	map = []
	
	all = int(pow(2,objects.size())-1)
	
	
	
	for i in range(max_bound.x - min_bound.x):
		map.append([])
		for j in range(max_bound.y - min_bound.y):
			map[i].append([])
			for _l in range(max_bound.z - min_bound.z):
				map[i][j].append(all) 
				
	neighbour_shifts = get_neighbour_shifts()
	add_map_state_to_string()


func add_mesh_to_mesh_lib(mesh : Mesh):
	var id = grid_map.mesh_library.get_last_unused_item_id()
	
	grid_map.mesh_library.create_item(id)
	
	grid_map.mesh_library.set_item_mesh(id, mesh)
	
	
	pass

func rotate_rules_y90(rules_ : Array):
	
	return [rules_[0],rules_[1],rules_[5],rules_[4],rules_[2],rules_[3]]

func rotate_rules_y180(rules_ : Array):
	
	return [rules_[0],rules_[1],rules_[3],rules_[2],rules_[5],rules_[4]]

func rotate_rules_y270(rules_ : Array):
	
	return [rules_[0],rules_[1],rules_[4],rules_[5],rules_[3],rules_[2]]


func get_neighbour_shifts():
	# y+ y- x+ z+ x- z-
	return [Vector3(0,1,0), Vector3(0,-1,0), Vector3(1,0,0), Vector3(-1,0,0), Vector3(0,0,1), Vector3(0,0,-1)]

func write_map_to_file():
	var __my_file := File.new()
	__my_file.open("res://DEBUG.txt", __my_file.WRITE)
	assert(__my_file.is_open())
	__my_file.store_string(debug_string)
	__my_file.close()
	
	
func fill_base_with_obj(id : int):
	for i in range(map.size()):
		for j in range(map[0][0].size()):
			map[i][0][j] = 1 << id
			propegate_map(Vector3(i,0,j))
	
	
func add_map_state_to_string():
	var __my_text = " ÖÖÖ \n"
	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):
				__my_text += dec2bin(map[x][y][z]) + "-"
			__my_text += "\n" 
		__my_text += "\n" 
	__my_text += " ____ "
	
	debug_string += __my_text

func wave_function_collapse():
	
	var cur = start_pos
	
	while true:
		
		collapse_cell(cur)
		add_map_state_to_string()
		cur = get_next_cell_to_collapse()
		if cur == null:
			break
	put_objects_to_scene()
	write_map_to_file()


func get_object_adjacency_objects(obj_rules : Array, index : int , self_adj : bool = false ):
	
	var temp
	
	for i in range(rules.size()):
		# i- th object rules
		var rule = rules[i]
		
		if self_adj && i == index:
			continue
		
		if(rule[0] & obj_rules[1] != 0):
			adjacency_objects[index][1] += 1 << i
			
		if(rule[1] & obj_rules[0] != 0):
			adjacency_objects[index][0] += 1 << i
			
		if(rule[2] & obj_rules[3] != 0):
			adjacency_objects[index][3] += 1 << i
			
		if(rule[3] & obj_rules[2] != 0):
			adjacency_objects[index][2] += 1 << i
			
		if(rule[4] & obj_rules[5] != 0):
			adjacency_objects[index][5] += 1 << i
			
		if(rule[5] & obj_rules[4] != 0):
			adjacency_objects[index][4] += 1 << i	
	
	#print(adjacency_objects[index])
	for x in adjacency_objects[index]:
		print(dec2bin(x)," ",x)
	
	
	#print(adjacency_objects[index][0] & adjacency_objects[index][1] &adjacency_objects[index][2] &adjacency_objects[index][3] &adjacency_objects[index][4] &adjacency_objects[index][5])


func get_next_cell_to_collapse():
	var lowest_entropy_cells = []
	var cur_low_entropy = all
	var temp
	
	for x in range(max_bound.x - min_bound.x):
		for y in range(max_bound.y - min_bound.y):
			for z in range(max_bound.z - min_bound.z):
				# can be done with quick calculation maybe?
				if is_collapsed(map[x][y][z]):
					continue
				temp = get_entropy(map[x][y][z]) 
				if(cur_low_entropy == temp):
					lowest_entropy_cells.append(Vector3(x,y,z))
				elif(cur_low_entropy > temp):
					cur_low_entropy = temp
					lowest_entropy_cells.clear()
					lowest_entropy_cells.append(Vector3(x,y,z))
	
	
	var random = int(rand_range(0, lowest_entropy_cells.size()))
	
	if(lowest_entropy_cells.size() == 0):
		return null
	
	return lowest_entropy_cells[random]



func collapse_cell(pos : Vector3):
	
	var possible = map[pos.x][pos.y][pos.z]
	
	# get random bit and turn it into an index
	
	var obj_index = get_random_active_bit(possible)
	
	map[pos.x][pos.y][pos.z] = obj_index
	
	obj_index = bit_to_index(obj_index)
	
	debug_string += (" \n : pos : " + str(pos.x) + " " + str(pos.y) + " " + str(pos.z) +  " collapsed val : " + str(obj_index))
	
	# print(pos," --- ", obj_index)
	
	propegate_map(pos)
	
	pass

func propegate_map(pos : Vector3):
	
	var stack = []
	var current = pos
	
	for i in neighbour_shifts:
		stack.append(current + i)
	var boolean
	while stack.size() != 0:
		current = stack.pop_back()
		for i in neighbour_shifts:
			if propegate_cell(current, i):
				stack.append(current + i)

func propegate_cell(pos : Vector3, shift : Vector3):
	# cell being changed
	# cell comparing against
	
	# make pretier
	if pos.x + shift.x >= max_bound.x - min_bound.x || pos.x + shift.x < 0 || pos.x >= max_bound.x || pos.x < 0:
		return false
	if pos.y + shift.y >= max_bound.y - min_bound.y || pos.y + shift.y < 0 || pos.y >= max_bound.y || pos.y < 0:
		return false
	if pos.z + shift.z >= max_bound.z - min_bound.z || pos.z + shift.z < 0 || pos.z >= max_bound.z || pos.z < 0:
		return false
	
	
	var cur = map[pos.x][pos.y][pos.z]
	
	if(cur == 0):
		add_map_state_to_string()
		
		debug_string += " ERROR at " + str(pos)
		
		write_map_to_file()
		
		# assert(cur != 0, "WHO DIED???")
	
	if is_collapsed(cur):
		return false
	
	var check = map[pos.x + shift.x][pos.y + shift.y][pos.z+shift.z]
	
	var i = get_index_from_dir(shift)
	
	
	var mmm = get_rule_with_dir(check, i)

	map[pos.x][pos.y][pos.z] = cur & mmm
	
	# returns true if changes made
	return map[pos.x][pos.y][pos.z] != cur
	
func put_objects_to_scene():
	
	#print(grid_map.mesh_library.get_item_list())
	
	
	for x in range(max_bound.x - min_bound.x):
		for y in range(max_bound.y - min_bound.y):
			for z in range(max_bound.z - min_bound.z):
				assert(is_collapsed(map[x][y][z]), " cell not collapsed -" + str(map[x][y][z]))
				
				var obj_index = bit_to_index(map[x][y][z])
				
				if obj_index == -1: 
					print("ERROR")
					continue
				
				# print(obj_index)
				
				# print(grid_map.mesh_library.get_item_mesh(obj_index))
				
				var myQuaternion = Quat(Vector3(0, 1, 0.0), deg2rad(objects[obj_index][1].y))
				
				var cell_item_orientation = Basis(myQuaternion).get_orthogonal_index()
				
				grid_map.set_cell_item(x, y, z , obj_index, cell_item_orientation)
				
				
				
				###
				"""
				var pos = Vector3(x,y,z)
				
				var obj_index = bit_to_index(map[x][y][z])
				
				if map[x][y][z] == 0:
					break
				
				var block = objects[obj_index][0].instance()
				
				block.translate(pos * object_size + min_bound)
				
				block.get_child(0).rotate_y(deg2rad(objects[obj_index][1].y))
				
				add_child(block)
				"""
				###
				
	
	pass

func get_rule_with_dir(possible : int, i : int):
	
	var temp
	var count = int(floor(log(possible) / log(2)) + 1)
	var ret = 0
	while(count >= 0): 
		temp = possible >> count 
		if(temp & 1): 
			ret |= adjacency_objects[count][i]
		count -= 1 
	
	if(ret == 0):
		#print(dec2bin(possible), " ??? ", possible)
		pass
	
	return ret

func get_index_from_dir(dir : Vector3):
	# obj_rules = int[6] # y+ y- x+ z+ x- z-
	if dir.y == 1:
		return 1
	if dir.y == -1:
		return 0
	
	if dir.x == 1:
		return 3
	if dir.x == -1:
		return 2
		
	if dir.z == 1:
		return 5
	if dir.z == -1:
		return 4

func get_random_active_bit(mask : int):
	rnd.randomize()
	if(mask == 0):
		return -1
	var bit = 0;
	var mask_len = int(floor(log(mask) / log(2)) + 1)
	while true:
		var rndm = int(rnd.randi())
		bit = 1 << rndm % mask_len
		if bit | mask == mask :
			break
	
	#print(dec2bin(mask), " ? ", dec2bin(bit) , " - ", mask_len)
	return bit

func is_collapsed(cell : int):
	var log_2 = log(cell) / log(2)
	var ceilNum = ceil(log_2)
	var floorNum = floor(log_2)
	return ceilNum == floorNum

func get_entropy(mask:int):
	
	var count = 0
	
	var n = mask
	
	if(mask == 0):
		return 10
	
	while n > 0:
		n &= (n-1)
		count += 1
	
	return count

func bit_to_index(mask : int):
	
	var temp 
	var count = int(floor(log(all) / log(2)) + 1)
 
	while(count >= 0): 
		temp = mask >> count 
		if(temp & 1): 
			return count
		count -= 1 
	
	return -1

func dec2bin(var decimal_value): 
	var binary_string = "" 
	var temp 
	var count = 20 # Checking up to 16 bits 
 
	while(count >= 0): 
		temp = decimal_value >> count 
		if(temp & 1): 
			binary_string = binary_string + "1" 
		else: 
			binary_string = binary_string + "0" 
		count -= 1 

	return binary_string
	
# reddit user kleonc
func getFilePathsByExtension(directoryPath: String, extension: String, recursive: bool = true) -> Array:
	var dir := Directory.new()
	if dir.open(directoryPath) != OK:
		printerr("Warning: could not open directory: ", directoryPath)
		return []
	
	if dir.list_dir_begin(true, true) != OK:
		printerr("Warning: could not list contents of: ", directoryPath)
		return []

	var filePaths := []
	var fileName := dir.get_next()

	while fileName != "":
		if dir.current_is_dir():
			if recursive:
				var dirPath = dir.get_current_dir() + "/" + fileName
				filePaths += getFilePathsByExtension(dirPath, extension, recursive)
		else:
			if fileName.get_extension() == extension:
				var filePath = dir.get_current_dir() + "/" + fileName
				filePaths.append(filePath)
	
		fileName = dir.get_next()
	
	return filePaths
