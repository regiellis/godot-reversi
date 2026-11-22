extends Control

## The tutorial: five positions on the real board, each one solved by playing it.
##
## Reached from the title's HOW TO PLAY. Every lesson is one entry in LESSONS: a
## board written out row by row, what the player has to do, and what the card
## says before, after, and when a move misses. Adding a lesson is a dictionary.
## The rules still live only in ReversiBoard. A lesson names its goal and this
## screen asks the board which moves meet it.
##
## `layout()` derives every box, and sizes the card's text blocks from the
## longest copy any lesson can put there, so text that outgrows the card fails
## the layout check instead of running off it.

const TITLE_SCENE := "res://screens/title/title.tscn"
const SETUP_SCENE := "res://screens/setup/setup.tscn"
const RULES_SCENE := "res://screens/how_to_play/how_to_play.tscn"

## The design box. `canvas_items` stretch fits it to the player's window.
const PAGE := Vector2(2560.0, 1440.0)

enum Goal {
	ANY, ## Any legal move.
	MOST, ## The move that flips the most.
	TARGET, ## One named cell, ringed on the board.
	CORNER, ## A corner.
	SAFE, ## Any move that opens no corner for the other side.
}

## Card copy runs at FS_SMALL, as the rules cards do: at FS_BODY the longest
## lesson needs more lines than the card beside the board has room for.
const COPY_FS := Design.FS_SMALL

## The beat between the player's move and the scripted reply, long enough to
## see the first move land before the board moves again.
const T_REPLY_BEAT := 0.45

## How long a lesson holds the corner White just took before rewinding.
const T_REWIND_HOLD := 1.6

## Must match Pips.RADIUS and Pips.GAP, which layout() sizes the row from.
const PIP_RADIUS := 14.0
const PIP_GAP := Design.SPACE_SM

const NEXT_LABEL := "NEXT"
const RESET_LABEL := "RESET"
const PLAY_LABEL := "PLAY"
const RULES_LABEL := "RULES"
const BACK_LABEL := "BACK"

const FINISH_CARD := "TUTORIAL"
const FINISH_HEADING := "READY TO PLAY"
const FINISH_BODY := (
	"That is the game. Trap lines to flip them, take corners, and keep the squares "
	+ "beside an empty corner for later. PLAY starts a game against Easy, and RULES "
	+ "puts everything on one page."
)
const WRONG_SQUARE := "Only the marked cells are legal here."
const PASS_TOAST := "White passes."
const TRAP_TOAST := "White takes the corner."

## Rows run top to bottom, files left to right, the way the board is drawn.
## B is black, W is white, a dot is empty. The player is always black.
const LESSONS: Array[Dictionary] = [
	{
		"title": "PLACE AND FLIP",
		"body": "You play black, and black moves first. Place a disc so a straight line "
		+ "of white discs sits between it and a black disc already on the board. "
		+ "Hover a marked cell to see what it would flip.",
		"rows": [
			"........",
			"........",
			"........",
			"...WB...",
			"...BW...",
			"........",
			"........",
			"........",
		],
		"goal": Goal.ANY,
		"nudge": "",
		"success": "The trapped disc turned black. Trapping a line is the only way a "
		+ "disc ever changes colour.",
	},
	{
		"title": "EVERY DIRECTION",
		"body": "One move flips every line it closes at once: across, down and "
		+ "diagonally. One move here flips five discs. Find it.",
		"rows": [
			"........",
			"........",
			".......B",
			"...BB.W.",
			"...WWW..",
			".BWW....",
			"........",
			"........",
		],
		"goal": Goal.MOST,
		"nudge": "That move flips %d. One move here flips %d.",
		"success": "Three lines closed by one disc. The biggest captures come from moves "
		+ "that touch several lines.",
	},
	{
		"title": "NO MOVE, NO TURN",
		"body": "With no legal move, a player passes. The game only ends when neither "
		+ "side can move. Play the ringed move and see what White has left.",
		"rows": [
			"........",
			"........",
			"........",
			"...WWW..",
			"...WWW..",
			"...WWWWW",
			"....W...",
			"...WBBB.",
		],
		"goal": Goal.TARGET,
		"target": Vector2i(2, 7),
		"nudge": "That leaves White a reply. Try the ringed move.",
		"after_pass": "White has no move and passes. Your turn again: play any marked cell.",
		"success": "A pass is a free move. Leaving the other side nothing to play is a "
		+ "real way to win.",
	},
	{
		"title": "CORNERS STAY",
		"body": "A corner can never be flipped, because no line runs past it for a disc "
		+ "to close. One is open to you now. Take it.",
		"rows": [
			"........",
			"........",
			"...B....",
			"...BB...",
			"...BWB..",
			".....W..",
			".....WW.",
			".....W..",
		],
		"goal": Goal.CORNER,
		"nudge": "That one is legal, but the corner is the prize here.",
		"success": "White has moved, and the corner is still yours. It stays yours for "
		+ "the rest of the game.",
	},
	{
		"title": "DON'T OPEN CORNERS",
		"body": "A move beside an empty corner can hand that corner to the other side. "
		+ "Hover a move: the coach marks a corner it would give away with a red "
		+ "cross. Pick a move that keeps the corner closed.",
		"rows": [
			"........",
			"........",
			"........",
			"...WB...",
			"WWWWW...",
			"..B.BWB.",
			"......W.",
			"........",
		],
		"goal": Goal.SAFE,
		"nudge": "White took the corner that move opened. The board is back as it was: "
		+ "try another move.",
		"success": "The corner stays closed. Most of good Reversi is not giving one away.",
	},
]

