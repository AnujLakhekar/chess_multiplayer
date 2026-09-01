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

const TURN_BLACK = preload("uid://b31753kfiwd4e")
const TURN_WHITE = preload("uid://1yk2d68ckgwk")

@onready var promotion_bg: ColorRect = $"../GameCanvas/promotion_bg"
@onready var white_promotion: Control = $"../GameCanvas/white_promotion"
@onready var black_promotion: Control = $"../GameCanvas/black_promotion"
@onready var check: Node2D = $check

@onready var game_complete: Control = $"../GameCanvas/game_complete"
@onready var winner_bg: ColorRect = $"../GameCanvas/game_complete/winnerBg"
@onready var winner: Label = $"../GameCanvas/game_complete/Winner"
@onready var winner_name: Label = $"../GameCanvas/game_complete/Winner_Name"
@onready var button: Button = $"../GameCanvas/game_complete/Button"

@onready var pieces: Node2D = $pieces
@onready var dots: Node2D = $dot
@onready var turn: Node2D = $turn

var board: Array = []
var white : bool = true
var state : bool = false
var moves = []
var selected_piece : Vector2 
var promotion_square = null

var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var en_passent = null

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
	
	var white_pieces = get_tree().get_nodes_in_group("white")
	var black_pieces = get_tree().get_nodes_in_group("black")
	
	for btn in white_pieces:
		btn.pressed.connect(on_btn_pressed.bind(btn))
	
	for btn in black_pieces:
		btn.pressed.connect(on_btn_pressed.bind(btn))

func on_btn_pressed(btn):
	var num_char = int(btn.name.substr(0, 1))
	board[promotion_square.x][promotion_square.y] = -num_char if white else num_char
	white_promotion.visible = false
	black_promotion.visible = false
	promotion_bg.visible = false
	promotion_square = null
	
	play(AudioPlayer.PLAYS.PROMOTE)
	
	draw_board()
	check_game_over()

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
	
	if white: turn.texture = TURN_WHITE
	else: turn.texture = TURN_BLACK

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and promotion_square == null:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_mouse_out_of_bound(): return
			
			var col = int(get_global_mouse_position().x / CELL_WIDTH)
			var row = int(abs(get_global_mouse_position().y / CELL_WIDTH))
			
			if !state and (white and board[row][col] > 0 || !white and board[row][col] < 0):
				selected_piece = Vector2(row, col)
				show_option()
				state = true
			elif state:
				set_move(col, row)

func show_option() -> void:
	moves = get_moves()
	if moves == []:
		state = false
		return
	show_dots()

func show_dots():
	play(AudioPlayer.PLAYS.DOT)
	for child in dots.get_children():
		child.queue_free()

	for move_pos in moves:
		var holder = TEXTURE.instantiate()
		dots.add_child(holder)
		holder.texture = PIECE_MOVE
		holder.global_position = Vector2(move_pos.y * CELL_WIDTH + (CELL_WIDTH / 2.0), -move_pos.x * CELL_WIDTH - (CELL_WIDTH / 2.0))

func delete_dots():
	for child in dots.get_children():
		child.queue_free()

