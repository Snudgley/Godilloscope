extends Panel

onready var texture_holder = get_node('Centre/TextureHolder')
onready var texture = texture_holder.get_node('Texture')

var lines_data = []

var snapping = true
var lock_image = false
var smoothing_amount = 1
var snap_bias = 20
var line_size = 1
var selected_line = -1

var scale_factor = (rect_size.x * 0.5)


var move_image = false
const texture_scale_factor = 0.025
var texture_scale

signal line_updated(lines)
signal texture_rotation_changed(rotation)
signal texture_offset_changed(offset)
signal texture_scale_changed(scale)
signal line_created()
signal line_deselected()
signal line_destroyed()

var rotating = false

var is_mouse_over = false

var previous_mouse_pos : Vector2
# detect mouse when over rect
func _on_XY_Drawing_gui_input(event):
	if event is InputEventMouseButton: # if mouse is clicked within the drawing box
		if event.button_index == 1:
			if event.pressed:
				var pos = get_local_mouse_position() / scale_factor - Vector2.ONE 
				if selected_line == -1: # if no line is selected make a new one
					lines_data.append([pos])
					selected_line = lines_data.size() - 1
					emit_signal('line_created')
				else: # continue adding to old line
					if lines_data.size() -1 >= selected_line:
						if snapping and (pos * snap_bias).round() == (lines_data[selected_line][0] * snap_bias).round(): # if new point is close to end then snap to start and end line
							lines_data[selected_line].append(lines_data[selected_line][0])
							selected_line = -1
							emit_signal('line_deselected')
							_draw_lines()
						else:
							lines_data[selected_line].append(pos)
				emit_signal('line_updated', lines_data)
		elif event.button_index == 3:
			move_image = event.pressed
			if !event.pressed:
				if selected_line == -1:
					_clamp_texture_location()
				else:
					_clamp_drawing()
		elif event.button_index == 4:
			if selected_line == -1:
				if !lock_image:
					if texture_holder.rect_scale.x == 0:
						texture_holder.rect_scale == 0.01
					texture_holder.rect_scale *= 1 + texture_scale_factor
					_clamp_texture_location()
					emit_signal('texture_scale_changed', texture_holder.rect_scale.x)
			else:
				var new_scale = 1 + texture_scale_factor
				_scale_drawing(Vector2(new_scale,new_scale))
			
		elif event.button_index == 5:
			if selected_line == -1:
				if !lock_image:
					texture_holder.rect_scale *= 1 - texture_scale_factor
					_clamp_texture_location()
					emit_signal('texture_scale_changed', texture_holder.rect_scale.x)
			else:
				var new_scale = 1 - texture_scale_factor
				_scale_drawing(Vector2(new_scale,new_scale))
	
	elif event is InputEventMouseMotion: # update the line when mouse moves
		#
		if event.button_mask & 1:
			var pos = get_local_mouse_position() / scale_factor - Vector2.ONE 
			if selected_line == -1: # if no line is selected make a new one
				lines_data.append([pos])
				selected_line = lines_data.size() - 1
				emit_signal('line_created')
			else: # continue adding to old line
				if lines_data.size() -1 >= selected_line:
					lines_data[selected_line].append(pos)
			emit_signal('line_updated', lines_data)
		#
		if move_image:
			if selected_line == -1:
				if !lock_image:
					texture_holder.rect_position += event.relative
					emit_signal('texture_offset_changed', texture_holder.rect_position * (1 / (texture_scale * 3.0)))
			else:
				_move_drawing(event.relative)
		if rotating:
			var mouse_pos = (get_local_mouse_position() - Vector2(scale_factor, scale_factor)).normalized()
			var mouse_angle = atan2(mouse_pos.y, mouse_pos.x) - atan2(previous_mouse_pos.y, previous_mouse_pos.x)
			previous_mouse_pos = mouse_pos
			if selected_line == -1:
				if !lock_image:
					texture.rotation += mouse_angle
					emit_signal('texture_rotation_changed', texture_holder.rect_rotation)
			else:
				_rotate_drawing(mouse_angle)
		else:
			if selected_line != -1:
				_draw_lines()

var angle = 0
var rotation_speed = 0.01
var center = Vector2.ZERO
var control_pressed = false
func _unhandled_key_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == OS.find_scancode_from_string("ESCAPE"):
				if selected_line != -1:
					if lines_data[selected_line].size() < 2:
						lines_data.remove(selected_line)
						emit_signal('line_destroyed')
						selected_line = -1
					else:
						selected_line = -1
						emit_signal('line_deselected')
					_draw_lines()
			elif event.scancode == OS.find_scancode_from_string("ENTER"):
				if lines_data[selected_line].size() >= 2:
					selected_line = -1
					emit_signal('line_deselected')
					_draw_lines()
		if event.scancode == OS.find_scancode_from_string("Control"):
			control_pressed = event.pressed
		elif event.scancode == OS.find_scancode_from_string("Z"):
			if control_pressed and event.pressed:
				if selected_line != -1:
					lines_data[selected_line].remove(lines_data[selected_line].size() - 1)
					if lines_data[selected_line].size() == 0:
						lines_data.remove(selected_line)
						emit_signal('line_destroyed')
						selected_line = -1
