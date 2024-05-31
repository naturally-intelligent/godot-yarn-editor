# YARN EDITOR
extends Control
class_name YarnEditor

@export var verbose := false

var yarn_importer: YarnImporter
var yarn: Dictionary

var current_file: String
var current_thread: String

var yarn_boxes := {} # pointers
var yarn_strings := {} # pointers

const yarn_box_tscn = preload("res://scenes/yarn-box.tscn")
const yarn_string_tscn = preload("res://scenes/yarn-string.tscn")

@export var default_spacing_x := 128
@export var default_spacing_y := 80
@export var default_margin_x := 20
@export var default_margin_y := 20

# sorted
var section_owners := {}
var section_level_sizings := {}

func _ready() -> void:
	yarn_importer = YarnImporter.new()
	clear_canvas()
	clear_editor()
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
	if %Filename.text:
		save_yarn(%Filename.text)
	else:
		$SaveAsFileDialog.visible = true
		
func _on_load_pressed():
	$OpenFileDialog.visible = true
	#load_yarn(%Filename.text)

func _on_load_test_pressed() -> void:
	load_yarn("user://yarns/sample2.yarn.txt")

func _on_file_dialog_file_selected(path: String) -> void:
	$OpenFileDialog.visible = false
	load_yarn(path)

func _on_save_as_pressed() -> void:
	$SaveAsFileDialog.visible = true

func _on_save_as_file_dialog_file_selected(path: String) -> void:
	$SaveAsFileDialog.visible = false
	save_yarn(path)

func set_status(message: String):
	%Status.text = "Status: " + message

# CANVAS

func clear_canvas():
	yarn_boxes = {}
	for child in %Canvas.get_children():
		child.queue_free()
	yarn_boxes = {}
	yarn_strings = {}
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
		if auto_position.x > 1200:
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
		if %ShowHeaders.button_pressed or not %ShowTexts.button_pressed:
			yarn_box.update_content(%ShowHeaders.button_pressed, %ShowTexts.button_pressed)
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
			var marker: String = fibre['marker']
			if marker in yarn_boxes:
				if marker != thread_title: # prevent self-reference
					if not has_box_string(thread_title, marker): # prevent duplicates
						var matching_box = yarn_boxes[marker]
						var string: YarnString = yarn_string_tscn.instantiate()
						var from_position = yarn_box.get_string_starting_point(marker, matching_box)
						var to_position = matching_box.get_string_destination_point(marker, yarn_box)
						string.set_string_line(from_position, to_position)
						string.set_label(marker)
						remember_box_string(thread_title, marker, string)
						# while we could store these inside each box, its annoying to handle coordinates
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

func has_box_string(thread_title: String, marker: String) -> bool:
	if thread_title in yarn_strings:
		if marker in yarn_strings[thread_title]:
			return true
	return false
	
func remember_box_string(thread_title: String, marker: String, yarn_string: YarnString):
	if not thread_title in yarn_strings:
		yarn_strings[thread_title] = {}
	yarn_strings[thread_title][marker] = yarn_string

func clear_box_strings(thread_title: String):
	if thread_title in yarn_strings:
		for marker: String in yarn_strings[thread_title]:
			var yarn_string = yarn_strings[thread_title][marker]
			yarn_string.queue_free()
		yarn_strings[thread_title] = {}

func delete_box_strings(thread_title: String):
	if thread_title in yarn_strings:
		for marker: String in yarn_strings[thread_title]:
			var yarn_string = yarn_strings[thread_title][marker]
			yarn_string.queue_free()
		yarn_strings.erase(thread_title)
	for title_test in yarn_strings:
		for marker: String in yarn_strings[title_test]:
			if marker == thread_title:
				yarn_strings[title_test][marker].queue_free()
				yarn_strings[title_test].erase(marker)
		
# EDITOR

func clear_editor():
	%NodeTitle.text = ''
	%NodeHeader.text = ''
	%NodeText.text = ''
	current_thread = ''
	update_buttons()
		
func _on_thread_pressed(thread_title: String, yarn_box):
	update_editor(thread_title)
	
func update_editor(thread_title: String):
	if not thread_title in yarn['threads']:
		print("ERROR! missing yarn thread: ", thread_title)
		return
	var yarn_thread = yarn['threads'][thread_title]
	%NodeTitle.text = thread_title
	%NodeHeader.text = yarn_thread['raw_header']
	%NodeText.text = yarn_thread['raw_body']
	current_thread = thread_title
	update_buttons()

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

func _on_header_text_changed():
	update_buttons()
	
