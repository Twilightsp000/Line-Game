extends TileMap

const main_layer = 0
const main_atlas_id = 0


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				var global_clicked = event.position
				var pos_clicked = local_to_map(to_local(global_clicked))
				
				
				var current_atlas_coords = get_cell_atlas_coords(main_layer, pos_clicked)
				var current_tile_alt = get_cell_alternative_tile(main_layer, pos_clicked)
				var number_of_alts_for_clicked = tile_set.get_source(main_atlas_id)\
										.get_alternative_tiles_count(current_atlas_coords)
				print("The pos is" + str(pos_clicked))
				print("tile_alt is" + str(current_atlas_coords))
				print(number_of_alts_for_clicked)
				
				
				set_cell(main_layer,pos_clicked,main_atlas_id,current_atlas_coords,(current_tile_alt+1)%number_of_alts_for_clicked)
				
				

