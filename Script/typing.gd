extends Node2D


var word_list: Array= ["a", "about", "and", "any", "as", "ask", "at", "back", "be", "but", "by", 
"can", "come", "do", "down", "end", "few", "find", "for", "go", 
"group", "have", "he", "help", "home", "house", "how", "I", "if", "in", "into", "it", "large", "last", "late", "lead", "life", "line", "man", "many", "may", "more", "move", "new", "no", "not", "now", "of", "on", "one", "open", "or", "other", "out", "own", "part", "plan", "play", "point", "real", "run", "same", "say", "set", "she", "so", "some", "take", "the", 
"this", "those", "time", "to", "turn", "up", "use", "want", "we", "what", "who", "with", "work", "you"]



var word :Array= []
var current_index: int = 0 

func _ready() -> void:
	generate_words()
	render_words()
	$LineEdit.editable = true
	$LineEdit.modulate.a = 0
	$LineEdit.text_changed.connect(highlight)
	$LineEdit.grab_focus()
	$RichTextLabel.bbcode_enabled= true
func generate_words() -> void:
	word.clear()
	for i: int in range(5):
		word.append(word_list.pick_random())
	current_index= 0	
func render_words() -> void:
	for i: Label in $HBoxContainer.get_children():
		i.free()
	
	for i: int in range(word.size()):
		var libil: Label = Label.new()
		libil.text = word[i]
		if i == current_index:
			libil.modulate = Color.GOLD
		else:
			libil.modulate = Color.WHITE
		$HBoxContainer.add_child(libil)		
func highlight(text: String = " ") -> void:
	var typed: String  = $LineEdit.text 
	var target: String = word[current_index]
	var result: String = ""
	for j in range(word.size()):
		var current_word: String = word[j]
		
		if j == current_index:
			for i: int in range(target.length()):
				if i < typed.length():
					if typed[i] == current_word[i]: 
						result += "[color=green]" + current_word[i] +"[/color]"
					else:
						result += "[color=red]" + current_word[i] + "[/color]"
				else:
					result += "[tornado radius= 10lallllllll freq= 10]" + current_word[i] + "[/tornado]"	
		else:
			result += "[color= white]" + current_word + "[/color]"	
		result +=" "	
	$RichTextLabel.text = result
			
		
	for i: int in range($HBoxContainer.get_child_count()):
		var libil: Label =$HBoxContainer.get_child(i)
		if i == current_index:
			libil.modulate= Color.YELLOW
		else:
			libil.modulate = Color.WHITE	
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		highlight()
		if event.keycode == KEY_SPACE:
			check_word()
			$LineEdit.text = ""
			$LineEdit.grab_focus()
			get_viewport().set_input_as_handled()
			highlight()

func check_word() -> void:


	var typed: String = $LineEdit.text.strip_edges()
	if current_index>=word.size():
		return
			
	if typed == word[current_index]:
		print("NICE")
		$"../Player".attack() 
	else:
		print("NOT NICE")	
		$"../Player".hurt(5)
	current_index+= 1
	$LineEdit.text=""
	if current_index == word.size():
		current_index= 0 
		generate_words()		
		render_words()