#					else:
					emit_signal('line_updated', lines_data)
					_draw_lines()
		elif event.scancode == OS.find_scancode_from_string("R"):
			rotating = event.pressed
			previous_mouse_pos = (get_local_mouse_position() - Vector2(scale_factor, scale_factor)).normalized()
			if selected_line != -1:
				if !event.pressed:
					_clamp_drawing()
					_draw_lines()

func _clamp_texture_location():
	texture_holder.rect_position.x = clamp(
		texture_holder.rect_position.x, 
		-rect_size.x * 0.5 - (texture.get_rect().size.x * 0.5 * texture_holder.rect_scale.x),
		rect_size.x * 0.5 + (texture.get_rect().size.x * 0.5 * texture_holder.rect_scale.x)
	)
	texture_holder.rect_position.y = clamp(
		texture_holder.rect_position.y, 
		-rect_size.y * 0.5 - (texture.get_rect().size.y * 0.5 * texture_holder.rect_scale.x), 
		rect_size.y * 0.5 + (texture.get_rect().size.y * 0.5 * texture_holder.rect_scale.x)
	)

func _scale_drawing(factorvector):
	if selected_line != -1:
		if lines_data.size() - 1 >= selected_line:
			for i in lines_data[selected_line].size():
				lines_data[selected_line][i] *= factorvector
			_clamp_drawing()
			_draw_lines()
			emit_signal('line_updated', lines_data)

func _move_drawing(vect):
	if selected_line != -1:
		for i in lines_data[selected_line].size():
			lines_data[selected_line][i] += vect / scale_factor
		emit_signal('line_updated', lines_data)
		_draw_lines()

func _smooth_points():
	if selected_line != -1:
		var cur_line = lines_data[selected_line]
		var loop = false
		if cur_line[cur_line.size()-1] == cur_line[0]:
			loop = true
		for iii in range(smoothing_amount):
			var avg_point = Vector2()
			for i in cur_line.size():
				avg_point = Vector2()
				avg_point += cur_line[(i-1)%cur_line.size()]
				avg_point += cur_line[i]
				avg_point += cur_line[i]
				avg_point += cur_line[(i+1)%cur_line.size()]
				avg_point *= Vector2(.25,.25)
				cur_line[i] = avg_point
			if loop :
				avg_point = (cur_line[0] + cur_line[cur_line.size()-1])/2
				cur_line[0] = avg_point
				cur_line[cur_line.size()-1] = avg_point
		emit_signal('line_updated', lines_data)
		_draw_lines()

func _rotate_drawing(deg):
	if selected_line != -1:
		if lines_data[selected_line].size() > 1:
			for i in lines_data[selected_line].size():
				var point = lines_data[selected_line][i]
				var point_normalised = point.normalized()
				angle = deg + atan2(point_normalised.y, point_normalised.x)
				var radius = point.distance_to(center)
				var coord = (Vector2(cos(angle), sin(angle)) * radius)# + center
				lines_data[selected_line][i] = coord
				
			_draw_lines()
			emit_signal('line_updated', lines_data)

func _clamp_drawing():
	for i in lines_data[selected_line].size():
		var point = lines_data[selected_line][i]
		lines_data[selected_line][i] = Vector2(clamp(point.x, -1, 1), clamp(point.y, -1, 1))
	_draw_lines()
	emit_signal('line_updated', lines_data)

var previous_rect_size = rect_size.x
# if rect_size changes then recalculate the drawing
func _draw():
	if rect_size.x > 0:
		scale_factor = (rect_size.x * 0.5)
		texture_scale = rect_size.x / 600.0
		var pos_scale = rect_size.x / float(previous_rect_size)
		texture.scale = Vector2(texture_scale, texture_scale)
		texture_holder.rect_position *= pos_scale
		_draw_lines()
		previous_rect_size = rect_size.x

func _draw_lines():
	update()
	yield(self, 'draw')
	
	# loop through all lines
	for i in lines_data.size():
		var line = lines_data[i]
		var Line_colour = Color.white # line will be white if nothing else happens
		if line.size() >= 1: # if the line has 1 or more points. A line should only have one point if it is the selected line
			if i == selected_line: # if the current line is the selected line
				var new_point = get_local_mouse_position() / scale_factor - Vector2.ONE
				if is_mouse_over:
					line = lines_data[i].duplicate()
					line.append(new_point) 
				
				# if line end is within snap distance then make it red otherwise the selected line will be green
				if snapping and (new_point * snap_bias).round() == (lines_data[selected_line][0] * snap_bias).round():
					Line_colour = Color.red
				else:
					Line_colour = Color.green
			
			# loop through all points in a line except the last point
			for ii in line.size() - 1:
				# if distance between 2 points is not 0
				if line[ii] - line[ii + 1] != Vector2.ZERO:
					draw_line((line[ii] + Vector2.ONE) * scale_factor, (line[ii + 1] + Vector2.ONE) * scale_factor, Line_colour, line_size, false)


func _on_Line_Snapping_toggled(button_pressed):
	snapping = button_pressed

func _on_Smoothing_Amount_changed(value):
	smoothing_amount = value

func mouse_entered():
	is_mouse_over = true

func mouse_exited():
	is_mouse_over = false
	_draw_lines()


func _on_Paste_Drawing_pressed():
	pass # Replace with function body.

