extends Node

@onready var source_node = $'../TileMap'
@onready var my_label1: Label = $Player1Score
@onready var my_label2: Label = $Player2Score


# Called when the node enters the scene tree for the first time.
func _ready():
	source_node.connect("text_change_player1", Callable(self, "_on_text_changed_player1")) 
	source_node.connect("text_change_player2", Callable(self, "_on_text_changed_player2")) 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_text_changed_player1(new_text: String):
	my_label1.text = "Player 1 Score is " + new_text
	
func _on_text_changed_player2(new_text: String):
	my_label2.text = "Player 2 Score is " + new_text