func set_move(var1, var2):
	var end_pos = Vector2(var2, var1)
	var double_pawn_step = false
	var is_castling = false
	var is_capture = false
	
	for i in moves:
		if i.x == var2 and i.y == var1:
			var moved_piece = board[int(selected_piece.x)][int(selected_piece.y)]
			
			if board[var2][var1] != 0:
				is_capture = true
			
			match moved_piece:
				6: 
					if selected_piece.x == 0 and selected_piece.y == 4:
						white_king = true
						if end_pos.y == 2:
							white_rook_left = true; white_rook_right = true
							board[0][0] = 0; board[0][3] = 4
							is_castling = true
						elif end_pos.y == 6:
							white_rook_left = true; white_rook_right = true
							board[0][7] = 0; board[0][5] = 4
							is_castling = true
				-6: 
					if selected_piece.x == 7 and selected_piece.y == 4:
						black_king = true
						if end_pos.y == 2:
							black_rook_left = true; black_rook_right = true
							board[7][0] = 0; board[7][3] = -4
							is_castling = true
						elif end_pos.y == 6:
							black_rook_left = true; black_rook_right = true
							board[7][7] = 0; board[7][5] = -4
							is_castling = true
				4: 
					if int(selected_piece.x) == 0 and int(selected_piece.y) == 0: white_rook_left = true
					elif int(selected_piece.x) == 0 and int(selected_piece.y) == 7: white_rook_right = true
				-4:
					if int(selected_piece.x) == 7 and int(selected_piece.y) == 0: black_rook_left = true
					elif int(selected_piece.x) == 7 and int(selected_piece.y) == 7: black_rook_right = true

			if abs(moved_piece) == 1 and en_passent != null:
				var ep_target = en_passent + (Vector2(1, 0) if white else Vector2(-1, 0))
				if end_pos == ep_target:
					board[int(en_passent.x)][int(en_passent.y)] = 0
					is_capture = true

			if moved_piece == 1 and selected_piece.x == 1 and var2 == 3:
				en_passent = Vector2(var2, var1)
				double_pawn_step = true
			elif moved_piece == -1 and selected_piece.x == 6 and var2 == 4:
				en_passent = Vector2(var2, var1)
				double_pawn_step = true

			if !double_pawn_step:
				en_passent = null

			board[var2][var1] = moved_piece
			board[int(selected_piece.x)][int(selected_piece.y)] = 0
			
			if is_castling:
				play(AudioPlayer.PLAYS.CASTLE)
			elif is_capture:
				play(AudioPlayer.PLAYS.CAPTURE)
			else:
				play(AudioPlayer.PLAYS.MOVE)

			if moved_piece == 1 and var2 == 7:
				promote(Vector2(var2, var1))
			elif moved_piece == -1 and var2 == 0:
				promote(Vector2(var2, var1))

			white = !white
			draw_board()
			check_game_over()
			break

	delete_dots()
	state = false

func get_moves() -> Array:
	var piece_val = board[int(selected_piece.x)][int(selected_piece.y)]
	var is_piece_white = piece_val > 0
	
	var raw_moves = []
	match abs(piece_val):
		1: raw_moves = get_pawns_moves()
		2: raw_moves = get_knight_moves()
		3: raw_moves = get_bishop_moves()
		4: raw_moves = get_rook_moves()
		5: raw_moves = get_queen_moves()
		6: raw_moves = get_king_moves()
		
	var legal_moves = []
	
	for target in raw_moves:
		var orig_source_val = board[int(selected_piece.x)][int(selected_piece.y)]
		var orig_target_val = board[int(target.x)][int(target.y)]
		
		board[int(target.x)][int(target.y)] = orig_source_val
		board[int(selected_piece.x)][int(selected_piece.y)] = 0
		
		# Validate check status using the color of the piece making the move
		if !is_in_check(is_piece_white):
			legal_moves.append(target)
			
		board[int(selected_piece.x)][int(selected_piece.y)] = orig_source_val
		board[int(target.x)][int(target.y)] = orig_target_val
		
	return legal_moves

func promote(i):
	promotion_square = i
	white_promotion.visible = white
	black_promotion.visible = !white
	promotion_bg.visible = true

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
			if is_empty(pos) or is_opponent(pos): 
				_moves.append(pos)
			
	if !is_in_check(white):
		if white and !white_king:
			if !white_rook_left and is_empty(Vector2(0, 1)) and is_empty(Vector2(0, 2)) and is_empty(Vector2(0, 3)):
				if !is_square_attacked(Vector2(0, 3), true) and !is_square_attacked(Vector2(0, 2), true):
					_moves.append(Vector2(0, 2))
			if !white_rook_right and is_empty(Vector2(0, 5)) and is_empty(Vector2(0, 6)):
				if !is_square_attacked(Vector2(0, 5), true) and !is_square_attacked(Vector2(0, 6), true):
					_moves.append(Vector2(0, 6))
		elif !white and !black_king:
			if !black_rook_left and is_empty(Vector2(7, 1)) and is_empty(Vector2(7, 2)) and is_empty(Vector2(7, 3)):
				if !is_square_attacked(Vector2(7, 3), false) and !is_square_attacked(Vector2(7, 2), false):
					_moves.append(Vector2(7, 2))
			if !black_rook_right and is_empty(Vector2(7, 5)) and is_empty(Vector2(7, 6)):
				if !is_square_attacked(Vector2(7, 5), false) and !is_square_attacked(Vector2(7, 6), false):
					_moves.append(Vector2(7, 6))
			
	return _moves

func get_bishop_moves():
	var _moves = []
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
	var directions = [Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
	Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)]

	for d in directions:
		var pos = selected_piece + d
		if is_valid_position(pos):
			if is_empty(pos) or is_opponent(pos): 
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
	
	if en_passent != null and (white and selected_piece.x == 4 || !white and selected_piece.x == 3) and abs(en_passent.y - selected_piece.y) == 1:
		_moves.append(en_passent + direction)
		
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