@onready var _board_view: BoardView = %Board

var _board := ReversiBoard.new()
var _index := 0
var _moves: Dictionary = {}
var _warnings: Dictionary = {}
var _busy := false
var _done := false
var _finished := false
## Lesson three takes two moves: the ringed one, then any move after the pass.
var _second_move := false
var _completed := 0
var _rng := RandomNumberGenerator.new()

var _card: JuicePanel = null
var _heading: Label = null
var _body: Label = null
var _feedback: Label = null
var _pips: Pips = null
var _left: JuiceButton = null
var _mid: JuiceButton = null
var _right: JuiceButton = null


## Draws one disc per lesson, filled once that lesson is solved.
class Pips extends Control:
	const RADIUS := 14.0
	const GAP := 16.0
	const RING := 3.0

	var count := 0
	var filled := 0
	var current := 0

	func _draw() -> void:
		for i in count:
			var centre := Vector2(RADIUS + float(i) * (RADIUS * 2.0 + GAP), size.y * 0.5)
			var colour := Design.CREAM if i < filled else Design.NIGHT_LO
			draw_circle(centre, RADIUS, colour, true, -1.0, true)
			var ring := Design.GOLD if i == current else Design.INK
			draw_circle(centre, RADIUS, ring, false, RING, true)


## Builds a board from a lesson's rows.
static func board_from(rows: Array) -> ReversiBoard:
	var board := ReversiBoard.new()
	board.cells.fill(ReversiBoard.EMPTY)
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			match row[x]:
				"B":
					board.set_cell(Vector2i(x, y), ReversiBoard.BLACK)
				"W":
					board.set_cell(Vector2i(x, y), ReversiBoard.WHITE)
	return board


## Every line of copy the feedback slot can show, so layout() can size the slot
## for the longest. MOST's nudge is filled with two-digit counts, its widest form.
static func feedback_copy() -> Array[String]:
	var lines: Array[String] = [WRONG_SQUARE]
	for lesson: Dictionary in LESSONS:
		lines.append(String(lesson["success"]))
		var nudge := String(lesson["nudge"])
		if nudge.contains("%d"):
			nudge = nudge % [10, 10]
		lines.append(nudge)
		if lesson.has("after_pass"):
			lines.append(String(lesson["after_pass"]))
	return lines


