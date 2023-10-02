extends Control

@export var Address = "127.0.0.1"
@export var port = 8080
var peer

# Called when the node enters the scene tree for the first time.i.e When there is new Peer 
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		hostGame()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.


# this get called on the server and clients
func peer_connected(id):
	print("Player Connected " + str(id))
	
# this get called on the server and clients
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	GameManager.Players.erase(id)
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if i.name == str(id):
			i.queue_free()
# called only from clients
func connected_to_server():
	print("connected To Sever!")
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())

# called only from clients
func connection_failed():
	print("Couldnt Connect")

#When func connected_to_server()
@rpc("any_peer")
func SendPlayerInformation(name, id):
	if !GameManager.Players.has(id):
		GameManager.Players[id] ={
			"name" : name,
			"id" : id,
			"score": 0
		}
	
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)

####Load Game here. And hide our connect menu 
@rpc("any_peer","call_local")
func StartGame():
	var scene = load("res://Main.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

#We are going to host a game. Create server and to be host
#Happen in _on_join_button_down()
func hostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)   #2 players game
	if error != OK:                  
		print("cannot host: " + error)
		return
	#Compress the pack  
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	#Client peer
	multiplayer.set_multiplayer_peer(peer) #multiplayer.set_multiplayer_peer，使多人游戏的对象之一使这个peer的信息
	print("Waiting For Players!")
	
	
func _on_host_button_down():
	hostGame()
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())
	pass # Replace with function body.


func _on_join_button_down():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)	
	pass # Replace with function body.


func _on_start_game_button_down():
	StartGame.rpc()   #rpc func StartGame for every peer
	pass # Replace with function body.
