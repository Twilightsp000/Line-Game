extends TileMap

const main_layer = 0
const main_atlas_id = 0
var PlayerX
var click_events = []
#Input开关
var can_process_input = true
@rpc("any_peer")
func resume_input():
	can_process_input = true
	print("Reset" + str(PlayerX))


#Tile color
var white = Vector2i(2,0)  #stage 1
var black = Vector2i(0,0)  #stage 2
var red = Vector2i(1,0)    #禁止通行


func _ready():
	if multiplayer.get_unique_id() == 1:
		PlayerX = 1     #玩家代号,同样也是替换棋子颜色,player1是蓝色
	else:
		PlayerX = 2     #玩olayer2是绿色
		


		
func _input(event):
	if event is InputEventMouseButton and can_process_input == true:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				var global_clicked = event.position
				var pos_clicked = local_to_map(to_local(global_clicked))
				
				
				var current_atlas_coords = get_cell_atlas_coords(main_layer, pos_clicked)
				var current_tile_alt = get_cell_alternative_tile(main_layer, pos_clicked)
				#var number_of_alts_for_clicked = tile_set.get_source(main_atlas_id)\
				#						.get_alternative_tiles_count(current_atlas_coords)
				var number_of_alts_for_clicked = PlayerX
				
				
				print("The pos is" + str(pos_clicked))
				print("tile_alt is" + str(current_atlas_coords))
				print(PlayerX)
				if current_atlas_coords == white:
					#如果不是服务器，发送点击位置到服务器
					can_process_input = false
					if !multiplayer.is_server():
						rpc_id(1, "process_click", pos_clicked, current_atlas_coords, current_tile_alt, number_of_alts_for_clicked)
						print("send to server")
					if multiplayer.is_server():
						process_click(pos_clicked, current_atlas_coords, current_tile_alt, number_of_alts_for_clicked)
#处理 点击
@rpc("any_peer","call_local")
func process_click(pos_clicked, current_atlas_coords, current_tile_alt, number_of_alts_for_clicked):
	if multiplayer.is_server():
		var click_event = {
			"pos_clicked": pos_clicked,
			"current_atlas_coords": current_atlas_coords,
			"current_tile_alt": current_tile_alt,
			"number_of_alts_for_clicked": number_of_alts_for_clicked
		}
		click_events.append(click_event)
		
		if click_events.size() == 2:
			can_process_input = true
			rpc("resume_input")
			
			if click_events[0]["pos_clicked"] == click_events[1]["pos_clicked"]:
				pos_clicked = click_events[0]["pos_clicked"]
				current_atlas_coords = red
				
				rpc("sync_tile_change", pos_clicked, current_atlas_coords,0)
			else:
				var myPlay = click_events[0]
				pos_clicked = myPlay["pos_clicked"]
				current_atlas_coords = myPlay["current_atlas_coords"]
				current_tile_alt = myPlay["current_tile_alt"]
				number_of_alts_for_clicked = myPlay["number_of_alts_for_clicked"]
				set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, number_of_alts_for_clicked)
				rpc("sync_tile_change", pos_clicked, current_atlas_coords, number_of_alts_for_clicked)
				
				var myPlay2 = click_events[1]
				pos_clicked = myPlay2["pos_clicked"]
				current_atlas_coords = myPlay2["current_atlas_coords"]
				current_tile_alt = myPlay2["current_tile_alt"]
				number_of_alts_for_clicked = myPlay2["number_of_alts_for_clicked"]
				set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, number_of_alts_for_clicked)
				rpc("sync_tile_change", pos_clicked, current_atlas_coords, number_of_alts_for_clicked)
			
			click_events=[]
		#set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, number_of_alts_for_clicked)
		#print("set tile in the server")
		
		#rpc("sync_tile_change", pos_clicked, current_atlas_coords, number_of_alts_for_clicked)
		#print("rpc to client")
		
@rpc("any_peer","call_local")
func sync_tile_change(pos_clicked, current_atlas_coords, new_tile_alt):
	# 在这里应用从服务器接收到的改变
	set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
	print("set tile in the client")
