# YARN BOX
extends Control
class_name YarnBox

#test comment

var title: String

var _dragging := false
var _mouse_focused := false
var _last_mouse := Vector2.ZERO
var _last_position := Vector2.ZERO

func _ready() -> void:
	pass

func parse_thread(yarn: Dictionary, thread_title: String):
	title = thread_title
	var thread: Dictionary = yarn['threads'][thread_title]
	%Title.text = thread_title
	var text := ''
	match thread['kind']:
		'branch':
			for fibre: Dictionary in thread['fibres']:
				match fibre['kind']:
					'text':
						text += fibre['text'] + "\n"
					'choice':
						text += fibre['text'] + "\n"
					'logic':
						text += fibre['instruction'] + " = " + fibre['command'] + "\n"
	%Text.text = text
	
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() && _mouse_focused:
			if not _dragging:
				_last_mouse = get_viewport().get_mouse_position()
				_last_position = position
				_dragging = true
			var _next_mouse = get_viewport().get_mouse_position()
			position = _last_position + _next_mouse - _last_mouse
			dragging_mouse_cursor()
			emit_signal("pressed")
		else:
			_dragging = false
			default_mouse_cursor()
	elif event is InputEventMouseMotion:
		if _dragging:
			var _next_mouse = get_viewport().get_mouse_position()
			position = _last_position + _next_mouse - _last_mouse
			
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

func default_mouse_cursor():
	mouse_default_cursor_shape = CURSOR_POINTING_HAND

func dragging_mouse_cursor():
	mouse_default_cursor_shape = CURSOR_DRAG
