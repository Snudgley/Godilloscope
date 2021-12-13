extends Panel

var spec_data
var f_data = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	spec_data = AudioServer.get_bus_effect_instance(0,1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()

func _draw():	
	var VU_COUNT = 16
	var HEIGHT = rect_size.y /2
	var w = rect_size.x / VU_COUNT
	var prev_hz = 0
	for i in range(0,VU_COUNT):   
		var hz = i * 8000 / VU_COUNT;
		var f = spec_data.get_magnitude_for_frequency_range(prev_hz,hz)
		var energyL = clamp((60 + linear2db(f.x))/60,0,1)
		var energyR = clamp((60 + linear2db(f.y))/60,0,1)
		var height = energyL * HEIGHT
		draw_rect(Rect2(w*i,HEIGHT-height,w,height),Color(.8,1,.9))
		height = energyR * HEIGHT
		draw_rect(Rect2(w*i,HEIGHT,w,height),Color(.7,.9,.8))
		prev_hz = hz