func _on_update_header_pressed() -> void:
	if current_thread and current_thread in yarn_boxes:
		var old_thread = yarn['threads'][current_thread]
		# update body
		if true:
			#var old_text = old_thread['raw_body']
			#if %NodeText.text != old_text:
			var new_fibres = yarn_importer.yarn_body_fibres(%NodeText.text)
			yarn['threads'][current_thread]['fibres'] = new_fibres
			reconnect_box_strings(current_thread)
			var yarn_box: YarnBox = yarn_boxes[current_thread]
			yarn_box.parse_thread(yarn, current_thread)
		# update header
		var new_attributes = yarn_importer.yarn_header_attributes(%NodeHeader.text)
		if not 'title' in new_attributes:
			set_status("Missing 'title' in header. Ignoring")
			return
		if new_attributes['title'] != current_thread:
			var new_title = new_attributes['title']
			yarn['threads'][new_title] = yarn['threads'][current_thread].duplicate(true)
			yarn['threads'][new_title]['raw_header'] = %NodeHeader.text
			yarn['threads'][new_title]['header'] = new_attributes
			yarn['threads'].erase(current_thread)
			clear_canvas()
			build_canvas()
			update_editor(new_title)
		else:
			yarn['threads'][current_thread]['raw_header'] = %NodeHeader.text
			yarn['threads'][current_thread]['header'] = new_attributes
			var yarn_box: YarnBox = yarn_boxes[current_thread]
			yarn_box.parse_thread(yarn, current_thread)
			reconnect_box_strings(current_thread)
	
func _on_body_text_changed():
	if current_thread and current_thread in yarn_boxes:
		yarn['threads'][current_thread]['raw_body'] = %NodeText.text
		var yarn_box = yarn_boxes[current_thread]
		yarn_box.update_text(%NodeText.text)

# DELETE

func delete_thread(thread_name: String):
	clear_editor()
	yarn.erase(thread_name)
	delete_box_strings(thread_name)
	yarn_boxes[thread_name].queue_free()
	yarn_boxes.erase(thread_name)
	#clear_canvas()
	#build_canvas()
	set_status("Deleted " + thread_name)

func _on_delete_pressed() -> void:
	if current_thread:
		$DeleteConfirmationDialog.visible = true
	
func _on_delete_confirmation_dialog_confirmed() -> void:
	if current_thread:
		delete_thread(current_thread)

# AUTOSORT

func _on_vertical_sort_pressed() -> void:
	if not yarn:
		return
	# data sort
	set_status("Starting data sort...")
	await get_tree().process_frame
	collect_thread_sort_data()
	# visually sort
	set_status("Starting visual sort...")
	await get_tree().process_frame
	const section_padding = 200
	const level_padding = 10
	const order_padding = 20
	const level_height = 200
	const order_width = 250
	const top_margin = 15
	const left_margin = 10
	var widest_x := 0
	var widest_y := 0
	# section loop (automatically sorted to tree/loop/solo)
	var section_size := Vector2.ZERO
	for section: int in section_owners:
		var level_size := Vector2.ZERO
		for thread_title: String in yarn_boxes:
			var yarn_box: YarnBox = yarn_boxes[thread_title]
			if yarn_box.section == section:
				var box_rect := yarn_box.get_rect()
				var section_pos := Vector2.ZERO
				var order = yarn_box.order
				if yarn_box.section_kind == 'tree' and order == 0:
					order = 1.5
				if yarn_box.section_kind == 'solo':
					order += 0.5
				section_pos = yarn_box.level*Vector2(0,level_height+level_padding) + order*Vector2(order_width+order_padding,0)
				if level_size.y < section_pos.y:
					level_size.y = section_pos.y
				yarn_box.position = section_size + section_pos + Vector2(left_margin,top_margin)
				if yarn_box.position.x > widest_x:
					widest_x = yarn_box.position.x
				if yarn_box.position.y > widest_y:
					widest_y = yarn_box.position.y
				reconnect_box_strings(thread_title)
				#yarn_box.debug_sort()
		section_size += level_size + Vector2(0, section_padding)
	update_canvas_size(widest_x, widest_y)
	mark_positions()
	set_status("Done sort!")

