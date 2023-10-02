extends TileMap

const main_layer = 0
const main_atlas_id = 0
var PlayerX
var click_events = []



#Tile color
var white = Vector2i(2,0)
var black = Vector2i(0,0)



func _ready():
	if multiplayer.get_unique_id() == 1:
		PlayerX = 1
	else:
		PlayerX = 2
		
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				var global_clicked = event.position
				var pos_clicked = local_to_map(to_local(global_clicked))
				
				
				var current_atlas_coords = get_cell_atlas_coords(main_layer, pos_clicked)
				var current_tile_alt = get_cell_alternative_tile(main_layer, pos_clicked)
				#var number_of_alts_for_clicked = tile_set.get_source(main_atlas_id)\
				#						.get_alternative_tiles_count(current_atlas_coords)
				#var number_of_alts_for_clicked = PlayerX
				
				print("The pos is" + str(pos_clicked))
				print("tile_alt is" + str(current_atlas_coords))
				print(PlayerX)
				if current_atlas_coords == white:
					#如果不是服务器，发送点击位置到服务器
					if !multiplayer.is_server():
						rpc_id(1, "process_click", pos_clicked, current_atlas_coords, current_tile_alt, PlayerX)
						print("send to server")
					if multiplayer.is_server():
						process_click(pos_clicked, current_atlas_coords, current_tile_alt, PlayerX)
#处理 点击
@rpc("any_peer","call_local")
func process_click(pos_clicked, current_atlas_coords, current_tile_alt, number_of_alts_for_clicked):
	if multiplayer.is_server():
		set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, number_of_alts_for_clicked)
		print("set tile in the server")
		
		rpc("sync_tile_change", pos_clicked, current_atlas_coords, number_of_alts_for_clicked)
		print("rpc to client")
		
@rpc("any_peer")
func sync_tile_change(pos_clicked, current_atlas_coords, new_tile_alt):
	# 在这里应用从服务器接收到的改变
	set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
	print("set tile in the client")
