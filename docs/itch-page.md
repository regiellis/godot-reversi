# itch.io page

Everything the itch.io project page needs: the theme values, the art, the embed settings and the
paste-ready copy. Not shipped with the game: this file is here so the store page lives with the
thing it describes and can be edited in review like anything else.

---

## Title and short description

```
Reversi
```

The one line under the title, 120 characters or fewer:

```
Classic Reversi, drawn entirely in code and built by AI agents driving a live Godot editor with Swallowtail.
```

That is 108 characters.

## Classification, embed, genre and tags

- **Kind of project:** HTML
- **Classification:** Game
- **Release status:** Released
- **Pricing:** No payments (free)
- **Kind of embed:** Embed in page, started automatically on page load. The game opens on its
  own title screen, so the page carries no banner and no poster to repeat the name.
- **Viewport:** 1280 x 720. The game is authored at 2560 by 1440 and scales to whatever it is
  given, so this is a frame size rather than a resolution.
- **Fullscreen button:** enabled. Worth it at this aspect ratio.
- **Mobile friendly:** off. It is a mouse and keyboard game.
- **Genre:** Strategy
- **Tags:** `board-game`, `reversi`, `othello`, `godot`, `open-source`, `source-available`, `ai`,
  `no-sprites`, `singleplayer`, `local-multiplayer`

## Theme

Set in the page's Edit theme panel. Every colour is a token from `core/design.gd`, so the page
and the game start from the same numbers.

| Slot | Value | Token |
| --- | --- | --- |
| BG | `#1b2430` | `NIGHT` |
| BG2 | `#121a24`, alpha 95% | `NIGHT_LO` |
| Text | `#f2efe6` | `CREAM` |
| Link | `#4fd6ff` | `CYAN` |
| Buttons | `#f5c242` | `GOLD` |
| Headers | `#f5c242` | `GOLD` |

- **Header font:** Bungee, the game's only face (it is on Google Fonts, which itch offers).
- **Page font:** Inter. Bungee is all caps and too heavy for paragraphs.
- **Background image:** `media/itch/background.png`, tiled horizontally, top centre. It is 2880
  pixels wide, three accent periods of the game's band field, so the bands tile without a seam,
  and it fades to `NIGHT` at the bottom so a long page ends on the BG colour.
- **Banner:** none. itch then shows the project title as text, set in the Bungee header font.
- **Screenshots:** Auto, which hides the sidebar on an embed page. The description carries the
  screenshots inline instead.

itch's docs do not say whether button text adapts to the Buttons colour. If a button label
comes out white on gold, set Buttons to the felt green `#1b5337` instead.

## Art

Both images are rendered by `media/itch/render.gd` through the game's own `Backdrop`,
`BoardView` and `Design`, so the store art cannot drift from the game. The script checks every
image's boxes for overlaps and margin breaks and writes nothing when one fails. Run it windowed
from the sample's root, since a headless run has no renderer:

```
godot --path . -s media/itch/render.gd
```

| File | Size | Use |
| --- | --- | --- |
| `cover.png` | 630 x 500 | Cover image, drawn at 1260 x 1000 and halved |
| `background.png` | 2880 x 1600 | Theme background image |

The cover holds the wordmark and byline only, at sizes that stay legible at itch's 315 x 250
listing size. Screenshots come from `media/`.

## Description

Paste in the description editor's HTML mode (the `<>` button), then stay in that mode: the rich
editor rewrites markup it does not recognise. Upload the four images through the editor's image
button first and swap each `src` for the URL itch gives it.