# Check if target square is attacked by an opponent of 'is_white_turn'
func is_square_attacked(pos: Vector2, is_white_turn: bool) -> bool:
	# Correct Pawn Attack Logic:
	# A White king (row r) is attacked by a Black pawn from (r + 1)
	# A Black king (row r) is attacked by a White pawn from (r - 1)
	var attacker_row_offset = 1 if is_white_turn else -1
	var pawn_attacks = [
		Vector2(pos.x + attacker_row_offset, pos.y + 1),
		Vector2(pos.x + attacker_row_offset, pos.y - 1)
	]
	for p in pawn_attacks:
		if is_valid_position(p):
			var piece = board[int(p.x)][int(p.y)]
			if (is_white_turn and piece == -1) or (!is_white_turn and piece == 1):
				return true

	var knight_offsets = [
		Vector2(2, 1), Vector2(2, -1), Vector2(1, 2), Vector2(1, -2),
		Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)
	]
	for offset in knight_offsets:
		var p = pos + offset
		if is_valid_position(p):
			var piece = board[int(p.x)][int(p.y)]
			if (is_white_turn and piece == -2) or (!is_white_turn and piece == 2):
				return true

	var king_offsets = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	for offset in king_offsets:
		var p = pos + offset
		if is_valid_position(p):
			var piece = board[int(p.x)][int(p.y)]
			if (is_white_turn and piece == -6) or (!is_white_turn and piece == 6):
				return true

	var straight_dirs = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
	for d in straight_dirs:
		var p = pos + d
		while is_valid_position(p):
			var piece = board[int(p.x)][int(p.y)]
			if piece != 0:
				if is_white_turn:
					if piece == -4 or piece == -5: return true
				else:
					if piece == 4 or piece == 5: return true
				break
			p += d

	var diag_dirs = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]
	for d in diag_dirs:
		var p = pos + d
		while is_valid_position(p):
			var piece = board[int(p.x)][int(p.y)]
			if piece != 0:
				if is_white_turn:
					if piece == -3 or piece == -5: return true
				else:
					if piece == 3 or piece == 5: return true
				break
			p += d

	return false

# Find king location and determine if under attack
func is_in_check(is_white_turn: bool) -> bool:
	var target_king = 6 if is_white_turn else -6
	var king_pos = Vector2(-1, -1)
	
	for r in BOARD_SIZE:
		for c in BOARD_SIZE:
			if board[r][c] == target_king:
				king_pos = Vector2(r, c)
				break
		if king_pos != Vector2(-1, -1):
			break
			
	if king_pos == Vector2(-1, -1):
		return false
		
	return is_square_attacked(king_pos, is_white_turn)

# Checks if active player has any legal moves available
func has_any_legal_moves() -> bool:
	var original_selected = selected_piece
	
	for r in BOARD_SIZE:
		for c in BOARD_SIZE:
			var piece = board[r][c]
			if (white and piece > 0) or (!white and piece < 0):
				selected_piece = Vector2(r, c)
				if get_moves().size() > 0:
					selected_piece = original_selected
					return true
					
	selected_piece = original_selected
	return false

# Checks if remaining material is insufficient for checkmate
func is_insufficient_material() -> bool:
	var pieces_on_board = []
	for r in BOARD_SIZE:
		for c in BOARD_SIZE:
			if board[r][c] != 0:
				pieces_on_board.append(abs(board[r][c]))
				
	if pieces_on_board.size() == 2:
		return true
		
	if pieces_on_board.size() == 3:
		if 2 in pieces_on_board or 3 in pieces_on_board:
			return true
			
	return false

# Evaluates checkmate, stalemate, draw, or check state
func check_game_over() -> void:
	if promotion_square != null:
		return
		
	var in_check = is_in_check(white)
	var moves_available = has_any_legal_moves()
	
	if !moves_available:
		if in_check:
			var winner_var = "Black" if white else "White"
			winner_name.text = winner_var
			game_complete.visible = true
			play(AudioPlayer.PLAYS.NOTIFY)
		else:
			print("STALEMATE! Game is a draw.")
			play(AudioPlayer.PLAYS.NOTIFY)
	elif is_insufficient_material():
		print("DRAW! Insufficient material.")
		play(AudioPlayer.PLAYS.NOTIFY)
	elif in_check:
		print("CHECK!")
		play(AudioPlayer.PLAYS.NOTIFY)

func play(target : AudioPlayer.PLAYS):
	GameEvents.audio_player_play.emit(target)
