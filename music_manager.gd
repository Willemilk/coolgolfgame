extends Node

var player
var songs = []
var current_song = 0
var volume_db = 0.0


func _ready():
	var music_dir = DirAccess.open("res://music/")
	if music_dir:
		music_dir.list_dir_begin()
		var file = music_dir.get_next()
		while file != "":
			if file.ends_with(".ogg") or file.ends_with(".mp3"):
				songs.append("res://music/" + file)
			file = music_dir.get_next()

	if songs.size() > 0:
		songs.shuffle()
		player = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = volume_db
		add_child(player)
		player.finished.connect(_on_song_finished)
		play_song()


func play_song():
	if songs.size() == 0:
		return
	var stream = load(songs[current_song])
	player.stream = stream
	player.play()


func _on_song_finished():
	current_song += 1
	if current_song >= songs.size():
		current_song = 0
		songs.shuffle()
	play_song()


func set_volume(value):
	volume_db = lerp(-40.0, 0.0, value)
	if player:
		player.volume_db = volume_db


func get_volume_normalized():
	return inverse_lerp(-40.0, 0.0, volume_db)