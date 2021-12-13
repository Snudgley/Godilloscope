extends Control

var click_protect
var File_Dialog

onready var XY_Viewport = get_node("VBoxContainer/Top Half/AspectRatioContainer/XY Drawing")
onready var texture_holder = XY_Viewport.texture_holder
onready var texture = XY_Viewport.texture


var SaveSample : Control
var PlaySample : Control

var EditorVolume : Control

var FrequencyApproximate : Control
var FrequencyExact : Control
var FrequencyNote : Control
var FrequencyNotes = []
var FrequencyOctave : Control
var SampleCountNode : Control

var OpenImage : Control

var ImageLock : Control
var ImageControls : Control

var ImageOpacity : Control

var ImageScaleXY : Control
var ImageScaleX : Control
var ImageScaleY : Control

var ImageOffsetX : Control
var ImageOffsetY : Control

var ImageRotationApproximate : Control
var ImageRotationExact : Control

var ImageClickProtect : Control

var OpenDrawing : Control
var SaveDrawing : Control
var CopyDrawing : Control
var PasteDrawing : Control

var LineControls : Control

var LineScaleXY : Control
var LineScaleX : Control
var LineScaleY : Control

var LineOffsetX : Control
var LineOffsetY : Control

var LineRotationApproximate : Control
var LineRotationExact : Control

var LineControlsClickProtect : Control

var LineItemContainer : Control
var LineSnapping : Control

onready var x_channel = get_node("VBoxContainer/Bottom Half/X Axis/X Axis/X Drawing")
onready var y_channel = get_node("VBoxContainer/Bottom Half/Y Axis/Y Axis/Y Drawing")

onready var Audio = $AudioStreamPlayer

var lines_array = []
var Audio_playing = true
var lock_image = false

enum File_Dialog_Modes{Open_Project, Open_Drawing, Open_Image, Save_Project, Save_Drawing, Save_Sample}
var file_dialog_mode : int = File_Dialog_Modes.Open_Project

var sample_count = 100

func _ready():
	SaveSample = find_node("Save Sample", true, false)
	PlaySample = find_node("Play Sample", true, false)
	
	EditorVolume = find_node("Volume", true, false)
	EditorVolume.value = .2
	FrequencyApproximate = find_node("FrequencyApprox", true, false)
	FrequencyExact = find_node("FrequencyExact", true, false)
	FrequencyNote = find_node("Note", true, false)
	for i in FrequencyNote.get_item_count():
		FrequencyNotes.append(FrequencyNote.get_item_text(i))
	FrequencyOctave = find_node("Octave", true, false)
	SampleCountNode = find_node("SampleCount", true, false)
	
	ImageControls = find_node("Image Controls", true, false)
	
	ImageOpacity = find_node("ImageOpacity", true, false)
	
	ImageScaleXY = find_node("ImageScaleXY", true, false)
	ImageScaleX = find_node("ImageScaleX", true, false)
	ImageScaleY = find_node("ImageScaleY", true, false)
	
	ImageOffsetX = find_node("ImageOffsetX", true, false)
	ImageOffsetY = find_node("ImageOffsetY", true, false)
	
	ImageRotationApproximate = find_node("ImageRotationApproximate", true, false)
	ImageRotationExact = find_node("ImageRotationExact", true, false)
	
	ImageClickProtect = find_node("ImageClickProtect", true, false)
	
	OpenDrawing = find_node("Open Drawing", true, false)
	SaveDrawing = find_node("Save Drawing", true, false)
	CopyDrawing = find_node("Copy Drawing", true, false)
	PasteDrawing = find_node("Paste Drawing", true, false)
	
	LineControls = find_node("LineControls", true, false)
	
	LineScaleXY = find_node("LineScaleXY", true, false)
	LineScaleX = find_node("LineScaleX", true, false)
	LineScaleY = find_node("LineScaleY", true, false)
	
	LineOffsetX = find_node("LineOffsetX", true, false)
	LineOffsetY = find_node("LineOffsetY", true, false)
	
	LineRotationApproximate = find_node("LineRotationApproximate", true, false)
	LineRotationExact = find_node("LineRotationExact", true, false)
	
	LineControlsClickProtect = find_node("LineControlsClickProtect", true, false)
	
	LineItemContainer = find_node("LineItemContainer", true, false)

func _open_file_dialog(Title : String, Filters : PoolStringArray, Mode : int):
	File_Dialog.set_current_file("")
	File_Dialog.window_title = Title
	File_Dialog.filters = Filters
	File_Dialog.mode = 0 if Mode < 3 else 4
	file_dialog_mode = Mode
	click_protect.show()
	File_Dialog.popup()

func _on_Open_Image_pressed():
	_open_file_dialog("Open an Image", ["*.png", "*.jpg"], File_Dialog_Modes.Open_Image)

