extends Sprite2D

const BOARD_SIZE = 8  
const CELL_WIDTH = 18
const TEXTURE = preload("uid://beyygqb7vscw8") 

const BLACK_BISHOP = preload("uid://bmmt31nb526bf")
const BLACK_KING = preload("uid://dlusf3487dr48")
const BLACK_KNIGHT = preload("uid://bftid8e6hwnna")
const BLACK_PAWN = preload("uid://cmukmd5mpbfm4")
const BLACK_QUEEN = preload("uid://bs6nmydq4udho")
const BLACK_ROOK = preload("uid://bhr8c2pb02smt")
const WHITE_BISHOP = preload("uid://dn55e0qqy2f8g")
const WHITE_KING = preload("uid://qfadvjemxfv1")
const WHITE_KNIGHT = preload("uid://ctsgdmugmedg5")
const WHITE_PAWN = preload("uid://nft2c70y5uwo")
const WHITE_QUEEN = preload("uid://oqqp46qtmwfu")
const WHITE_ROOK = preload("uid://ctq0j6xxcqikw")
const PIECE_MOVE = preload("uid://xl3na846yk7q")

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dot
@onready var turn: Node2D = $turn

var board: Array = []
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2 # Stores Vector2(row, col)

func _ready() -> void:
	board.append([4, 2, 3, 5, 6, 3, 2, 4])
	board.append([1, 1, 1, 1, 1, 1, 1, 1])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([0, 0, 0, 0, 0, 0, 0, 0])
	board.append([-1, -1, -1, -1, -1, -1, -1, -1])
	board.append([-4, -2, -3, -5, -6, -3, -2, -4])

	draw_board()

func draw_board() -> void:
	for child in pieces.get_children():
		child.queue_free()

	for row in BOARD_SIZE:
		for col in BOARD_SIZE:
			var holder = TEXTURE.instantiate() as Sprite2D
			pieces.add_child(holder)
			holder.name = "%d_%d" % [row, col]
			
			holder.global_position = Vector2(col * CELL_WIDTH + (CELL_WIDTH / 2.0), -row * CELL_WIDTH - (CELL_WIDTH / 2.0))
			
			match board[row][col]:
				-6: holder.texture = BLACK_KING
				-5: holder.texture = BLACK_QUEEN
				-4: holder.texture = BLACK_ROOK
				-3: holder.texture = BLACK_BISHOP
				-2: holder.texture = BLACK_KNIGHT
				-1: holder.texture = BLACK_PAWN
				0: holder.texture = null
				6: holder.texture = WHITE_KING
				5: holder.texture = WHITE_QUEEN
				4: holder.texture = WHITE_ROOK
				3: holder.texture = WHITE_BISHOP
				2: holder.texture = WHITE_KNIGHT
				1: holder.texture = WHITE_PAWN

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out_of_bound(): return
			
			# Map global mouse click directly to grid row & col
			var col = int(get_global_mouse_position().x / CELL_WIDTH)
			var row = int(abs(get_global_mouse_position().y / CELL_WIDTH))
			
			if !state and (white and board[row][col] > 0 || !white and board[row][col] < 0):
				selected_piece = Vector2(row, col)
				show_option()
				state = true

func show_option() -> void:
	moves = get_moves()
	if moves == []:
		state = false
		return
	show_dots()

func show_dots():
	# Clear old move indicator dots before drawing new ones
	for child in dots.get_children():
		child.queue_free()

	for move_pos in moves:
		var holder = TEXTURE.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		# move_pos.x = row, move_pos.y = col
		holder.global_position = Vector2(move_pos.y * CELL_WIDTH + (CELL_WIDTH / 2.0), -move_pos.x * CELL_WIDTH - (CELL_WIDTH / 2.0))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()


func get_moves():
	var _moves = []
	match abs(board[int(selected_piece.x)][int(selected_piece.y)]):
		1: _moves = get_pawns_moves()
		2: _moves = get_knight_moves()
		3: _moves = get_bishop_moves()
		4: _moves = get_rook_moves()
		5: _moves = get_queen_moves()
		6: _moves = get_king_moves()
		
	return _moves

func get_rook_moves():
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	
	for d in directions:
		var pos = selected_piece + d
		while is_valid_position(pos):
			if is_empty(pos): 
				_moves.append(pos)
			elif is_opponent(pos):
				_moves.append(pos)
				break
			else: 
				break
			pos += d
		
	return _moves

func get_queen_moves():
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for d in directions:
		var pos = selected_piece + d
		while is_valid_position(pos):
			if is_empty(pos): 
				_moves.append(pos)
			elif is_opponent(pos):
				_moves.append(pos)
				break
			else: 
				break
			pos += d
		
	return _moves

func get_king_moves():
	var _moves = []
	var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
	Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for d in directions:
		var pos = selected_piece + d
		if is_valid_position(pos):
			if is_empty(pos): 
				_moves.append(pos)
			elif is_opponent(pos):
				_moves.append(pos)
				
	return _moves
	
func get_bishop_moves():
	var _moves = []
	# Diagonal offsets: (row_step, col_step)
	var directions = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	
	for d in directions:
		var pos = selected_piece + d
		while is_valid_position(pos):
			if is_empty(pos): 
				_moves.append(pos)
			elif is_opponent(pos):
				_moves.append(pos)
				break
			else: 
				break
			pos += d
		
	return _moves

func get_knight_moves():
	var _moves = []
	# Diagonal offsets: (row_step, col_step)
	var directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]

	for d in directions:
		var pos = selected_piece + d
		if is_valid_position(pos):
			if is_empty(pos): 
				_moves.append(pos)
			elif is_opponent(pos):
				_moves.append(pos)
		
	return _moves


func get_pawns_moves():
	var _moves = []
	var direction
	var is_frist_move = false
	
	if white: direction = Vector2(1, 0)
	else: direction = Vector2(-1, 0)
	
	if white and selected_piece.x == 1 || !white and selected_piece.x == 6:
		is_frist_move = true
		
	var pos = selected_piece + direction
	if is_empty(pos): _moves.append(pos)
	
	pos = selected_piece + Vector2(direction.x, 1)
	if is_valid_position(pos):
		if is_opponent(pos):
			_moves.append(pos)
	
	pos = selected_piece + Vector2(direction.x, -1)
	if is_valid_position(pos):
		if is_opponent(pos): _moves.append(pos)
	
	pos = selected_piece + direction * 2
	if is_frist_move and is_empty(pos) and is_empty(selected_piece + direction): _moves.append(pos)
	
	return _moves

func is_valid_position(pos : Vector2):
	return pos.x >= 0 and pos.x < BOARD_SIZE and pos.y >= 0 and pos.y < BOARD_SIZE

func is_empty(pos : Vector2):
	return board[int(pos.x)][int(pos.y)] == 0

func is_opponent(pos: Vector2):
	var piece_val = board[int(pos.x)][int(pos.y)]
	return (white and piece_val < 0) or (!white and piece_val > 0)

func is_mouse_out_of_bound() -> bool:
	var pos = get_global_mouse_position()
	return pos.x < 0 or pos.x >= (BOARD_SIZE * CELL_WIDTH) or pos.y > 0 or pos.y <= -(BOARD_SIZE * CELL_WIDTH)