## Every box on the screen, derived rather than authored. Static and free of the
## scene tree so a check can audit the numbers the screen places.
##
## The board keeps the match screen's geometry. The card fills the column to its
## right from the board frame's top edge to just above the button row, which
## sits on the frame's bottom edge. `fits` is false when the measured text needs
## more height than the card has.
static func layout() -> Dictionary:
	var frame_top := Design.BOARD_ORIGIN.y - Design.FRAME_WIDTH
	var frame_bottom := Design.BOARD_ORIGIN.y + Design.BOARD_PX + Design.FRAME_WIDTH
	var row_y := frame_bottom - Design.BUTTON_H
	var column := Design.PANEL_RECT
	var card := Rect2(
		column.position.x, frame_top, column.size.x, row_y - Design.SPACE_MD - frame_top
	)

	var probe := JuicePanel.new()
	probe.title = "LESSON %d OF %d" % [LESSONS.size(), LESSONS.size()]
	var header := probe.content_top()
	probe.free()

	var inner_x := card.position.x + Design.PAD_PANEL
	var inner_w := card.size.x - Design.PAD_PANEL * 2.0

	var heading_h := Design.text_height(FINISH_HEADING, inner_w, Design.FS_H2)
	var body_h := Design.text_height(FINISH_BODY, inner_w, COPY_FS)
	for lesson: Dictionary in LESSONS:
		heading_h = maxf(heading_h, Design.text_height(lesson["title"], inner_w, Design.FS_H2))
		body_h = maxf(body_h, Design.text_height(lesson["body"], inner_w, COPY_FS))
	var feedback_h := 0.0
	for line: String in feedback_copy():
		feedback_h = maxf(feedback_h, Design.text_height(line, inner_w, COPY_FS))

	var heading := Rect2(inner_x, card.position.y + header, inner_w, heading_h)
	var body := Rect2(inner_x, heading.end.y + Design.SPACE_SM, inner_w, body_h)
	var feedback := Rect2(inner_x, body.end.y + Design.SPACE_MD, inner_w, feedback_h)
	var pips := Rect2(
		inner_x, card.end.y - Design.PAD_PANEL - PIP_RADIUS * 2.0,
		(PIP_RADIUS * 2.0 + PIP_GAP) * float(LESSONS.size()), PIP_RADIUS * 2.0
	)

	var width := (column.size.x - Design.SPACE_SM * 2.0) / 3.0
	var buttons: Array[Rect2] = []
	for i in 3:
		buttons.append(Rect2(
			column.position.x + (width + Design.SPACE_SM) * float(i), row_y,
			width, Design.BUTTON_H
		))

	return {
		"card": card,
		"heading": heading,
		"body": body,
		"feedback": feedback,
		"pips": pips,
		"buttons": buttons,
		"fits": feedback.end.y + Design.SPACE_MD <= pips.position.y,
	}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 20261122
	var plan := layout()
	_build(plan)
	_board_view.cell_clicked.connect(_on_cell_clicked)
	_load_lesson(0)
	_card.pop_in()
	for i in 3:
		[_left, _mid, _right][i].play_intro(0.12 + float(i) * Design.T_MENU_STAGGER)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _build(plan: Dictionary) -> void:
	_card = JuicePanel.new()
	_card.name = "Card"
	_card.accent = Design.GOLD
	var card_rect: Rect2 = plan["card"]
	_card.position = card_rect.position
	_card.size = card_rect.size
	add_child(_card)

	# Siblings after the card rather than its children: the card scales from
	# nothing on entry, and text riding that scale would smear.
	_heading = _label("Heading", plan["heading"], Design.FS_H2, Design.CREAM)
	_body = _label("Body", plan["body"], COPY_FS, Design.CREAM_MUTED)
	_feedback = _label("Feedback", plan["feedback"], COPY_FS, Design.GOLD)

	_pips = Pips.new()
	_pips.name = "Pips"
	var pip_rect: Rect2 = plan["pips"]
	_pips.position = pip_rect.position
	_pips.size = pip_rect.size
	_pips.count = LESSONS.size()
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pips)

	var rects: Array = plan["buttons"]
	_left = _button("LeftButton", rects[0], RESET_LABEL)
	_mid = _button("MidButton", rects[1], NEXT_LABEL)
	_right = _button("RightButton", rects[2], BACK_LABEL)
	_left.pressed.connect(_on_left_pressed)
	_mid.pressed.connect(_on_mid_pressed)
	_right.pressed.connect(_on_back_pressed)


