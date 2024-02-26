extends Camera


func _ready():
	pass

#func _process(delta):
#	pass

func _input(event):
	if Input.is_key_pressed(KEY_Q):
		rotate_y(0.1)
	if Input.is_key_pressed(KEY_E):
		rotate_y(-0.1)
	
	if Input.is_key_pressed(KEY_W):
		transform.origin.z += 1
	
	if Input.is_key_pressed(KEY_S):
		transform.origin.z -= 1
		
	if Input.is_key_pressed(KEY_A):
		transform.origin.x += 1
	
	if Input.is_key_pressed(KEY_D):
		transform.origin.x -= 1
	
	if Input.is_key_pressed(KEY_SPACE):
		transform.origin.y += 1
	
	if Input.is_key_pressed(KEY_SHIFT):
		transform.origin.y -= 1
	