func _on_Open_Drawing_pressed():
	_open_file_dialog("Open a Drawing", ["*.dat", "*.json"], File_Dialog_Modes.Open_Drawing)

func _on_Copy_Drawing_pressed():
	OS.set_clipboard(String(lines_array))

func _on_Paste_Drawing_pressed():
	var clipboard = OS.get_clipboard()
	if clipboard.find("[[(") != -1:
		lines_array = []
		for i in LineItemContainer.get_children():
			i.queue_free()
	#	print(String(OS.get_clipboard()).trim_prefix("[").trim_suffix("]"))
	#	return
		_open_normal_drawing(clipboard.trim_prefix("[").trim_suffix("]"))
		XY_Viewport.lines_data = lines_array
		XY_Viewport.selected_line = -1
		XY_Viewport.emit_signal('line_updated', lines_array)
		_on_XY_Drawing_line_deselected()


		
func _on_Save_Drawing_pressed():
	_open_file_dialog("Save Drawing", ["*.dat"], File_Dialog_Modes.Save_Drawing)

func _on_Save_Sample_pressed():
	_open_file_dialog("Export Single Audio Loop", ["*.wav"], File_Dialog_Modes.Save_Sample)

func _on_FileDialog_popup_hide():
	click_protect.hide()
	File_Dialog.hide()



func _on_FileDialog_file_selected(file_select_path):
	if file_dialog_mode == File_Dialog_Modes.Open_Project:
		pass
	elif file_dialog_mode == File_Dialog_Modes.Open_Drawing:
		lines_array = []
		for i in LineItemContainer.get_children():
			i.queue_free()
		XY_Viewport.selected_line = -1
		
		var file = File.new()
		file.open(file_select_path, File.READ)
		var content = file.get_as_text()
		file.close()
		
		if content.find('"objects"') != -1:
			_open_bummsn_drawing(content.trim_prefix('{"objects":[').split(']],"switchChannels":')[0])
		elif content.find("[[(") != -1:
			_open_normal_drawing(content.trim_prefix("[").trim_suffix("]"))
		XY_Viewport.lines_data = lines_array
#		XY_Viewport._draw()
		XY_Viewport.emit_signal('line_updated', lines_array)
		_on_XY_Drawing_line_deselected()
	elif file_dialog_mode == File_Dialog_Modes.Open_Image:
		var image = Image.new()
		var err = image.load(file_select_path)
		if err != OK:
			print("error opening image")
			return
		var new_texture = ImageTexture.new()
		new_texture.create_from_image(image, 0)
		texture.texture = new_texture
	elif file_dialog_mode == File_Dialog_Modes.Save_Project:
		pass
	elif file_dialog_mode == File_Dialog_Modes.Save_Drawing:
		var file = File.new()
		file.open(file_select_path, File.WRITE)
		file.store_string(String(lines_array))
		file.close()
		
	elif file_dialog_mode == File_Dialog_Modes.Save_Sample:
		_generate_new_audio()
		new_stream_sample.save_to_wav(file_select_path)


func _FrequencyApprox_changed(value):
	FrequencyExact.value = value
	_calculate_note_and_octave(value)
	calculate_sample_rate(value)

func _FrequencyExact_changed(value):
	FrequencyApproximate.value = value
	_calculate_note_and_octave(value)
	calculate_sample_rate(value)

var a4 = 440
var c0 = a4*pow(2, -4.75)
var name_ = ["c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"]
func _calculate_note_and_octave(frequency):
	if frequency < 27.5 or frequency > 7902.132:
		return
	var h = round(
		12 *
		(log(frequency/c0) / log(2)))
	octave = round(h / 12 - 0.5)
	var n = int(h) % 12
	FrequencyNote.selected = n
	FrequencyOctave.text = String(octave)


const C1 = 16.351597831287414
const di = 0.0833333333333333
var Frequency = 27.5
var octave = 4
func _Note_selected(index):
	var SemitonesUpFromA = index + 3
	Frequency = ((pow(pow(2, di), SemitonesUpFromA)) * 13.75)
	var FrequencyPlusOctave = Frequency * pow(2, octave)
	FrequencyApproximate.value = FrequencyPlusOctave
	FrequencyExact.value = FrequencyPlusOctave
	calculate_sample_rate(FrequencyPlusOctave)

func _on_Octave_number_entered(number):
	octave = number
	var FrequencyPlusOctave = Frequency * pow(2, octave)
	FrequencyApproximate.value = FrequencyPlusOctave
	FrequencyExact.value = FrequencyPlusOctave
	calculate_sample_rate(FrequencyPlusOctave)

