# YARN EDITOR
extends Control
class_name YarnEditor

var yarn_importer: YarnImporter
var yarn: Dictionary

var current_file: String
var current_node: String
var current_box: YarnBox

const yarn_box_tscn = preload("res://scenes/yarn-box.tscn")

func _ready() -> void:
	yarn_importer = YarnImporter.new()
	clear_canvas()
	set_status("Ready")
	update_editor()
	
# FILES

func _on_new_pressed() -> void:
	current_file = ''
	%Filename.text = 'New / Unsaved'
	yarn = {}
	clear_canvas()
	set_status("New")

func load_yarn(file: String) -> bool:
	yarn = yarn_importer.load_yarn(file)
	if yarn:
		current_file = file
		%Filename.text = file
		set_status("Loaded file!")
		print(yarn)
		clear_canvas()
		build_canvas()
		return true
	set_status("Failed to load file!")
	return false

func _on_load_test_pressed() -> void:
	load_yarn("res://yarns/sargeant.yarn.txt")

func set_status(message: String):
	%Status.text = "Status: " + message

# EDITOR

func update_editor():
	if current_node:
		pass
	else:
		pass

# CANVAS

func clear_canvas():
	for child in %Canvas.get_children():
		child.queue_free()
		
func build_canvas():
	if not yarn:
		return
	var pos_move = Vector2(50,50)
	for thread_title in yarn['threads']:
		var yarn_box = yarn_box_tscn.instantiate()
		yarn_box.parse_thread(yarn, thread_title)
		pos_move.x += yarn_box.size.x+10
		if pos_move.x > 1600:
			pos_move.y += yarn_box.size.y+10
			pos_move.x = 10
		yarn_box.position = pos_move
		#yarn_box.size = Vector2(160, 180)
		yarn_box.connect("pressed", Callable(self, "on_box_pressed").bind(thread_title, yarn_box))
		%Canvas.add_child(yarn_box)
		print("Added thread: ", thread_title)
	
func on_box_pressed(thread_title: String, yarn_box):
	print(thread_title)
	%TitleEdit.text = thread_title
	%TextEdit.text = ''
