extends Spatial

export(Array, int) var up  = Array()

export(Array, int) var down = Array()

export(Array, int) var forward = Array()

export(Array, int) var backward = Array()

export(Array, int) var right = Array()

export(Array, int) var left = Array()


export(bool) var allow_add_90_y =false
export(bool) var allow_sub_90_y =false
export(bool) var allow_add_180_y =false 

func get_rotations():
	return [allow_add_90_y,allow_sub_90_y,allow_add_180_y]

func get_rule_as_int():
	
	var rule = [0,0,0,0,0,0]
	
	
	for i in range(up.size()):
		rule[0] += 1 << up[i]
	
	
	for i in range(down.size()):
		rule[1] += 1 << down[i]
		
		
	for i in range(forward.size()):
		rule[2] += 1 << forward[i]
		
		
	for i in range(backward.size()):
		
		rule[3] += 1 << backward[i]
		
		
	for i in range(right.size()):
		rule[4] += 1 << right[i]
		

	for i in range(left.size()):
		rule[5] += 1 << left[i]
		
		
	return rule
