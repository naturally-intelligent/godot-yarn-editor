# YARN BOX
extends Control
class_name YarnBox

#test comment

var title: String

var _dragging := false
var _mouse_focused := false
var _last_mouse := Vector2.ZERO
var _last_position := Vector2.ZERO

var custom_position := false

var yarn_editor: YarnEditor

func _ready() -> void:
	pass

func parse_thread(yarn: Dictionary, thread_title: String):
	title = thread_title
	var thread: Dictionary = yarn['threads'][thread_title]
	%Title.text = thread_title
	%Text.text = thread['raw_body']
	if 'position' in thread['header']:
		var vec_string = thread['header']['position']
		var vec_split = vec_string.split(',')
		var vec_x = int(vec_split[0])
		var vec_y = int(vec_split[1])
		position = Vector2(vec_x, vec_y)
		custom_position = true
	if 'size' in thread['header']:
		var vec_string = thread['header']['size']
		var vec_split = vec_string.split(',')
		var vec_x = int(vec_split[0])
		var vec_y = int(vec_split[1])
		size = Vector2(vec_x, vec_y)
	
func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed() && _mouse_focused:
			if not _dragging:
				_last_mouse = get_viewport().get_mouse_position()
				_last_position = position
				_dragging = true
			var _next_mouse = get_viewport().get_mouse_position()
			var _current_postion = position
			position = _last_position + _next_mouse - _last_mouse
			if _current_postion != position:
				yarn_editor.reconnect_box_strings(title)
				yarn_editor.update_canvas_size(position.x + size.x, position.y + size.y)
				yarn_editor.update_thread(title, "header", "position", str(position.x) + ',' + str(position.y))
			dragging_mouse_cursor()
			emit_signal("pressed")
		else:
			_dragging = false
			default_mouse_cursor()
	elif event is InputEventMouseMotion:
		if _dragging:
			var _next_mouse = get_viewport().get_mouse_position()
			var _current_postion = position
			position = _last_position + _next_mouse - _last_mouse
			if _current_postion != position:
				update_strings()
				yarn_editor.update_thread(title, "header", "position", str(position.x) + ',' + str(position.y))
				yarn_editor.update_canvas_size(position.x + size.x, position.y + size.y)

func update_strings():
	yarn_editor.reconnect_box_strings(title)
			
func _on_mouse_entered() -> void:
	if not _dragging:
		_mouse_focused = true
		_last_mouse = Vector2.ZERO
		_dragging = false
		default_mouse_cursor()
		
func _on_mouse_exited() -> void:
	if not _dragging:
		_mouse_focused = false
		_dragging = false
		default_mouse_cursor()

func _on_focus_exited():
	_mouse_focused = false
	_dragging = false
	default_mouse_cursor()

func default_mouse_cursor():
	mouse_default_cursor_shape = CURSOR_POINTING_HAND

func dragging_mouse_cursor():
	mouse_default_cursor_shape = CURSOR_DRAG

# STRINGS

func get_string_starting_point(choice_marker: String, destination_box: YarnBox) -> Vector2:
	var center = get_center_point()
	return center

func get_string_destination_point(choice_marker: String, starting_box: YarnBox) -> Vector2:
	var center = get_center_point()
	return center

func get_center_point() -> Vector2:
	return position + size/2

# RESIZE

func _on_resized():
	yarn_editor.update_thread(title, "header", "size", str(size.x) + ',' + str(size.y))
	yarn_editor.reconnect_box_strings(title)