```html
<p><strong>Reversi on an eight by eight board.</strong> Place a disc to trap a line of your opponent's discs, and every disc you trap turns to your colour. Play the computer on Easy, Normal or Hard, or play a friend at one keyboard.</p>

<h2>How to play</h2>
<ul>
<li>Black moves first.</li>
<li>Your move has to trap at least one of your opponent's discs in a straight line, across, down or diagonally, between the disc you place and one you already have.</li>
<li>If you have no legal move, your turn passes. When neither side can move, the larger count wins.</li>
<li>A corner can never be flipped once it is taken, which makes it worth more than its one disc.</li>
</ul>
<p>Click a highlighted cell to place a disc. Hover a cell first to see which discs it would flip, and with the coach on, a red cross marks any corner the move would give away. Press HINT and the board marks the move the computer would suggest, without playing it. UNDO takes back a move against Easy or Normal. Escape opens the pause menu, and the arrow keys with Enter drive every menu.</p>
<p><img src="game.png" alt="A match in progress: the board beside a panel showing the score, the side to move and the last move"></p>
<p>New to Reversi? HOW TO PLAY on the title screen opens a five-lesson tutorial, each lesson a position you solve on the real board.</p>
<p><img src="tutorial.png" alt="Lesson two of the tutorial: one move on the board previewing five flips"></p>

<h2>Drawn in code</h2>
<p>The project contains no sprites. The board, the discs, the buttons, the sliders, the panels, the notifications and the screen transitions are drawn in code from polygons and text against a 2560 by 1440 design box, so the game stays sharp at any window size. The page background and the cover art come from the same drawing code.</p>
<p><img src="setup.png" alt="Choosing an opponent and a colour before a match"></p>
<p><img src="how-to-play.png" alt="The rules, five cards each with a small board diagram"></p>

<h2>What this is</h2>
<p>A demonstration. AI agents built the whole game by driving a live Godot editor through Swallowtail, a tool that keeps the development loop in one place: build the game, run it, play it, observe its state, debug it, fix it and verify the fix.</p>
<p>The brief came from a video demonstrating a different tool. This build answers the same brief with Swallowtail, so you can put the two results side by side and judge what each produced.</p>
<p><strong>This is not an argument for generating games from a single prompt, and it is not a case for making games at volume.</strong></p>
<p>One prompt produced the brief. Everything after it took direction. The first build looked finished and was not: every screen had spacing and overlap faults, a drop shadow made small text look doubled, and the title screen clicked at the player once a second for as long as it stayed open. A person found all of it.</p>
<p>It also worked because Reversi is a solved problem. The rules are fixed and published, the board is eight by eight, and the interface conventions are decades old. Nothing here had to be invented, prototyped, or found by playing until it felt right. A game whose mechanic has to be discovered by iterating on it is a different job, and one prompt does not touch it.</p>
<p>Swallowtail is a tool. It belongs inside a Godot workflow, next to source control, review, playtesting, and someone with the judgement to decide when the work is done.</p>

<h2>Source</h2>
<p>The project is MIT licensed: <a href="https://github.com/regiellis/godot-reversi">github.com/regiellis/godot-reversi</a>. Read it, learn from it and reuse the techniques freely. It is a teaching artifact, so it is not maintained as a game and does not take feature requests.</p>
<p>Swallowtail: <a href="https://github.com/regiellis/godot-mcp-go">repository</a> and <a href="https://regiellis.github.io/godot-mcp-go/docs">documentation</a>.</p>

<h2>Credits</h2>
<p>The people credited here are not associated with this project and have not endorsed it. Their work is used under licences that permit reuse. A CC0 release, an OFL font or an MIT kit grants permission to use the work. It says nothing about the author's view of AI tools, of AI in games, or of this demonstration.</p>
<ul>
<li>The look and feel come from the <a href="https://miisan.itch.io/godot-4-ui">Liquid UI Kit for Godot</a> by Miisan, the source of the idea of drawing every widget in _draw() so each property stays a float a tween can move. The mechanisms were re-implemented here; the thinking is theirs.</li>
<li>Sound effects by <a href="https://kenney.nl">Kenney</a>, released under CC0.</li>
<li>Type is Bungee by David Jonathan Ross, under the SIL Open Font License 1.1.</li>
<li>Built with Godot 4.7.</li>
</ul>
```

## Before the first push

`butler` needs the project to exist. Create it in itch's editor, set the kind to HTML, then take
an API key from https://itch.io/user/settings/api-keys and add it to the repository as the secret
`BUTLER_API_KEY`.

The workflow pushes to `paperenigma/reversi:html`. If the project ends up at a different URL
slug, change `ITCH_TARGET` in `.github/workflows/pages.yml` to match, or the push will fail with a
project-not-found error.
