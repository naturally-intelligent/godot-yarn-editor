# YARN EDITOR
extends Control
class_name YarnEditor

@export var verbose := false

var yarn_importer: YarnImporter
var yarn: Dictionary

var current_file: String
var current_node: String
var current_box: YarnBox

var yarn_boxes := {} # pointers
var yarn_strings := {} # pointers

const yarn_box_tscn = preload("res://scenes/yarn-box.tscn")
const yarn_string_tscn = preload("res://scenes/yarn-string.tscn")

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
	load_yarn("user://yarns/sargeant.yarn.txt")

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
	yarn_boxes = {}
	for child in %Canvas.get_children():
		child.queue_free()
	clear_editor()
	
func build_canvas():
	if not yarn:
		return
	# BUILD YARN BOXES
	var pos_move = Vector2(50,50)
	for thread_title: String in yarn['threads']:
		var yarn_box: YarnBox = yarn_box_tscn.instantiate()
		yarn_box.yarn_editor = self
		yarn_box.parse_thread(yarn, thread_title)
		pos_move.x += yarn_box.size.x+10
		if pos_move.x > 1600:
			pos_move.y += yarn_box.size.y+10
			pos_move.x = 10
		yarn_box.position = pos_move
		#yarn_box.size = Vector2(160, 180)
		yarn_box.connect("pressed", Callable(self, "on_thread_pressed").bind(thread_title, yarn_box))
		%Canvas.add_child(yarn_box)
		if verbose:
			print("Added thread: ", thread_title)
		yarn_boxes[thread_title] = yarn_box
	# CONNECT BOXES
	for thread_title: String in yarn['threads']:
		connect_box_strings(thread_title)

func connect_box_strings(thread_title: String):
	var yarn_box = yarn_boxes[thread_title]
	var yarn_thread = yarn['threads'][thread_title]
	for fibre: Dictionary in yarn_thread['fibres']:
		if fibre['kind'] == 'choice':
			var text: String = fibre['text']
			var marker: String = fibre['marker']
			if marker in yarn_boxes:
				var matching_box = yarn_boxes[marker]
				var string: YarnString = yarn_string_tscn.instantiate()
				var from_position = yarn_box.get_string_starting_point(marker, matching_box)
				var to_position = matching_box.get_string_destination_point(marker, yarn_box)
				string.set_string_line(from_position, to_position)
				string.set_label(marker)
				remember_box_string(thread_title, marker, string)
				%Canvas.add_child(string)
			else:
				print("WARNING: Unmatched choice found, from '" + thread_title + "' to '" + marker + "'")

func reconnect_box_strings(thread_title: String, reconnect_children := true):
	clear_box_strings(thread_title)
	connect_box_strings(thread_title)
	if reconnect_children:
		for check_title in yarn_strings:
			for check_marker in yarn_strings[check_title]:
				if check_marker == thread_title:
					reconnect_box_strings(check_title, false)
				
func remember_box_string(thread_title: String, marker: String, yarn_string: YarnString):
	if not thread_title in yarn_strings:
		yarn_strings[thread_title] = {}
	yarn_strings[thread_title][marker] = yarn_string

func clear_box_strings(thread_title: String):
	if thread_title in yarn_strings:
		for marker in yarn_strings[thread_title]:
			var yarn_string = yarn_strings[thread_title][marker]
			yarn_string.queue_free()
		yarn_strings[thread_title] = {}

					
# EDITOR

func clear_editor():
	%HeaderEdit.text = ''
	%TitleEdit.text = ''
	%TextEdit.text = ''
		
func on_thread_pressed(thread_title: String, yarn_box):
	if not thread_title in yarn['threads']:
		print("ERROR! missing yarn thread: ", thread_title)
		return
	var yarn_thread = yarn['threads'][thread_title]
	%HeaderEdit.text = yarn_thread['raw_header']
	%TitleEdit.text = thread_title
	%TextEdit.text = yarn_thread['raw_body']
