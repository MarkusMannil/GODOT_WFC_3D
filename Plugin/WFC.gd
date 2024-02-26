extends Node

# objects
var objects : Array

# for every object 6 rules
# y+
# y-
# x+ 
# z+ 
# x- 
# z-
var rules : Array

var adjacency_objects : Array

# size of every object
export var object_size : Vector3

# grid start cordinate
export var start_pos : Vector3 

# pos - min bound lowest x y z cords : inclusive
export var min_bound : Vector3

# pos + max bound highest x y z cords : inclusive 
export var max_bound : Vector3

var rnd : RandomNumberGenerator

var map : Array

var map_copy_zeroes: Array

var col_map : Array

var collapsed_cells :int

var collapse_max :int

func _ready():
	rnd = RandomNumberGenerator.new()
	
	_ready_objects()
	wave_function_collapse()
	pass
# 0 wall
# 1 sky 
# later get all objects from somewhere
# and set the rules
func _ready_objects():
	
	# get all objects
	var object_paths = getFilePathsByExtension("res://wfc_objects/","tscn",false)
	
	#print(object_paths)
	#print(object_paths[0])
	
	objects = Array()
	rules = Array()
	adjacency_objects = Array()
	
	# get rules for each object
	for index in range(object_paths.size()):
		var path = object_paths[index]
		
		var obj = load(path)
		
		var instance = obj.instance()
		
		rules.append([0,0,0,0,0,0])
		
		adjacency_objects.append([0,0,0,0,0,0])
		
		if instance.get_child(0).has_method("get_rule_as_int"):
			rules[index] = instance.get_child(0).get_rule_as_int()
		add_child(instance)
		
		objects.append(obj)
	
	# DEBUG
	
	for i in range(rules.size()):
		var rule = rules[i]
		get_object_adjacency_objects(rule, i) 
	
	map = []
	col_map = []
	
	var all = int(pow(2,objects.size())-1)
	
	#print(all, " ALL")
	
	collapsed_cells = 0
	collapse_max = 0
	
	for i in range(max_bound.x - min_bound.x):
		map.append([])
		col_map.append([])
		for j in range(max_bound.y - min_bound.y):
			map[i].append([])
			col_map[i].append([])
			for l in range(max_bound.z - min_bound.z):
				map[i][j].append(all) 
				col_map[i][j].append(0)
				collapse_max += 1
	pass
	
	map_copy_zeroes = col_map.duplicate(true)
	print(rules)
	print(adjacency_objects, " adjs objs")

func wave_function_collapse():
	
	var cur
	while (collapsed_cells < collapse_max):
		
		cur = get_lowest_entropy()
		collapse_cell(cur)
		write_map_to_file()
		
		
	
	

	

func get_object_adjacency_objects(obj_rules : Array, obj_id : int):
	
	var tmp_rul
	# iga objekti sobituvus reeglid
	for i in range(rules.size()):
		tmp_rul = rules[i]
		# iga reegel i-ndas objectis
		for j in range(tmp_rul.size()):
			var tmp = tmp_rul[j]
			if tmp & obj_rules[j] != 0:
				adjacency_objects[obj_id][j] += 1 << (i)
	
	pass


# DEBUG
func dec2bin(var decimal_value): 
	var binary_string = "" 
	var temp 
	var count = 7 # Checking up to 16 bits 
 
	while(count >= 0): 
		temp = decimal_value >> count 
		if(temp & 1): 
			binary_string = binary_string + "1" 
		else: 
			binary_string = binary_string + "0" 
		count -= 1 

	return binary_string





func write_map_to_file():
	var __my_text = ""
	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):
				__my_text += str(map[x][y][z]) + " "
			__my_text += "\n" 
		__my_text += "\n" 
		
	__my_text += " ____ "
	var __my_file := File.new()
	__my_file.open("res://DEBUG.txt", __my_file.WRITE)
	assert(__my_file.is_open())
	__my_file.store_string(__my_text)
	__my_file.close()


func arr_to_string(arr : Array):
	var txt = ""
	for i in arr:
		txt += str(i) + " "
	return txt	
	
# get next cell to collapse
func get_lowest_entropy():
	var low = 32
	var arr = Array()
	var temp = 1000
	
	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):
				# if cell collapsed
				if col_map[x][y][z] == 1:
					continue
				temp = get_all_active_bit_index(map[x][y][z]).size() 
				if(temp == low):
					arr.append(Vector3(x,y,z))
				elif(temp < low):
					arr.clear()	
					low = temp
					arr.append(Vector3(x,y,z))
	
	rnd.randomize()
	var rnd_nbr = rnd.randi_range(0,arr.size()-1)
	#print(rnd_nbr," ", arr.size())
	
	if(rnd_nbr == -1):
		 return 1000
	
	
	
	return arr[rnd_nbr]
	
	
	pass

# get entropy of a cell
func get_entropy(val : int):
	
	var temp 
	var count = 7 
	var lit_count = 0
	
	while(count >= 0): 
		temp = val >> count 
		if(temp & 1): 
			lit_count += 1
		count -= 1 
		
	return lit_count

