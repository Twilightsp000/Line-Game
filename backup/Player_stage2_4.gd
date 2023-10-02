extends TileMap


##DONT CHANGE
const main_layer = 0
const main_atlas_id = 0
var PlayerX
var click_events = []
#Input开关
var can_process_input = true


	
#点击次数计数器
var input_counter = 0 #record input triggle times
var input_stage = 1   #record current stage number


#Setting. Can Change.
#Stage 1 rounds
var N = 2 # rounds to go

#Stage 2
var click_events2 = []
var pre_pos_clicked = Vector2i(0,0)



#Tile color
var white = Vector2i(2,0)  #白色在stage 1
var black = Vector2i(0,0)  #黑色在stage 2动
var red = Vector2i(1,0)    #红色禁止通行



func _ready():

	if multiplayer.get_unique_id() == 1:
		PlayerX = 1     #玩家代号,同样也是替换棋子颜色,player1是蓝色
	else:
		PlayerX = 2     #玩player2是绿色
		
		
func _input(event):
	
	if event is InputEventMouseButton and can_process_input == true:
		########Stage 1
		
		if input_stage == 1: 
			print("stage 1")     
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
					var global_clicked = event.position
					var pos_clicked = local_to_map(to_local(global_clicked))
					
					
					var current_atlas_coords = get_cell_atlas_coords(main_layer, pos_clicked)
					var current_tile_alt = get_cell_alternative_tile(main_layer, pos_clicked)  #当前颜色代替
					#var number_of_alts_for_clicked = tile_set.get_source(main_atlas_id)\
					#						.get_alternative_tiles_count(current_atlas_coords)
					var new_tile_alt = PlayerX
					
					
					print("The pos is" + str(pos_clicked))
					print("tile_alt is" + str(current_atlas_coords))
					print(PlayerX)
					if current_atlas_coords == white:
						#如果不是服务器，发送点击位置到服务器
						can_process_input = false
						print("Input disable")
						if !multiplayer.is_server():
							print("request send to server")
							rpc_id(1, "process_click", pos_clicked, current_atlas_coords, current_tile_alt, new_tile_alt)
							print("send to server")
						if multiplayer.is_server():
							print("server runs process click")
							process_click(pos_clicked, current_atlas_coords, current_tile_alt, new_tile_alt)
		
		##################stage 2
		##################
		elif input_stage == 2:
			#print("We are in stage 2")
			##存储点击位置
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
					var global_clicked = event.position
					var pos_clicked = local_to_map(to_local(global_clicked))
					var current_atlas_coords = get_cell_atlas_coords(main_layer, pos_clicked)
					var current_tile_alt = get_cell_alternative_tile(main_layer, pos_clicked)  #变成哪个颜色
					var new_tile_alt = PlayerX
					print("The input pos is" + str(pos_clicked))
					#print("tile_alt is" + str(current_atlas_coords))
					var click_event2 = {"pos_clicked": pos_clicked,
										"current_atlas_coords": current_atlas_coords,
										"current_tile_alt": current_tile_alt,
										"new_tile_alt": new_tile_alt
										}
					
					
					
					#是否是第一次点击
					if click_events2.size() == 0:
						#是否是玩家棋子
						if current_atlas_coords == white and current_tile_alt == PlayerX:
							click_events2.append(click_event2)
							#print("before click, pre_pos_clicked is" + str(pre_pos_clicked))
							pre_pos_clicked = click_event2["pos_clicked"]
							#print("after click, pre_pos_clicked is" + str(pre_pos_clicked))
							new_tile_alt = PlayerX+2   #tilemap,white alt playerx+2为待定选项
							current_atlas_coords = white
							set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
						else:
							print("Please click your color")
					else:  #不是第一次点击
						#是否和上一次点击相连
						if if_connected(pre_pos_clicked,pos_clicked):
							#是否是黑色或者白色区域
							if (current_atlas_coords == black or current_atlas_coords == white) and current_tile_alt == 0:
								click_events2.append(click_event2)
								print("before click, pre_pos_clicked is" + str(pre_pos_clicked))
								pre_pos_clicked = click_event2["pos_clicked"]
								print("after click, pre_pos_clicked is" + str(pre_pos_clicked))
								new_tile_alt = PlayerX+2
								current_atlas_coords = white
								set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
							elif current_atlas_coords == white and current_tile_alt == PlayerX:
								click_events2.append(click_event2)
								pre_pos_clicked = click_event2["pos_clicked"]
								new_tile_alt = PlayerX+2
								current_atlas_coords = white
								set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
								can_process_input = false
								print("Input disable")
								
								if !multiplayer.is_server():
									rpc_id(1, "process_click2", click_events2,PlayerX)
									
								if multiplayer.is_server():
									process_click2(click_events2,PlayerX)
									
								
								
								
						else:
								
								print("The cell you clicked does not connect to your previous cell, pre_pos_clicked is "+str(pre_pos_clicked))
							#if current_atlas_coords == black or white:
						#	current_atlas_coords = white
						#	new_tile_alt = PlayerX+2

						#	if !multiplayer.is_server():
						#		rpc_id(1, "process_click", pos_clicked, current_atlas_coords, current_tile_alt, new_tile_alt)
						#		print("send to server")
						#	if multiplayer.is_server():
						#		process_click(pos_clicked, current_atlas_coords, current_tile_alt, new_tile_alt)