func calculate_sample_rate(Frequency):
	sample_count = 44100 / (Frequency)
	SampleCountNode.value = round(sample_count)
	if Audio_playing:
		_generate_new_audio()

func _SampleCount_changed(value):
	sample_count = value
	var frequency = 44100 / value
	FrequencyExact.value = frequency
	FrequencyApproximate.value = frequency
	_calculate_note_and_octave(frequency)
	if Audio_playing:
		_generate_new_audio()

func _LockImage_toggled(pressed):
	lock_image = pressed
	XY_Viewport.lock_image = pressed
	ImageClickProtect.visible = pressed
	ImageControls.modulate.a = 0.5 if pressed else 1

func _on_Opacity_value_changed(value):
	if !lock_image:
		texture_holder.modulate.a = value

func _on_XY_Drawing_texture_scale_changed(scale):
	if !lock_image:
		ImageScaleXY.value = scale

func _on_ImageScaleXY_value_changed(value):
	if !lock_image:
		texture_holder.rect_scale = Vector2(value, value)
		ImageScaleX.value = value
		ImageScaleY.value = value

func _on_ImageScaleX_value_changed(value):
	if !lock_image:
		texture_holder.rect_scale.x = value
		if ImageScaleY.value == value:
			ImageScaleXY.value = value

func _on_ImageScaleY_value_changed(value):
	if !lock_image:
		texture_holder.rect_scale.y = value
		if ImageScaleX.value == value:
			ImageScaleXY.value = value

func _on_XY_Drawing_texture_offset_changed(offset):
	if !lock_image:
		ImageOffsetX.value = offset.x
		ImageOffsetY.value = offset.y

func _on_X_Offset_value_changed(value):
	if !lock_image:
		texture_holder.rect_position.x = value * XY_Viewport.texture_scale * 3

func _on_Y_Offset_value_changed(value):
	if !lock_image:
		texture_holder.rect_position.y = value * XY_Viewport.texture_scale * 3


func _on_XY_Drawing_texture_rotation_changed(rotation):
	if !lock_image:
		ImageRotationApproximate.value = rotation
		ImageRotationExact.value = rotation


func _ImageRotationApproximate_changed(value):
	if !lock_image:
		ImageRotationExact.value = value
		texture_holder.rect_rotation = value

func _ImageRotationExact_changed(value):
	if !lock_image:
		ImageRotationApproximate.value = value
		texture_holder.rect_rotation = value


var new_stream_sample : AudioStreamSample
const channel_count = 2
func _on_XY_Drawing_line_updated(lines):
	lines_array = lines
	yield(get_tree().create_timer(0.01), 'timeout')
	_generate_new_audio()

func _generate_new_audio():
	var x_curve = Curve.new()
	var y_curve = Curve.new()
	x_curve.min_value = -1
	y_curve.min_value = -1
	if lines_array.size() > 0:
		for i in x_channel.channel_x:
			x_curve.add_point(i, 0,0,1,1)
		
		for i in y_channel.channel_y:
			y_curve.add_point(i, 0,0,1,1)
	
	var distance_between_sample = 1.0 / sample_count
	new_stream_sample = AudioStreamSample.new()
	new_stream_sample.stereo = true if channel_count == 2 else false
	new_stream_sample.set_format(new_stream_sample.FORMAT_16_BITS)
	var new_data : PoolByteArray
	
	for sample in sample_count:
		var curve_offset = distance_between_sample * sample
		for channel in channel_count:
			if channel == 0:
				var x_byte = float2byte(clamp(x_curve.interpolate(curve_offset), -1, 1))
				new_data.append(x_byte[0])
				new_data.append(x_byte[1])
			else:
				var y_byte = float2byte(clamp(y_curve.interpolate(curve_offset), -1, 1))
				new_data.append(y_byte[0])
				new_data.append(y_byte[1])
	new_stream_sample.data = new_data
	new_stream_sample.loop_mode = AudioStreamSample.LOOP_FORWARD
	new_stream_sample.loop_end = sample_count - 1
	if Audio_playing:
		var pos = Audio.get_playback_position()
		Audio.stream = new_stream_sample
		Audio.play(pos)

var streampeer = StreamPeerBuffer.new()
func float2byte(_float):
	streampeer.data_array = []
	_float *= 32768
	streampeer.put_16(_float)
	return streampeer.data_array


func _on_Play_Sample_toggled(button_pressed):
	Audio_playing = button_pressed
	if button_pressed:
		_generate_new_audio()
	else:
		Audio.stop()

func _on_Volume_value_changed(value):
	AudioServer.set_bus_volume_db(0, linear2db(value))

