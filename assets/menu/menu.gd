extends Control

signal play()
signal pause()
signal resume()
signal menu()
signal quit()

@onready
var _game_title_screen: Control = $game_title_screen as Control
@onready
var _game_title_screen_button_play: BaseButton = $game_title_screen/buttons_container/play as BaseButton
@onready
var _game_title_screen_button_quit: BaseButton = $game_title_screen/buttons_container/quit as BaseButton
@onready
var _game_title_screen_slider_sound: Slider = $game_title_screen/buttons_container/sound/h_slider as Slider
@onready
var _game_title_screen_slider_music: Slider = $game_title_screen/buttons_container/music/h_slider as Slider

@onready
var _game_pause_screen: Control = $game_pause_screen as Control
@onready
var _game_pause_screen_button_resume: BaseButton = $game_pause_screen/buttons_container/resume as BaseButton
@onready
var _game_pause_screen_button_menu: BaseButton = $game_pause_screen/buttons_container/menu as BaseButton
@onready
var _game_pause_screen_slider_sound: Slider = $game_pause_screen/buttons_container/sound/h_slider as Slider
@onready
var _game_pause_screen_slider_music: Slider = $game_pause_screen/buttons_container/music/h_slider as Slider

@onready
var _game_lose_screen: Control = $game_lose_screen as Control
@onready
var _game_lose_screen_button_menu: BaseButton = $game_lose_screen/buttons_container/menu as BaseButton

@onready
var _game_win_screen: Control = $game_win_screen as Control
@onready
var _game_win_screen_button_menu: BaseButton = $game_win_screen/buttons_container/menu as BaseButton

@onready
var _game_play_screen: Control = $game_play_screen as Control
@onready
var _game_play_screen_progress_fear: TextureProgressBar = $game_play_screen/bar_fear_meter as TextureProgressBar
@onready
var _game_play_screen_progress_health: TextureProgressBar = $game_play_screen/bar_health_meter as TextureProgressBar

@onready
var _music_menu: AudioStreamPlayer = $music/music_menu as AudioStreamPlayer
@onready
var _music_low_fear: AudioStreamPlayer = $music/music_low_fear as AudioStreamPlayer
@onready
var _music_medium_fear: AudioStreamPlayer = $music/music_medium_fear as AudioStreamPlayer
@onready
var _music_high_fear: AudioStreamPlayer = $music/music_high_fear as AudioStreamPlayer
@onready
var _music_game_over: AudioStreamPlayer = $music/music_game_over as AudioStreamPlayer

enum ActiveScreen { MENU, PAUSE, LOSE, WIN, PLAY }
var _active_screen: ActiveScreen = ActiveScreen.MENU