func collect_thread_sort_data():
	section_owners = {}
	# reset all
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		yarn_box.reset_sort_data()
	# collect pointing threads
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		var yarn_thread = yarn['threads'][thread_title]
		for fibre: Dictionary in yarn_thread['fibres']:
			if fibre['kind'] == 'choice':
				var marker: String = fibre['marker']
				if marker in yarn_boxes:
					var matching_box = yarn_boxes[marker]
					yarn_box.threads_pointing_out.append(marker)
					matching_box.threads_pointing_in.append(thread_title)
	# find tree sections
	var section_counter := 0
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		if yarn_box.threads_pointing_in.is_empty() and not yarn_box.threads_pointing_out.is_empty():
			yarn_box.is_top_level = true
			section_counter += 1
			yarn_box.section = section_counter
			yarn_box.section_kind = 'tree'
			mark_section_threads(thread_title)
			section_owners[section_counter] = thread_title
		if yarn_box.threads_pointing_out.is_empty():
			yarn_box.is_bottom_level = true
	# find looped sections
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		if yarn_box.section == 0:
			if not yarn_box.threads_pointing_in.is_empty() and not yarn_box.threads_pointing_out.is_empty():
				section_counter += 1
				yarn_box.section = section_counter
				yarn_box.section_kind = 'loop'
				mark_section_threads(thread_title)
				section_owners[section_counter] = thread_title
	# find remaining stranded/solo threads and put them in bunches of sections
	const max_stranded_per_section = 4
	var stranded_per_section = max_stranded_per_section
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		if yarn_box.section == 0:
			stranded_per_section += 1
			if stranded_per_section >= max_stranded_per_section:
				section_counter += 1
				stranded_per_section = 0
				section_owners[section_counter] = thread_title
			yarn_box.section = section_counter
			yarn_box.order = stranded_per_section
			yarn_box.section_kind = 'solo'
			mark_section_threads(thread_title)
	# find best sizes per level
	var level_sizes = {}
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		if not yarn_box.section in level_sizes:
			level_sizes[yarn_box.section] = {}
		if not yarn_box.level in level_sizes[yarn_box.section]:
			level_sizes[yarn_box.section][yarn_box.level] = []
		level_sizes[yarn_box.section][yarn_box.level].append(yarn_box.get_rect())
	section_level_sizings = {}
	
func mark_section_threads(thread_title: String, level := 1):
	var yarn_box = yarn_boxes[thread_title]
	var order := 0
	for marker: String in yarn_box.threads_pointing_out:
		var matching_box = yarn_boxes[marker]
		if matching_box.section == 0:
			matching_box.section = yarn_box.section
			matching_box.level = level
			order = order + 1
			matching_box.order = order
			mark_section_threads(marker, level+1)
			
func mark_positions() -> void:
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		yarn_box.mark_layout()
	if current_thread:
		update_editor(current_thread)

func _on_show_headers_toggled(toggled_on: bool) -> void:
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		yarn_box.update_content(%ShowHeaders.button_pressed, %ShowTexts.button_pressed)

func _on_show_text_toggled(toggled_on: bool) -> void:
	for thread_title: String in yarn_boxes:
		var yarn_box: YarnBox = yarn_boxes[thread_title]
		yarn_box.update_content(%ShowHeaders.button_pressed, %ShowTexts.button_pressed)

# CREATE A NODE

func _on_create_node_pressed() -> void:
	var thread = yarn_importer.new_yarn_thread()
	thread['raw_header'] = %NodeHeader.text
	thread['raw_body'] = %NodeText.text
	thread['header'] = yarn_importer.yarn_header_attributes(thread['raw_header'])
	thread['fibres'] = yarn_importer.yarn_body_fibres(thread['raw_body'])
	if not 'title' in thread['header']:
		set_status("DENIED: No title set.")
		return
	var thread_title = thread['header']['title']
	if thread_title in yarn['threads']:
		set_status("DENIED: Already have this title.")
		return
	yarn['threads'][thread_title] = thread
	var yarn_box: YarnBox = yarn_box_tscn.instantiate()
	yarn_box.yarn_editor = self
	yarn_box.parse_thread(yarn, thread_title)
	yarn_box.position = Vector2(1,1)
	yarn_box.connect("pressed", Callable(self, "_on_thread_pressed").bind(thread_title, yarn_box))
	if %ShowHeaders.button_pressed or not %ShowTexts.button_pressed:
		yarn_box.update_content(%ShowHeaders.button_pressed, %ShowTexts.button_pressed)
	%Canvas.add_child(yarn_box)
	yarn_boxes[thread_title] = yarn_box
	connect_box_strings(thread_title)
	update_editor(thread_title)
	
func _on_clear_pressed() -> void:
	clear_editor()

func update_buttons():
	if current_thread:
		%UpdateHeader.disabled = false
		%DeleteNode.disabled = false
	else:
		%UpdateHeader.disabled = true
		%DeleteNode.disabled = true

	
