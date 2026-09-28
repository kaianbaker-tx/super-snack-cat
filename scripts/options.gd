extends CanvasLayer

# ============================================================
#    THE OPTIONS BOX
#
#    Press P while you're playing to open it. The game freezes
#    while it's up, so nothing can sneak up on you.
#
#    Every sound in the game goes down one of two pipes:
#    the MUSIC pipe or the SOUND pipe. Each slider turns the
#    volume of one pipe up and down.
#
#    The game remembers which level you got to. Press N while
#    this box is open to go all the way back to World 1-1.
# ============================================================

# Where your settings get remembered, so the game starts the way
# you left it next time.
const SETTINGS_FILE = "user://settings.cfg"

# What the sliders start at the very first time you ever play.
const MUSIC_TO_START_WITH = 0.45
const SOUND_TO_START_WITH = 0.9


func _ready():
	# Keep working even while the rest of the game is frozen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	$Panel/Box/MusicSlider.value_changed.connect(music_moved)
	$Panel/Box/SoundSlider.value_changed.connect(sound_moved)
	load_your_settings()


# This box listens for its own key, because while the game is frozen
# the level itself has stopped listening for anything.
func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_P:
		open_or_close()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and visible:
		open_or_close()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_N and visible:
		# Back to the very first level. Only works while the box is
		# open, so you can't do it by accident while playing.
		var world = get_tree().current_scene
		if world.has_method("start_again_from_world_one"):
			get_viewport().set_input_as_handled()
			world.start_again_from_world_one()


func open_or_close():
	visible = not visible
	get_tree().paused = visible
	if visible:
		$Panel/Box/MusicSlider.grab_focus()


func music_moved(how_loud):
	turn_the_volume(&"Music", how_loud)
	remember_your_settings()


func sound_moved(how_loud):
	turn_the_volume(&"Sound", how_loud)
	remember_your_settings()


# Sliders count 0 to 1, but loudness is measured in decibels, which
# go up in a curve rather than a straight line. linear_to_db does
# that sum for us. All the way down means silence.
func turn_the_volume(which_pipe, how_loud):
	var pipe = AudioServer.get_bus_index(which_pipe)
	AudioServer.set_bus_volume_db(pipe, linear_to_db(how_loud))
	AudioServer.set_bus_mute(pipe, how_loud < 0.005)


func remember_your_settings():
	var settings = ConfigFile.new()
	settings.set_value("volume", "music", $Panel/Box/MusicSlider.value)
	settings.set_value("volume", "sound", $Panel/Box/SoundSlider.value)
	settings.save(SETTINGS_FILE)


func load_your_settings():
	var settings = ConfigFile.new()
	var music = MUSIC_TO_START_WITH
	var sound = SOUND_TO_START_WITH

	# If there's no settings file yet, this quietly does nothing and
	# we keep the starting numbers above.
	if settings.load(SETTINGS_FILE) == OK:
		music = settings.get_value("volume", "music", music)
		sound = settings.get_value("volume", "sound", sound)

	$Panel/Box/MusicSlider.value = music
	$Panel/Box/SoundSlider.value = sound
	turn_the_volume(&"Music", music)
	turn_the_volume(&"Sound", sound)