func propagate_map(pos : Vector3):
	
	
	var cur
	
	var queue = [pos]
	
	var done = map_copy_zeroes.duplicate(true)
	
	
	
	while(queue.size() != 0):
		
		cur = queue.pop_front()
		done[cur.x][cur.y][cur.z] = -1
		
		for dir in get_pos_around(cur):
			if(dir.x != -1 && done[dir.x][dir.y][dir.z] == 0):
				queue.append(dir)
		get_cell_possible_states(cur)
		
	pass


func get_pos_around(pos : Vector3):
	var ret = [0,0,0,0,0,0]
	var up = pos + Vector3(0,1,0)
	var down = pos + Vector3(0,-1,0)
	var forward = pos + Vector3(1,0,0)
	var right = pos + Vector3(0,0,1)
	var backward = pos + Vector3(-1,0,0)
	var left = pos + Vector3(0,0,-1)
	
	var oob = Vector3(-1,-1,-1)
	
	if(up.y >= map.size()):
		ret[0] = oob
	else:
		ret[0] = up
	
	if(down.y < 0):
		ret[1] = oob
	else:
		ret[1] = down
	
	if(forward.x >= map.size()):
		ret[2] = oob
	else:
		ret[2] = forward
	
	if(backward.z < 0):
		ret[3] = oob
	else:
		ret[3] = backward
	
	if(right.z >= map.size()):
		ret[4] = oob
	else:
		ret[4] = right
	
	if(left.z < 0):
		ret[5] = oob
	else:
		ret[5] = left
	
	return ret		


func get_cell_possible_states(pos : Vector3):
	
	var pos_around = get_pos_around(pos)
	
	var temp_rules = map[pos.x][pos.y][pos.z]
	
	if(pos_around[0].x != -1):
		temp_rules = temp_rules & find_common_rules(pos , pos_around[0] , 1 )
	if(pos_around[1].x != -1):
		temp_rules = temp_rules & find_common_rules(pos , pos_around[1] , 0 )
	if(pos_around[2].x != -1):
		temp_rules = temp_rules & find_common_rules(pos , pos_around[2] , 4 )
	if(pos_around[3].x != -1):
		temp_rules = temp_rules & find_common_rules(pos , pos_around[3] , 2 )
	if(pos_around[4].x != -1):	
		temp_rules = temp_rules & find_common_rules(pos , pos_around[4] , 5 )
	if(pos_around[5].x != -1):	
		temp_rules = temp_rules & find_common_rules(pos , pos_around[5] , 3 )
	
	map[pos.x][pos.y][pos.z] = temp_rules
	pass

func find_common_rules(cur_pos : Vector3 , other_pos : Vector3 , rule_index : int):
	
	var cur = map[cur_pos.x][cur_pos.y][cur_pos.z]
	
	var other = map[other_pos.x][other_pos.x][other_pos.x]
	
	#print(cur ," ", dec2bin(cur) ,  " current cell obj")
	#print(other," ", dec2bin(other) , " other cell obj")
	
	var other_possible = get_all_active_bit_index(other) # -> võimalikud kõrval oleva celli tükid
	
	var temp  = int(floor(log(cur) / log(2))+ 1)
	temp = int(pow(2,temp)) - 1
	
	
	#print(temp, " ", dec2bin(temp) , " temp -0")
	#print(rule_index , " rul")
	for index in other_possible:
		#print(dec2bin(adjacency_objects[index][rule_index]), " & ", dec2bin(temp) , " temp ", index)
		# print(adjacency_objects[index] , " ", rule_index ," ",adjacency_objects[index][rule_index] )
		#print(dec2bin(adjacency_objects[index][rule_index]))
		
		temp = temp & adjacency_objects[index][rule_index]
		
		
	#print(temp, " ", dec2bin(temp) , " temp \n")
	
	if(temp == 0):
		return cur
	
	return cur & temp



func collapse_cell(pos : Vector3):
	
	var cell = map[pos.x][pos.y][pos.z]
	
	var selected_obj = get_random_active(cell)
	
	#print(selected_obj , " S RULE")
	
	map[pos.x][pos.y][pos.z] = selected_obj
	col_map[pos.x][pos.y][pos.z] = 1
	
	var collapsed_cell_obj_index = one_bit_to_index(selected_obj)
	
	#TODO -> instaciate object
	var block = objects[collapsed_cell_obj_index].instance()
	
	#print(block)
	
	block.translate(pos + min_bound)
	add_child(block)
	collapsed_cells += 1
	
	propagate_map(pos)
	
	
	pass

# get a random active bit 
func get_random_active(mask : int):
	rnd.randomize()
	#print(dec2bin(mask))
	if(mask == 0):
		return -1
	var bit = 0;
	var mask_len = int(floor(log(mask) / log(2)) + 1)
	while not (bit and mask):
		var rndm = int(rnd.randi())
		bit = 1 << rndm % mask_len
	#print(dec2bin(bit) , " before index ", bit)
	
	return bit

# get all bit indexes
func get_all_active_bit_index(mask : int):
	var count = int(floor(log(mask) / log(2)) + 1)
	var temp
	var index = Array()
	
	while(count >= 0): 
		temp = mask >> count 
		if(temp & 1): 
			index.append(count)
		count -= 1 
	
	#print(index, " ", dec2bin(mask))
	return index

# get index from bit
func one_bit_to_index(mask : int):
	var count = int(floor(log(mask) / log(2)) + 1)
	var temp
	while(count >= 0): 
		temp = mask >> count 
		if(temp & 1): 
			return  count
		count -= 1 
	return -1

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