func set_active_screen(active_screen: ActiveScreen) -> void:
	_active_screen = active_screen
	match _active_screen:
		ActiveScreen.MENU:
			_game_title_screen.visible = true
			_game_pause_screen.visible = false
			_game_lose_screen.visible = false
			_game_win_screen.visible = false
			_game_play_screen.visible = false
			
			_music_menu.playing = true
			_music_low_fear.playing = false
			_music_medium_fear.playing = false
			_music_high_fear.playing = false
			_music_game_over.playing = false
		ActiveScreen.PAUSE:
			_game_title_screen.visible = false
			_game_pause_screen.visible = true
			_game_lose_screen.visible = false
			_game_win_screen.visible = false
			_game_play_screen.visible = false
			
			_music_menu.playing = true
			_music_low_fear.playing = false
			_music_medium_fear.playing = false
			_music_high_fear.playing = false
			_music_game_over.playing = false
		ActiveScreen.LOSE:
			_game_title_screen.visible = false
			_game_pause_screen.visible = false
			_game_lose_screen.visible = true
			_game_win_screen.visible = false
			_game_play_screen.visible = false
			
			_music_menu.playing = false
			_music_low_fear.playing = false
			_music_medium_fear.playing = false
			_music_high_fear.playing = false
			_music_game_over.playing = true
		ActiveScreen.WIN:
			_game_title_screen.visible = false
			_game_pause_screen.visible = false
			_game_lose_screen.visible = false
			_game_win_screen.visible = true
			_game_play_screen.visible = false
			
			_music_menu.playing = false
			_music_low_fear.playing = false
			_music_medium_fear.playing = false
			_music_high_fear.playing = true
			_music_game_over.playing = false
		ActiveScreen.PLAY:
			_game_title_screen.visible = false
			_game_pause_screen.visible = false
			_game_lose_screen.visible = false
			_game_win_screen.visible = false
			_game_play_screen.visible = true
			
			_music_menu.playing = false
			_music_low_fear.playing = true
			_music_medium_fear.playing = false
			_music_high_fear.playing = false
			_music_game_over.playing = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_game_title_screen_button_play.pressed.connect(_play)
	_game_title_screen_button_quit.pressed.connect(_quit)
	_game_title_screen_slider_sound.value_changed.connect(_set_sound)
	_game_title_screen_slider_music.value_changed.connect(_set_music)
	
	_game_pause_screen_button_resume.pressed.connect(_resume)
	_game_pause_screen_button_menu.pressed.connect(_menu)
	_game_pause_screen_slider_sound.value_changed.connect(_set_sound)
	_game_pause_screen_slider_music.value_changed.connect(_set_music)
	
	_game_lose_screen_button_menu.pressed.connect(_menu)
	
	_game_win_screen_button_menu.pressed.connect(_menu)
	
	set_active_screen(ActiveScreen.MENU)

func win(score: int = 0, hunted: bool = false) -> void:
	set_active_screen(ActiveScreen.WIN)

func lose(score: int = 0, hunted: bool = false) -> void:
	set_active_screen(ActiveScreen.LOSE)

func _play() -> void:
	set_active_screen(ActiveScreen.PLAY)
	play.emit()

func _quit() -> void:
	quit.emit()

func _pause() -> void:
	set_active_screen(ActiveScreen.PAUSE)
	pause.emit()

func _resume() -> void:
	set_active_screen(ActiveScreen.PLAY)
	resume.emit()

func _menu() -> void:
	set_active_screen(ActiveScreen.MENU)
	menu.emit()

func set_global_scare(global_scare: float) -> void:
	pass# probably not needed since we have percent

func set_player_health_percent(percent: float) -> void:
	_game_play_screen_progress_health.value = percent

func set_player_candy_count(candy_count: int) -> void:
	pass# TODO: implement me!

func set_tricker_count(tricker_count: int) -> void:
	pass# TODO: implement me!

func set_global_scare_threshold_percents(thresholds: Array[float]) -> void:
	# temporary
	var total: float = 0.0
	for threshold: float in thresholds:
		total += threshold
	var percent: float = total / thresholds.size()
	_game_play_screen_progress_fear.value = percent

func _set_sound(value: float) -> void:
	AudioServer.set_bus_volume_db(1, remap(value, 0.0, 100.0, -24.0, 0.0))

func _set_music(value: float) -> void:
	AudioServer.set_bus_volume_db(2, remap(value, 0.0, 100.0, -24.0, 0.0))

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if Input.is_action_just_pressed("pause"):
		if _active_screen == ActiveScreen.PLAY:
			_pause()
		elif _active_screen == ActiveScreen.PAUSE:
			_resume()

func _process(delta: float) -> void:
	_game_title_screen_slider_sound.value = remap(AudioServer.get_bus_volume_db(1), -24.0, 0.0, 0.0, 100.0)
	_game_title_screen_slider_music.value = remap(AudioServer.get_bus_volume_db(2), -24.0, 0.0, 0.0, 100.0)
	_game_pause_screen_slider_sound.value = remap(AudioServer.get_bus_volume_db(1), -24.0, 0.0, 0.0, 100.0)
	_game_pause_screen_slider_music.value = remap(AudioServer.get_bus_volume_db(2), -24.0, 0.0, 0.0, 100.0)