#处理 点击 for stage 1. Server only
@rpc("any_peer","call_local")
func process_click(pos_clicked, current_atlas_coords, current_tile_alt, new_tile_alt):
	
	if multiplayer.is_server():
		var click_event = {
			"pos_clicked": pos_clicked,
			"current_atlas_coords": current_atlas_coords,
			"current_tile_alt": current_tile_alt,
			"new_tile_alt": new_tile_alt
		}
		click_events.append(click_event)
		
		if click_events.size() == 2:
			can_process_input = true
			rpc("resume_input")
			print("Input enable")
			#计数器此处计数
			input_counter = input_counter+1
			if input_counter == N:
				input_stage = input_stage+1
			rpc("sync_input_stage_and_counter",input_stage,input_counter)
			
			if click_events[0]["pos_clicked"] == click_events[1]["pos_clicked"]:
				pos_clicked = click_events[0]["pos_clicked"]
				current_atlas_coords = red
				
				rpc("sync_tile_change", pos_clicked, current_atlas_coords,0)
			else:
				var myPlay = click_events[0]
				pos_clicked = myPlay["pos_clicked"]
				current_atlas_coords = myPlay["current_atlas_coords"]
				current_tile_alt = myPlay["current_tile_alt"]
				new_tile_alt = myPlay["new_tile_alt"]
				set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
				rpc("sync_tile_change", pos_clicked, current_atlas_coords, new_tile_alt)
				
				var myPlay2 = click_events[1]
				pos_clicked = myPlay2["pos_clicked"]
				current_atlas_coords = myPlay2["current_atlas_coords"]
				current_tile_alt = myPlay2["current_tile_alt"]
				new_tile_alt = myPlay2["new_tile_alt"]
				set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
				rpc("sync_tile_change", pos_clicked, current_atlas_coords, new_tile_alt)
			click_events=[]
			
		
		#set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, number_of_alts_for_clicked)
		#print("set tile in the server")
		
		#rpc("sync_tile_change", pos_clicked, current_atlas_coords, number_of_alts_for_clicked)
		#print("rpc to client")

########
########
########
######## Stage 2


####server only
var seen_pos = {}
var dup_pos = {}
var stage2events = []
var processed_players = {}

@rpc("any_peer","call_local")
func process_click2(click_events2,Playernumber):
	if multiplayer.is_server():
		if Playernumber not in processed_players:

			#####收集记录#######
			processed_players[Playernumber] = true
			var Playerevent2 = {
				"click_events2" : click_events2,
				"Playerid" : Playernumber
			}
			stage2events.append(Playerevent2)
			
			####
			####
			if stage2events.size() == 2:
				######开始process
				resume_input
				rpc("resume_input")
				print("Input enable")
				#stage2evets[i]是储存两个玩家，各自的所有点击信息。
				for i in stage2events.size():
				
					var myplayerid = stage2events[i]["Playerid"]
					if myplayerid == 1:
						#####有关player1的执行
						var myevents1 = stage2events[i]["click_events2"]
						var scoreplayer1 = myevents1.size()    ##得分在此处
						for click_event in myevents1:
						##myevents1由很多click_event组成
						# click_event成分
	#							var click_event = {
	#								"pos_clicked": pos_clicked,
						#			"current_atlas_coords": current_atlas_coords,
						#			"current_tile_alt": current_tile_alt,
						#			"new_tile_alt": new_tile_alt
	#		}
							var pos = click_event["pos_clicked"]
							
							if pos in seen_pos:
								dup_pos[pos] = true
							else:
								seen_pos[pos] = true	
							
					elif myplayerid == 2:
						var myevents2 = stage2events[i]["click_events2"]
						var scoreplayer2 = myevents2.size()
						for click_event in myevents2:
							var pos = click_event["pos_clicked"]
							
							if pos in seen_pos:
								dup_pos[pos] = true
							else:
								seen_pos[pos] = true	
								
								
				for i in dup_pos:
					rpc("sync_tile_change",i,red,0)










########判断是否相连
var even_offset = [Vector2i(0,-1),Vector2i(1,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(-1,1)]
var odd_offset  = [Vector2i(0,-1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0)] 

func if_connected(pre_pos_clicked,pos_clicked):
	if abs(pre_pos_clicked.x) % 2 == 0:  #even
		for i in even_offset:
			if pre_pos_clicked + i == pos_clicked:
				return true
		return false
	elif abs(pre_pos_clicked.x) % 2 == 1:
		for i in odd_offset:
			if pre_pos_clicked +i == pos_clicked:
				return true
		return false

################
################rpc小函数们
################
#同步tile
@rpc("any_peer","call_local")
func sync_tile_change(pos_clicked, current_atlas_coords, new_tile_alt):
	# 在这里应用从服务器接收到的改变
	set_cell(main_layer, pos_clicked, main_atlas_id, current_atlas_coords, new_tile_alt)
	print("set tile in the client")
#同步stage and counter
@rpc("any_peer","call_local")
func sync_input_stage_and_counter(new_stage,new_counter):
	input_stage = new_stage
	input_counter = new_counter
#重置input使用
@rpc("any_peer")
func resume_input():
	can_process_input = true   #print("Reset" + str(PlayerX))