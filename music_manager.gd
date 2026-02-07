extends Node

var songs = [
	"res://music/lensko_cetus.mp3"
]
var current_song = 0
var volume_linear = 0.8
var player: AudioStreamPlayer


func _ready():
	player = AudioStreamPlayer.new()
	player.bus = &"Master"
	add_child(player)
	player.finished.connect(_on_song_finished)

	if songs.size() > 0:
		songs.shuffle()
		call_deferred("play_song")


func play_song():
	if songs.size() == 0 or current_song >= songs.size():
		return

	var stream = load(songs[current_song])
	if stream == null:
		push_warning("MusicManager: Could not load " + songs[current_song])
		return

	if stream is AudioStreamMP3:
		stream.loop = false

	player.stream = stream
	player.volume_db = linear_to_db(volume_linear)
	player.play()
	print("MusicManager: Now playing " + songs[current_song] + " at " + str(player.volume_db) + " dB")


func _on_song_finished():
	current_song += 1
	if current_song >= songs.size():
		current_song = 0
		songs.shuffle()
	play_song()


func set_volume(value):
	volume_linear = clampf(value, 0.0, 1.0)
	if player:
		player.volume_db = linear_to_db(volume_linear)


func get_volume_normalized():
	return volume_linear