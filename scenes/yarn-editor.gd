# YARN EDITOR
extends Control
class_name YarnEditor

@export var verbose := false

var yarn_importer: YarnImporter
var yarn: Dictionary

var current_file: String
var current_thread: String
var current_box: YarnBox

var yarn_boxes := {} # pointers
var yarn_strings := {} # pointers

const yarn_box_tscn = preload("res://scenes/yarn-box.tscn")
const yarn_string_tscn = preload("res://scenes/yarn-string.tscn")

@export var default_spacing_x := 128
@export var default_spacing_y := 80
@export var default_margin_x := 20
@export var default_margin_y := 20

func _ready() -> void:
	yarn_importer = YarnImporter.new()
	clear_canvas()
	set_status("Ready")
	# test
	_on_load_test_pressed()
	
# FILES

func _on_new_pressed() -> void:
	current_file = 'user://yarns/new.yarn.txt'
	%Filename.text = current_file
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

func save_yarn(file: String) -> bool:
	if yarn_importer.save_yarn(file, yarn):
		set_status("Saved yarn file!")
		%Filename.text = file
		return true
	else:
		set_status("Failed to save file!")
		return false

func _on_save_pressed():
	save_yarn(%Filename.text)

func _on_load_pressed():
	load_yarn(%Filename.text)

func _on_load_test_pressed() -> void:
	load_yarn("user://yarns/sample2.yarn.txt")

func set_status(message: String):
	%Status.text = "Status: " + message

# CANVAS

func clear_canvas():
	yarn_boxes = {}
	for child in %Canvas.get_children():
		child.queue_free()
	clear_editor()
	
func build_canvas():
	if not yarn:
		return
	# build yarn boxes
	var auto_position := Vector2(default_margin_x, default_margin_y)
	var widest_x := 0
	var widest_y := 0
	for thread_title: String in yarn['threads']:
		var yarn_box: YarnBox = yarn_box_tscn.instantiate()
		yarn_box.yarn_editor = self
		yarn_box.parse_thread(yarn, thread_title)
		# auto positioning
		auto_position.x += yarn_box.size.x + default_spacing_x
		if auto_position.x > 1600:
			auto_position.y += yarn_box.size.y + default_spacing_y
			auto_position.x = default_margin_x
		if not yarn_box.custom_position:
			yarn_box.position = auto_position
		# canvas edges
		if yarn_box.position.x > widest_x:
			widest_x = yarn_box.position.x
		if yarn_box.position.y > widest_y:
			widest_y = yarn_box.position.y
		yarn_box.connect("pressed", Callable(self, "_on_thread_pressed").bind(thread_title, yarn_box))
		%Canvas.add_child(yarn_box)
		if verbose:
			print("Added thread: ", thread_title)
		yarn_boxes[thread_title] = yarn_box
	# canvas size
	widest_x += default_spacing_x*3
	widest_y += default_spacing_y*2
	update_canvas_size(widest_x, widest_y)
	# connect strings
	for thread_title: String in yarn['threads']:
		connect_box_strings(thread_title, true)

func update_canvas_size(widest_x: int, widest_y: int):
	widest_x += default_spacing_x*3 + default_margin_x
	widest_y += default_spacing_y*2 + default_margin_y
	if %Canvas.custom_minimum_size.x < widest_x:
		%Canvas.custom_minimum_size.x = widest_x
	if %Canvas.custom_minimum_size.y < widest_y:
		%Canvas.custom_minimum_size.y = widest_y
	%Canvas.size = %Canvas.custom_minimum_size

# STRINGS

func connect_box_strings(thread_title: String, first_build := false):
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
				# only need to show this warning on first load
				if first_build:
					print("WARNING: Unmatched choice found, from '" + thread_title + "' to '" + marker + "'")

func reconnect_box_strings(thread_title: String, reconnect_neighbors := true):
	clear_box_strings(thread_title)
	connect_box_strings(thread_title)
	if reconnect_neighbors:
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
		
func _on_thread_pressed(thread_title: String, yarn_box):
	update_editor(thread_title)
	
func update_editor(thread_title: String):
	if not thread_title in yarn['threads']:
		print("ERROR! missing yarn thread: ", thread_title)
		return
	var yarn_thread = yarn['threads'][thread_title]
	%HeaderEdit.text = yarn_thread['raw_header']
	%TitleEdit.text = thread_title
	%TextEdit.text = yarn_thread['raw_body']
	current_thread = thread_title

func update_thread(thread_title: String, section: String, attribute: String, value: String):
	yarn['threads'][thread_title][section][attribute] = value
	if section == 'header':
		recalculate_raw_header(thread_title)
	update_editor(thread_title)
	
func recalculate_raw_header(thread_title: String):
	var thread: Dictionary = yarn['threads'][thread_title]
	var raw_header := ''
	for key: String in thread['header']:
		var value: String = thread['header'][key]
		raw_header += key + ': ' + value + "\n"
	yarn['threads'][thread_title]['raw_header'] = raw_header

func _on_title_text_changed(new_text):
	pass

func _on_header_text_changed():
	yarn['threads'][current_thread]['raw_header'] = %HeaderEdit.text
	# recalculate header

func _on_body_text_changed():
	yarn['threads'][current_thread]['raw_body'] = %TextEdit.text