var line_item = preload("res://LineTreeItem.tscn")
var button_group = preload("res://LineTreeItemButtonGroup.tres")
func _add_LineTreeItem():
	for i in LineItemContainer.get_children():
		i.button.pressed = false
	var line_item_instance = line_item.instance()
	LineItemContainer.add_child(line_item_instance)
	line_item_instance.root = self
	line_item_instance.setup("Line" + String(LineItemContainer.get_child_count()).pad_zeros(3))
	line_item_instance.button.pressed = true
	line_item_instance.button.group = button_group

func _on_XY_Drawing_line_deselected():
	for i in LineItemContainer.get_children():
		i.button.pressed = false
	LineControls.modulate.a = 0.5
	LineControlsClickProtect.visible = true
	
	LineScaleXY.value = 1
	LineScaleX.value = 1
	LineScaleY.value = 1
	LineOffsetX.value = 1
	LineOffsetY.value = 1
	LineRotationApproximate.value = 0
	LineRotationExact.value = 0

func _on_XY_Drawing_line_destroyed():
	LineItemContainer.get_child(XY_Viewport.selected_line).queue_free()
	_generate_new_audio()

func _delete_line(index):
	yield(get_tree().create_timer(0.01), 'timeout')
	XY_Viewport.lines_data.remove(index)
	XY_Viewport._draw()
	if XY_Viewport.selected_line == index:
		XY_Viewport.selected_line = -1
	elif XY_Viewport.selected_line >= index:
		XY_Viewport.selected_line -= 1
	XY_Viewport.emit_signal('line_updated', XY_Viewport.lines_data)
	for i in LineItemContainer.get_child_count():
		LineItemContainer.get_child(i).get_child(0).text = "Line" + String(i + 1).pad_zeros(3)
	_generate_new_audio()

func _line_selected(index):
	XY_Viewport.selected_line = index
	XY_Viewport._draw()
	LineControls.modulate.a = 1
	LineControlsClickProtect.visible = false


func _open_normal_drawing(content):
	var lines = content.trim_prefix("[").split("], ")
	for line in lines:
		var points = line.trim_prefix("[").trim_suffix("]").split("), ")
		lines_array.append([])
		_add_LineTreeItem()
		for point in points:
			var vector : Vector2
			point = point.trim_prefix("(").trim_suffix(")").split(", ")
			vector.x = float(point[0])
			vector.y = float(point[1])
			lines_array[lines_array.size() - 1].append(vector)

func _open_bummsn_drawing(content):
	var lines = content.trim_prefix("[").split("],")
	for line in lines:
		var points = line.trim_prefix("[").split("},")
		lines_array.append([])
		_add_LineTreeItem()
		for point in points:
			var vector : Vector2
			point = point.trim_prefix("{").trim_suffix("}").split(",")
			vector.x = float(point[0].trim_prefix('"x":')) / 320 - 1
			vector.y = float(point[1].trim_prefix('"y":')) / 320 - 1
			lines_array[lines_array.size() - 1].append(vector)


var previous_line_scale = 1
func _LineScaleXY_changed(value):
	XY_Viewport._scale_drawing(Vector2.ONE + Vector2(value - previous_line_scale,value - previous_line_scale))
	previous_line_scale = value
	LineScaleX.value = value
	LineScaleY.value = value

var previous_line_scale_x = 1
func _LineScaleX_changed(value):
	XY_Viewport._scale_drawing(Vector2.ONE + Vector2(value - previous_line_scale_x,0))
	previous_line_scale_x = value

var previous_line_scale_y = 1
func _LineScaleY_changed(value):
	XY_Viewport._scale_drawing(Vector2.ONE + Vector2(0, value - previous_line_scale_y))
	previous_line_scale_y = value

var previous_line_offset_x = 0
func _LineOffsetX_changed(value):
	XY_Viewport._move_drawing(Vector2.ONE + Vector2(value - previous_line_offset_x, 0))
	previous_line_offset_x = value
	XY_Viewport._clamp_drawing()

var previous_line_offset_y = 0
func _LineOffsetY_changed(value):
	XY_Viewport._move_drawing(Vector2.ONE + Vector2(0, value - previous_line_offset_y))
	previous_line_offset_y
	XY_Viewport._clamp_drawing()

var previous_line_rotation = 0
func _LineRotationApproximate_changed(value):
	XY_Viewport._rotate_drawing(deg2rad(value - previous_line_rotation))
	previous_line_rotation = value
	XY_Viewport._clamp_drawing()
	LineRotationExact.value = value

func _LineRotationExact_changed(value):
	XY_Viewport._rotate_drawing(deg2rad(value - previous_line_rotation))
	previous_line_rotation = value
	XY_Viewport._clamp_drawing()
	LineRotationApproximate.value = value

func _on_Wobble_Adjust_value_changed(value):
	yield(get_tree().create_timer(0.01), 'timeout')
	_generate_new_audio()

