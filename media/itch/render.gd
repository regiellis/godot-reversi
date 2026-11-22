extends SceneTree

# Renders the itch.io cover and page background from the game's own drawing code: Backdrop for
# the band field, BoardView for the board, Design for every colour and the face,
# so the store art cannot drift from the game. Each image's boxes are checked for
# overlaps and margin breaks before anything is written; a failed check writes
# nothing and exits 1.
#
# Run windowed from the sample's root (a headless run has no renderer):
#   godot --path . -s media/itch/render.gd
# It lives under media/, which carries a .gdignore, so the editor never parses it.

var out_dir := ""
var failures: Array[String] = []


class Words extends Control:
	# Each item: {kind: "rule"|"hero"|"tracked"|"plain", pos, text, size, colour, rect}
	var items: Array[Dictionary] = []

	func _draw() -> void:
		var face := Design.font()
		for item in items:
			match item["kind"]:
				"rule":
					draw_rect(item["rect"], item["colour"])
				"hero":
					var fs: int = item["size"]
					var pen: Vector2 = item["pos"] + Vector2(0.0, face.get_ascent(fs))
					var sh := Vector2.ONE * float(Design.shadow_for(fs))
					draw_string(face, pen + sh, item["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Design.INK)
					draw_string(face, pen, item["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, item["colour"])
				"tracked":
					var fs2: int = item["size"]
					var x: float = item["pos"].x
					var y: float = item["pos"].y + face.get_ascent(fs2)
					var text: String = item["text"]
					for i in text.length():
						draw_string(face, Vector2(x, y), text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, item["colour"])
						x += face.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x + item["track"]


class Fade extends Control:
	# Vertical fade from clear to NIGHT over the bottom `span` pixels.
	var span := 400.0

	func _draw() -> void:
		var top := size.y - span
		var clear := Design.NIGHT
		clear.a = 0.0
		draw_polygon(
			PackedVector2Array([Vector2(0, top), Vector2(size.x, top), Vector2(size.x, size.y), Vector2(0, size.y)]),
			PackedColorArray([clear, clear, Design.NIGHT, Design.NIGHT])
		)


static func tracked_width(text: String, fs: int, track: float) -> float:
	var face := Design.font()
	var w := 0.0
	for i in text.length():
		w += face.get_string_size(text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + track
	return w - track


static func hero_size(text: String, fs: int) -> Vector2:
	var face := Design.font()
	return Vector2(face.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, face.get_height(fs))


# A mid-game position from a fixed seed, and the last move with its flips.
func mid_game(plies: int) -> Dictionary:
	var board := ReversiBoard.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261122
	var turn := ReversiBoard.BLACK
	var last := Vector2i(-1, -1)
	var flips: Array[Vector2i] = []
	var mover := turn
	for i in plies:
		var mv := ReversiAI.choose(board, turn, ReversiAI.Level.NORMAL, rng)
		if mv != ReversiAI.NO_MOVE:
			flips = board.apply_move(mv, turn)
			last = mv
			mover = turn
		turn = ReversiBoard.opponent(turn)
	return {"board": board, "last": last, "flips": flips, "mover": mover}


# Freeze the cascade part-way: near discs finished, the next ring mid-turn,
# the outer ring still showing the old colour on its way down.
func pose_view(view: BoardView, state: Dictionary) -> void:
	view.muted = true
	view.set_board(state["board"])
	view.last_move = state["last"]
	view.interactive = false
	var mover: int = state["mover"]
	var foe := ReversiBoard.opponent(mover)
	var last: Vector2i = state["last"]
	for cell: Vector2i in state["flips"]:
		var d := maxi(absi(cell.x - last.x), absi(cell.y - last.y))
		var key := cell.y * 8 + cell.x
		if d == 1:
			view._discs[key] = {"scale_x": 1.0, "player": mover, "drop": 1.0}
		elif d == 2:
			view._discs[key] = {"scale_x": 0.38, "player": mover, "drop": 1.0}
		else:
			view._discs[key] = {"scale_x": 0.55, "player": foe, "drop": 1.0}
	view.queue_redraw()


func make_viewport(px: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	return vp


func add_backdrop(vp: SubViewport, px: Vector2i, offset: float) -> void:
	var bd := Backdrop.new()
	vp.add_child(bd)
	bd.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bd.position = Vector2.ZERO
	bd.size = Vector2(px)
	bd.set_process(false)
	bd._offset = offset
	bd.queue_redraw()


func add_board(vp: SubViewport, state: Dictionary, top_left: Vector2, scale: float) -> Rect2:
	# BoardView draws its frame from BOARD_ORIGIN - FRAME_WIDTH; place that corner.
	var holder := Node2D.new()
	var corner := Design.BOARD_ORIGIN - Vector2.ONE * Design.FRAME_WIDTH
	holder.position = top_left - corner * scale
	holder.scale = Vector2.ONE * scale
	vp.add_child(holder)
	var view := BoardView.new()
	holder.add_child(view)
	pose_view(view, state)
	var extent := (Design.BOARD_PX + Design.FRAME_WIDTH * 2.0) * scale
	return Rect2(top_left, Vector2(extent, extent))


func check(name: String, boxes: Dictionary, canvas: Vector2, margin: float) -> void:
	var keys := boxes.keys()
	for k in keys:
		var r: Rect2 = boxes[k]
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			failures.append("%s: %s has zero size" % [name, k])
		if k != "board" and (r.position.x < margin - 0.5 or r.end.x > canvas.x - margin + 0.5 or r.position.y < 0.0 or r.end.y > canvas.y):
			failures.append("%s: %s leaves the canvas margin %s" % [name, k, r])
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			var a: Rect2 = boxes[keys[i]]
			var b: Rect2 = boxes[keys[j]]
			if a.intersects(b):
				failures.append("%s: %s overlaps %s" % [name, keys[i], keys[j]])


func save(vp: SubViewport, file: String, final_size: Vector2i = Vector2i.ZERO) -> void:
	var img := vp.get_texture().get_image()
	if final_size != Vector2i.ZERO:
		img.resize(final_size.x, final_size.y, Image.INTERPOLATE_LANCZOS)
	var path := out_dir.path_join(file)
	var err := img.save_png(path)
	print("saved %s %dx%d err=%d" % [path, img.get_width(), img.get_height(), err])


# Lays out rule, wordmark, byline and an optional foot line in a column that
# starts at `x`, stacked from `y` on the Design ladder scaled by `k`.
func title_block(x: float, y: float, k: float, foot: String, foot_y: float, by_k: float = -1.0) -> Dictionary:
	if by_k < 0.0:
		by_k = k
	var words := Words.new()
	var boxes := {}
	var rule := Rect2(x, y, 240.0 * k, 12.0 * k)
	words.items.append({"kind": "rule", "rect": rule, "colour": Design.GOLD})
	boxes["rule"] = rule
	var hero_fs := int(Design.FS_HERO * k)
	var hs := hero_size("REVERSI", hero_fs)
	var hero_pos := Vector2(x, rule.end.y + Design.SPACE_MD * k)
	words.items.append({"kind": "hero", "pos": hero_pos, "text": "REVERSI", "size": hero_fs, "colour": Design.CREAM})
	boxes["wordmark"] = Rect2(hero_pos, Vector2(hs.x, Design.font().get_ascent(hero_fs)) + Vector2.ONE * Design.shadow_for(hero_fs))
	var by_fs := int(Design.FS_SMALL * by_k)
	# Bungee has no descenders, so stack off the baseline, not the line box.
	var baseline := hero_pos.y + Design.font().get_ascent(hero_fs) + Design.shadow_for(hero_fs)
	var by_pos := Vector2(x, baseline + Design.SPACE_MD * k)
	var by_text := "A SWALLOWTAIL DEMO"
	words.items.append({"kind": "tracked", "pos": by_pos, "text": by_text, "size": by_fs, "colour": Design.GOLD, "track": Design.TRACK_LABEL * by_k})
	boxes["byline"] = Rect2(by_pos, Vector2(tracked_width(by_text, by_fs, Design.TRACK_LABEL * by_k), Design.font().get_height(by_fs)))
	if foot != "":
		var fpos := Vector2(x, foot_y)
		words.items.append({"kind": "tracked", "pos": fpos, "text": foot, "size": by_fs, "colour": Design.CREAM_FAINT, "track": Design.TRACK_LABEL * k})
		boxes["foot"] = Rect2(fpos, Vector2(tracked_width(foot, by_fs, Design.TRACK_LABEL * k), Design.font().get_height(by_fs)))
	return {"words": words, "boxes": boxes}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = ProjectSettings.globalize_path(args[0] if args.size() > 0 else "res://media/itch")
	DirAccess.make_dir_recursive_absolute(out_dir)
	_render.call_deferred()


func _render() -> void:
	var state := {}
	for plies in range(16, 34):
		var cand := mid_game(plies)
		var at: Vector2i = cand["last"]
		if cand["flips"].size() >= 4 and at.y >= 1 and at.y <= 3 and at.x >= 2 and at.x <= 5:
			state = cand
			break
	if state.is_empty():
		state = mid_game(24)
	print("position: last=%s flips=%d mover=%d" % [state["last"], state["flips"].size(), state["mover"]])

	# --- Cover, drawn at 1260 x 1000 then halved to itch's 630 x 500 -----------
	var csize := Vector2i(1260, 1000)
	var cvp := make_viewport(csize)
	add_backdrop(cvp, csize, 0.0)
	var ck := 0.72
	var cm := 88.0
	var cblock := title_block(cm, 96.0, ck, "", 0.0, 1.0)
	var cboard := add_board(cvp, state, Vector2(330.0, 440.0), 0.86)
	cvp.add_child(cblock["words"])
	cblock["words"].size = Vector2(csize)
	cblock["boxes"]["board"] = cboard
	check("cover", cblock["boxes"], Vector2(csize), cm)

	# --- Page background, 2880 x 1600: three accent periods wide so it tiles on x
	var gsize := Vector2i(2880, 1600)
	var gvp := make_viewport(gsize)
	add_backdrop(gvp, gsize, 0.0)
	var fade := Fade.new()
	gvp.add_child(fade)
	fade.size = Vector2(gsize)
	fade.span = 700.0

	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw

	if not failures.is_empty():
		for f in failures:
			printerr("LAYOUT: " + f)
		quit(1)
		return
	save(cvp, "cover.png", Vector2i(630, 500))
	save(gvp, "background.png")
	quit(0)