func _label(node_name: String, rect: Rect2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override(&"font", Design.font())
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", tint)
	label.add_theme_color_override(&"font_shadow_color", Design.INK)
	label.add_theme_constant_override(&"shadow_offset_x", Design.shadow_for(font_size))
	label.add_theme_constant_override(&"shadow_offset_y", Design.shadow_for(font_size))
	label.add_theme_constant_override(&"shadow_outline_size", 0)
	add_child(label)
	return label


func _button(node_name: String, rect: Rect2, label: String) -> JuiceButton:
	var button := JuiceButton.new()
	button.name = node_name
	button.text = label
	button.intro_style = JuiceButton.IntroStyle.RISE
	button.custom_minimum_size = rect.size
	button.position = rect.position
	button.size = rect.size
	add_child(button)
	return button


# --- Lessons ----------------------------------------------------------------


func _load_lesson(index: int) -> void:
	_index = index
	_finished = false
	_done = false
	_busy = false
	_second_move = false
	var lesson: Dictionary = LESSONS[index]
	_board = board_from(lesson["rows"])
	_board_view.set_board(_board)
	_board_view.last_move = BoardView.NO_CELL
	_card.title = "LESSON %d OF %d" % [index + 1, LESSONS.size()]
	_heading.text = String(lesson["title"])
	_body.text = String(lesson["body"])
	_say("", Design.GOLD)
	_pips.current = index
	_pips.queue_redraw()
	_left.text = RESET_LABEL
	_mid.text = NEXT_LABEL
	# Focus leaves NEXT before it goes dark: the previous lesson's NEXT press
	# left it focused, and a ring on a dead button points at nothing.
	if _mid.has_focus():
		_left.grab_focus()
	_mid.disabled = true
	_left.disabled = false
	_arm()
	if int(lesson["goal"]) == Goal.TARGET:
		_board_view.flash_hint(lesson["target"])


## Opens the board for the player's move, with the preview and the coach on.
func _arm() -> void:
	_moves = _board.valid_moves(ReversiBoard.BLACK)
	_warnings = _opened_corners()
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _moves:
		cells.append(cell)
	_board_view.hints = cells
	_board_view.preview_moves = _moves
	_board_view.preview_player = ReversiBoard.BLACK
	_board_view.corner_warnings = _warnings
	_board_view.interactive = true
	_board_view.queue_redraw()


## Same reading as the match screen's coach: corners a move makes playable for
## White that are not playable already.
func _opened_corners() -> Dictionary:
	var before := _board.valid_moves(ReversiBoard.WHITE)
	var opened := {}
	for cell: Vector2i in _moves:
		var child := _board.clone()
		child.apply_move(cell, ReversiBoard.BLACK)
		var after := child.valid_moves(ReversiBoard.WHITE)
		var given: Array[Vector2i] = []
		for corner: Vector2i in ReversiAI.CORNERS:
			if after.has(corner) and not before.has(corner):
				given.append(corner)
		if not given.is_empty():
			opened[cell] = given
	return opened


func _on_cell_clicked(cell: Vector2i) -> void:
	if _busy or _done or _finished:
		return
	if not _moves.has(cell):
		Audio.play(&"error", -4.0)
		_say(WRONG_SQUARE, Design.CYAN)
		return
	var lesson: Dictionary = LESSONS[_index]
	var goal := int(lesson["goal"])
	if _second_move:
		goal = Goal.ANY
	match goal:
		Goal.ANY:
			await _play(cell, ReversiBoard.BLACK)
			_complete()
		Goal.MOST:
			var most := 0
			for move: Vector2i in _moves:
				most = maxi(most, (_moves[move] as Array).size())
			var flips := (_moves[cell] as Array).size()
			if flips < most:
				_miss(String(lesson["nudge"]) % [flips, most])
				return
			await _play(cell, ReversiBoard.BLACK)
			_complete()
		Goal.TARGET:
			if cell != lesson["target"]:
				_miss(String(lesson["nudge"]))
				_board_view.flash_hint(lesson["target"])
				return
			await _play(cell, ReversiBoard.BLACK)
			await _white_passes(String(lesson["after_pass"]))
		Goal.CORNER:
			if not ReversiAI.CORNERS.has(cell):
				_miss(String(lesson["nudge"]))
				return
			await _play(cell, ReversiBoard.BLACK)
			await _white_replies()
			_complete()
		Goal.SAFE:
			if _warnings.has(cell):
				await _spring_trap(cell, String(lesson["nudge"]))
				return
			await _play(cell, ReversiBoard.BLACK)
			_complete()


## A legal move that misses the lesson's point is refused rather than played,
## so the position the card describes stays on the board.
func _miss(text: String) -> void:
	Audio.play(&"error", -4.0)
	_say(text, Design.CYAN)


func _play(cell: Vector2i, player: int) -> void:
	_busy = true
	_board_view.interactive = false
	var flipped := _board.apply_move(cell, player)
	_board_view.play_move(cell, player, flipped)
	await _board_view.animation_finished
	_busy = false


func _white_replies() -> void:
	_busy = true
	await get_tree().create_timer(T_REPLY_BEAT).timeout
	if not is_inside_tree():
		return
	var reply := ReversiAI.choose(
		_board, ReversiBoard.WHITE, ReversiAI.Level.NORMAL, _rng
	)
	if reply != ReversiAI.NO_MOVE:
		await _play(reply, ReversiBoard.WHITE)
	_busy = false


func _white_passes(text: String) -> void:
	_busy = true
	await get_tree().create_timer(T_REPLY_BEAT).timeout
	if not is_inside_tree():
		return
	Audio.play(&"pass")
	Juice.toast(PASS_TOAST, Design.CYAN)
	_say(text, Design.CYAN)
	_second_move = true
	_busy = false
	_arm()


## Plays the move the coach warned about, lets White take the corner it opened,
## holds long enough to see it, then puts the lesson's board back.
func _spring_trap(cell: Vector2i, text: String) -> void:
	var corner: Vector2i = (_warnings[cell] as Array)[0]
	await _play(cell, ReversiBoard.BLACK)
	_busy = true
	await get_tree().create_timer(T_REPLY_BEAT).timeout
	if not is_inside_tree():
		return
	await _play(corner, ReversiBoard.WHITE)
	Juice.toast(TRAP_TOAST, Design.RED)
	_say(text, Design.RED)
	_busy = true
	await get_tree().create_timer(T_REWIND_HOLD).timeout
	if not is_inside_tree():
		return
	_board = board_from(LESSONS[_index]["rows"])
	_board_view.set_board(_board)
	_board_view.last_move = BoardView.NO_CELL
	_busy = false
	_arm()


func _complete() -> void:
	_done = true
	_board_view.interactive = false
	_board_view.hints = []
	_board_view.preview_moves = {}
	_board_view.corner_warnings = {}
	_board_view.queue_redraw()
	_say(String(LESSONS[_index]["success"]), Design.GOLD)
	Audio.play(&"confirm", -2.0)
	_completed = maxi(_completed, _index + 1)
	_pips.filled = _completed
	_pips.queue_redraw()
	_mid.disabled = false
	_mid.grab_focus()
	if _index == LESSONS.size() - 1:
		Settings.set_value("game/tutorial_done", true)


## The last card sets out a fresh opening, the board the first real game starts on.
func _show_finish() -> void:
	_finished = true
	_board = ReversiBoard.new()
	_board_view.set_board(_board)
	_board_view.last_move = BoardView.NO_CELL
	_card.title = FINISH_CARD
	_heading.text = FINISH_HEADING
	_body.text = FINISH_BODY
	_say("", Design.GOLD)
	_pips.current = -1
	_pips.queue_redraw()
	_left.text = RULES_LABEL
	_mid.text = PLAY_LABEL
	_left.disabled = false
	_mid.disabled = false
	_mid.grab_focus()


func _say(text: String, tint: Color) -> void:
	_feedback.text = text
	_feedback.add_theme_color_override(&"font_color", tint)


# --- Buttons ----------------------------------------------------------------


func _on_left_pressed() -> void:
	if _finished:
		Stage.go(RULES_SCENE)
		return
	if _busy:
		return
	_load_lesson(_index)


func _on_mid_pressed() -> void:
	if _finished:
		# The first real game opens on Easy, which is what the last card says.
		Settings.set_value("game/difficulty", ReversiAI.Level.EASY)
		Stage.go(SETUP_SCENE)
		return
	if not _done:
		return
	if _index < LESSONS.size() - 1:
		_load_lesson(_index + 1)
	else:
		_show_finish()


func _on_back_pressed() -> void:
	Stage.go(TITLE_SCENE)
