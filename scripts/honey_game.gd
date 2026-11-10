class_name HoneyGame
extends RefCounted
## Honey Churros — fixed-step run-and-gun simulation (GDScript port of web/game.js).
## Pure game logic: no drawing or audio. The renderer reads state and the game reports
## sounds/voice lines through the `sound` and `voice` callables.
## Field, method and constant names match web/game.js so both builds behave identically.
## Only deviation: JS `call(text, sub, voice)` is `callOut` here (Object.call is reserved).

const W := 1280
const H := 720
const FLOOR := 576
const ENTRY_X := 180

const DIFFICULTY := {
	"easy": {"label": "쉬움", "hp": 7, "lives": 5, "enemyHp": .75, "fire": 1.4, "bullet": .82, "score": .8},
	"normal": {"label": "보통", "hp": 5, "lives": 3, "enemyHp": 1.0, "fire": 1.0, "bullet": 1.0, "score": 1.0},
	"hard": {"label": "어려움", "hp": 3, "lives": 3, "enemyHp": 1.3, "fire": .72, "bullet": 1.18, "score": 1.5}}

const WEAPONS := [
	{"name": "AKM", "letter": "A", "call": "A K M!", "label": "돌격소총", "rate": .13, "damage": 2.2, "speed": 1050, "ammo": 150, "spread": .035, "color": "#ffc45c"},
	{"name": "Kar98k", "letter": "K", "call": "Kar ninety-eight K!", "label": "저격소총", "rate": .6, "damage": 12, "speed": 1700, "ammo": 30, "spread": 0, "color": "#e6f7dd"},
	{"name": "M4", "letter": "M", "call": "M four!", "label": "카빈 소총", "rate": .075, "damage": 2, "speed": 1250, "ammo": 200, "spread": .045, "color": "#b5e3cf"},
	{"name": "RPG-26", "letter": "R", "call": "R P G twenty-six!", "label": "로켓 런처", "rate": .55, "damage": 14, "speed": 700, "ammo": 20, "spread": 0, "color": "#ff966f"},
	{"name": "FMG-9", "letter": "S", "call": "F M G nine!", "label": "기관단총", "rate": .055, "damage": 1.2, "speed": 950, "ammo": 250, "spread": .09, "color": "#f4a9c8"},
	{"name": "Glock 19", "letter": "P", "call": "", "label": "권총", "rate": .2, "damage": 2, "speed": 1000, "ammo": -1, "spread": 0, "color": "#fbdfa5"}]
const PISTOL := 5
# Weapons unlock as the campaign goes on: each mission adds its guns to the drop pool (AKM+FMG-9, then M4, Kar98k, RPG-26).
const WEAPON_UNLOCK := [[0, 4], [2], [1], [3]]

const VISUALS := [
	{"width": 88, "ratio": .40, "grip": .36, "recoil": 4, "flash": 18, "kind": "akm", "sound": "akm"},
	{"width": 108, "ratio": .26, "grip": .33, "recoil": 9, "flash": 31, "kind": "sniper", "sound": "sniper"},
	{"width": 90, "ratio": .40, "grip": .35, "recoil": 3, "flash": 15, "kind": "m4", "sound": "m4"},
	{"width": 104, "ratio": .37, "grip": .47, "recoil": 12, "flash": 34, "kind": "rocket", "sound": "rocket"},
	{"width": 62, "ratio": .66, "grip": .43, "recoil": 2, "flash": 11, "kind": "smg", "sound": "smg"},
	{"width": 43, "ratio": .68, "grip": .28, "recoil": 5, "flash": 13, "kind": "pistol", "sound": "pistol"}]

# Enemy archetypes. All use the gwamegi sheet; the renderer adds gear per kind.
const ENEMIES := {
	"grunt": {"name": "소총병", "hp": 5, "size": 92, "speed": 70, "score": 100},
	"hopper": {"name": "돌격병", "hp": 4, "size": 82, "speed": 170, "score": 100},
	"flyer": {"name": "프로펠러병", "hp": 4, "size": 84, "speed": 95, "score": 200},
	"shield": {"name": "방패병", "hp": 10, "size": 100, "speed": 42, "score": 300},
	"bomber": {"name": "꿀단지 투척병", "hp": 5, "size": 92, "speed": 60, "score": 200},
	"heavy": {"name": "중화기병", "hp": 14, "size": 112, "speed": 34, "score": 400},
	"turret": {"name": "꿀 포대", "hp": 34, "size": 120, "speed": 0, "score": 800}}

# Hand-placed level data. x positions are relative to the zone start.
# waves: [at, kind, count, entry]  entry R=right edge, L=left edge (ambush), P=parachute
# arena: list of waves fought with the camera locked at the end of the zone.
const LEVELS := [
	{"theme": "town", "boss": "king", "par": 400, "zones": [
		{"name": "꽃길 입구", "len": 1400, "plat": [[320, 446, 190], [660, 400, 170]], "props": [["crate", 560], ["barrel", 985]], "pows": [["cage", 780, "weapon", 0]],
			"waves": [[150, "grunt", 2, "R"], [430, "grunt", 1, "T"], [650, "hopper", 2, "R"], [900, "flyer", 2, "R"]],
			"arena": [[["grunt", 2, "R"], ["bomber", 1, "R"]], [["hopper", 2, "L"], ["grunt", 2, "P"]]]},
		{"name": "방송 장비 거리", "len": 1500, "plat": [[260, 446, 200], [560, 396, 180], [900, 446, 200]], "props": [["barrel", 420], ["crate", 760], ["barrel", 1110]], "pows": [["cage", 640, "ammo"], ["cage", 1010, "food"]],
			"waves": [[100, "grunt", 2, "R"], [300, "shield", 1, "R"], [350, "grunt", 1, "T"], [600, "bomber", 1, "R"], [800, "flyer", 2, "R"], [1000, "hopper", 2, "L"]],
			"arena": [[["shield", 1, "R"], ["grunt", 2, "R"]], [["bomber", 1, "T"], ["grunt", 2, "P"]]]},
		{"name": "꽃시장 골목", "len": 1400, "plat": [[240, 446, 180], [520, 400, 160], [820, 446, 200], [1080, 396, 160]], "props": [["crate", 380], ["barrel", 700], ["crate", 1000]], "pows": [["cage", 900, "weapon", 4]],
			"waves": [[120, "grunt", 2, "R"], [260, "hopper", 2, "R"], [400, "grunt", 1, "T"], [600, "flyer", 2, "R"], [850, "shield", 1, "R"], [1000, "grunt", 2, "P"]],
			"arena": [[["grunt", 2, "R"], ["hopper", 2, "L"]], [["shield", 1, "R"], ["bomber", 1, "T"]]]},
		{"name": "양봉장 언덕", "len": 1300, "plat": [[300, 430, 200], [620, 380, 180], [940, 430, 180]], "props": [["barrel", 480], ["crate", 800]], "pows": [["cage", 560, "food"], ["cage", 1080, "ammo"]],
			"waves": [[100, "flyer", 2, "R"], [300, "grunt", 2, "R"], [450, "bomber", 1, "T"], [700, "heavy", 1, "R"], [900, "hopper", 2, "L"]],
			"arena": [[["heavy", 1, "R"], ["grunt", 1, "T"]], [["flyer", 2, "R"], ["grunt", 2, "P"]]]},
		{"name": "송신탑 광장", "len": 1400, "plat": [[300, 420, 220], [700, 380, 200]], "props": [["crate", 500], ["barrel", 860]], "pows": [["cage", 820, "support"]],
			"waves": [[150, "grunt", 2, "R"], [300, "grunt", 1, "T"], [450, "flyer", 2, "R"], [650, "heavy", 1, "R"], [700, "grunt", 1, "R"], [900, "grunt", 2, "P"]],
			"arena": [[["heavy", 1, "R"], ["grunt", 2, "L"]], [["hopper", 2, "R"], ["flyer", 2, "R"]]]}]},
	{"theme": "factory", "boss": "cannon", "par": 450, "zones": [
		{"name": "꿀 운송장", "len": 1300, "plat": [[280, 446, 180], [600, 564, 310, "belt"]], "hazards": [["honey", 470, 100]], "props": [["crate", 380], ["barrel", 980]], "pows": [["cage", 720, "weapon", 2]],
			"waves": [[120, "grunt", 2, "R"], [300, "grunt", 1, "T"], [450, "bomber", 1, "R"], [650, "hopper", 2, "R"], [900, "grunt", 2, "P"]],
			"arena": [[["grunt", 2, "R"], ["hopper", 2, "L"]], [["bomber", 1, "R"], ["grunt", 1, "T"]]]},
		{"name": "컨베이어 홀", "len": 1400, "plat": [[200, 564, 360, "belt"], [640, 420, 180], [900, 564, 300, "belt"]], "hazards": [["honey", 580, 90]], "props": [["barrel", 860], ["crate", 1180]], "pows": [["cage", 700, "weapon", 0], ["cage", 1150, "ammo"]],
			"waves": [[100, "flyer", 2, "R"], [350, "shield", 1, "R"], [400, "grunt", 1, "R"], [550, "grunt", 1, "T"], [650, "grunt", 2, "L"], [850, "bomber", 1, "R"]], "turrets": [1240],
			"arena": [[["shield", 1, "R"], ["grunt", 2, "P"]], [["flyer", 2, "R"], ["hopper", 2, "L"]]]},
		{"name": "꿀단지 창고", "len": 1400, "plat": [[220, 446, 180], [520, 564, 280, "belt"], [880, 420, 200]], "hazards": [["honey", 820, 90]], "props": [["crate", 300], ["barrel", 440], ["crate", 1150]], "pows": [["cage", 1000, "weapon", 2]],
			"waves": [[120, "grunt", 2, "R"], [300, "bomber", 1, "R"], [450, "grunt", 1, "T"], [700, "shield", 1, "R"], [900, "hopper", 2, "L"], [1050, "flyer", 2, "R"]],
			"arena": [[["bomber", 1, "R"], ["grunt", 2, "R"]], [["shield", 1, "R"], ["hopper", 2, "L"], ["grunt", 1, "T"]]]},
		{"name": "벌집 정제실", "len": 1300, "plat": [[260, 430, 200], [560, 380, 180], [860, 430, 200]], "hazards": [["honey", 420, 110], ["honey", 740, 90]], "props": [["barrel", 330], ["crate", 950]], "pows": [["cage", 600, "support"]],
			"waves": [[150, "heavy", 1, "R"], [200, "grunt", 1, "T"], [400, "flyer", 2, "R"], [700, "grunt", 2, "P"], [750, "bomber", 1, "T"]],
			"arena": [[["heavy", 1, "R"], ["bomber", 1, "R"]], [["grunt", 2, "L"], ["hopper", 2, "R"], ["grunt", 1, "T"]]]},
		{"name": "로열젤리 실험실", "len": 1300, "plat": [[260, 430, 180], [560, 380, 200], [880, 430, 180]], "hazards": [["honey", 450, 100], ["honey", 780, 90]], "props": [["barrel", 360], ["crate", 1000]], "pows": [["cage", 680, "ammo"]],
			"waves": [[100, "heavy", 1, "R"], [250, "grunt", 1, "T"], [500, "flyer", 2, "R"], [750, "grunt", 2, "P"], [900, "bomber", 1, "R"]], "turrets": [1180],
			"arena": [[["heavy", 1, "R"], ["grunt", 2, "L"]], [["bomber", 1, "T"], ["flyer", 2, "R"]]]},
		{"name": "저장고 관제실", "len": 1300, "plat": [[300, 446, 200], [700, 396, 200]], "props": [["crate", 500], ["barrel", 640], ["barrel", 1000]], "pows": [["cage", 850, "food"]],
			"waves": [[100, "grunt", 2, "R"], [350, "shield", 1, "R"], [400, "grunt", 1, "T"], [700, "flyer", 2, "R"], [750, "bomber", 1, "R"]], "turrets": [1100],
			"arena": [[["shield", 1, "R"], ["bomber", 1, "R"], ["grunt", 1, "T"]], [["heavy", 1, "R"], ["grunt", 2, "P"]]]}]},
	{"theme": "harbor", "boss": "boat", "par": 430, "zones": [
		{"name": "해변 초소", "len": 1400, "plat": [[300, 446, 190], [840, 531, 160, "boat", 180]], "hazards": [["water", 640, 560]], "props": [["crate", 520], ["barrel", 1260]], "pows": [["cage", 600, "weapon", 4]],
			"waves": [[150, "grunt", 2, "R"], [300, "grunt", 1, "T"], [450, "flyer", 2, "R"], [850, "hopper", 2, "R"], [1050, "grunt", 2, "P"]],
			"arena": [[["grunt", 2, "R"], ["bomber", 1, "R"]], [["hopper", 2, "L"], ["flyer", 1, "R"]]]},
		{"name": "수산물 시장", "len": 1400, "plat": [[260, 446, 180], [560, 400, 160], [880, 446, 200]], "props": [["crate", 400], ["barrel", 740], ["crate", 1180]], "pows": [["cage", 980, "weapon", 0]],
			"waves": [[120, "grunt", 2, "R"], [280, "shield", 1, "R"], [420, "grunt", 1, "T"], [650, "flyer", 2, "R"], [850, "bomber", 1, "R"], [1050, "hopper", 2, "L"]], "turrets": [1250],
			"arena": [[["shield", 1, "R"], ["grunt", 2, "P"]], [["bomber", 1, "R"], ["hopper", 2, "L"]]]},
		{"name": "부두 창고", "len": 1500, "plat": [[220, 420, 200], [660, 531, 160, "boat", 170], [1030, 400, 200]], "hazards": [["water", 470, 540]], "props": [["crate", 300], ["crate", 1060], ["barrel", 1300]], "pows": [["cage", 1120, "weapon", 1], ["cage", 1380, "ammo"]],
			"waves": [[100, "shield", 1, "R"], [150, "grunt", 1, "R"], [400, "flyer", 3, "R"], [700, "bomber", 1, "R"], [750, "grunt", 1, "T"], [1000, "grunt", 2, "L"]], "turrets": [1300],
			"arena": [[["shield", 1, "R"], ["grunt", 2, "P"]], [["heavy", 1, "R"], ["hopper", 2, "L"]]]},
		{"name": "방파제 수로", "len": 1500, "plat": [[220, 446, 180], [790, 531, 160, "boat", 170], [1280, 420, 160]], "hazards": [["water", 600, 540]], "props": [["crate", 300], ["barrel", 1360]], "pows": [["cage", 1250, "food"]],
			"waves": [[100, "grunt", 2, "R"], [300, "flyer", 2, "R"], [500, "grunt", 1, "T"], [800, "bomber", 1, "R"], [1100, "grunt", 2, "R"], [1200, "hopper", 2, "L"]],
			"arena": [[["grunt", 2, "R"], ["flyer", 1, "R"]], [["heavy", 1, "R"], ["grunt", 1, "T"]]]},
		{"name": "상륙정 선착장", "len": 1400, "plat": [[260, 446, 200], [720, 531, 160, "boat", 160], [1080, 420, 200]], "hazards": [["water", 540, 520]], "props": [["barrel", 420], ["crate", 1100]], "pows": [["cage", 1200, "support"]],
			"waves": [[150, "heavy", 1, "R"], [200, "grunt", 1, "R"], [400, "grunt", 2, "P"], [850, "flyer", 2, "R"], [1050, "bomber", 1, "T"], [1100, "grunt", 1, "R"]],
			"arena": [[["grunt", 2, "R"], ["flyer", 1, "R"], ["grunt", 1, "T"]], [["heavy", 1, "R"], ["shield", 1, "L"]]]}]},
	{"theme": "fortress", "boss": "tank", "par": 480, "zones": [
		{"name": "요새 외벽", "len": 1300, "plat": [[300, 446, 200], [650, 396, 180]], "hazards": [["steam", 520, 100]], "props": [["barrel", 420], ["crate", 900]], "pows": [["cage", 760, "weapon", 2]],
			"waves": [[100, "grunt", 2, "R"], [200, "grunt", 1, "T"], [350, "shield", 1, "R"], [650, "flyer", 2, "R"], [900, "hopper", 2, "L"], [950, "bomber", 1, "R"]], "turrets": [1150],
			"arena": [[["shield", 2, "R"], ["grunt", 1, "T"]], [["heavy", 1, "R"], ["grunt", 2, "P"]]]},
		{"name": "해산물 병영", "len": 1400, "plat": [[260, 430, 200], [600, 380, 180], [950, 430, 200]], "hazards": [["steam", 470, 100], ["steam", 820, 100]], "props": [["crate", 380], ["barrel", 700], ["barrel", 1150]], "pows": [["cage", 650, "weapon", 3], ["cage", 1050, "food"]],
			"waves": [[120, "bomber", 1, "R"], [150, "grunt", 1, "T"], [400, "grunt", 2, "P"], [700, "heavy", 1, "R"], [750, "bomber", 1, "T"], [1000, "flyer", 3, "R"]],
			"arena": [[["heavy", 1, "R"], ["bomber", 1, "R"]], [["shield", 1, "R"], ["hopper", 2, "L"], ["grunt", 1, "T"]]]},
		{"name": "탄약고", "len": 1400, "plat": [[280, 446, 200], [620, 396, 180], [960, 446, 200]], "hazards": [["steam", 500, 100], ["steam", 840, 100]], "props": [["barrel", 400], ["barrel", 760], ["crate", 1100]], "pows": [["cage", 700, "weapon", 1]],
			"waves": [[100, "heavy", 1, "R"], [200, "grunt", 1, "T"], [450, "shield", 1, "R"], [650, "bomber", 1, "R"], [850, "grunt", 2, "P"], [1050, "flyer", 2, "R"]], "turrets": [1250],
			"arena": [[["heavy", 1, "R"], ["shield", 1, "R"]], [["grunt", 2, "L"], ["bomber", 1, "T"]]]},
		{"name": "중앙 보급로", "len": 1300, "plat": [[300, 446, 200], [700, 400, 200]], "hazards": [["steam", 560, 100]], "props": [["barrel", 250], ["crate", 880], ["barrel", 1000]], "pows": [["cage", 780, "support"]],
			"waves": [[100, "shield", 1, "R"], [150, "grunt", 1, "R"], [400, "flyer", 2, "R"], [450, "grunt", 1, "T"], [700, "grunt", 2, "L"]], "turrets": [1150],
			"arena": [[["heavy", 2, "R"], ["grunt", 1, "T"]], [["grunt", 2, "P"], ["hopper", 2, "L"]]]},
		{"name": "감시탑 회랑", "len": 1300, "plat": [[240, 420, 180], [560, 370, 180], [880, 420, 180]], "hazards": [["steam", 420, 100], ["steam", 740, 100]], "props": [["crate", 320], ["barrel", 1000]], "pows": [["cage", 640, "food"], ["cage", 1100, "ammo"]],
			"waves": [[120, "flyer", 2, "R"], [250, "grunt", 2, "R"], [400, "grunt", 1, "T"], [600, "heavy", 1, "R"], [850, "hopper", 2, "L"], [1000, "bomber", 1, "R"]],
			"arena": [[["shield", 1, "R"], ["grunt", 2, "P"]], [["heavy", 1, "R"], ["flyer", 2, "R"], ["grunt", 1, "T"]]]},
		{"name": "오리고기 사령부", "len": 1300, "plat": [[260, 420, 200], [640, 370, 200]], "hazards": [["steam", 480, 100]], "props": [["crate", 360], ["barrel", 900]], "pows": [["cage", 820, "ammo"]],
			"waves": [[100, "grunt", 2, "R"], [250, "grunt", 1, "T"], [350, "bomber", 1, "R"], [650, "shield", 1, "R"], [700, "bomber", 1, "T"], [900, "flyer", 2, "R"]],
			"arena": [[["heavy", 1, "R"], ["shield", 1, "R"]], [["bomber", 1, "R"], ["grunt", 2, "P"], ["grunt", 1, "T"]], [["hopper", 3, "L"], ["flyer", 1, "R"]]]}]}]
const BOSS_ARENA := 1400
# Boss death timeline (celebrate counts down from CELEBRATE_TIME): chain explosions, the final burst at CELEBRATE_BURST,
# the wreck fades out over 1.2s, then MISSION COMPLETE at CELEBRATE_CALLOUT, and the screen whites out before the tally.
# Grenades: GRENADE_START on a new game, topped back up to GRENADE_FLOOR on respawn/continue/next mission.
# Grenade throw: THROW_TIME of animation; the grenade leaves the hand THROW_RELEASE into it (after the wind-up).
const THROW_TIME := .32
const THROW_RELEASE := .1
const GRENADE_START := 10
const GRENADE_FLOOR := 10
const CELEBRATE_TIME := 6.4
# Harbor boss: open sea between the arena start and the ship's stern; the deck runs from there to the stage end.
const SHIP_SEA := 680.0
const SHIP_SPEED := 320.0
const CELEBRATE_BURST := 4.2
const CELEBRATE_CALLOUT := 2.8
const STORY_LEN := 25
# Slows the whole intro cutscene timeline (25 story-seconds play over ~36 real seconds).
const STORY_SPEED := .7

const BOSSES := {
	"king": {"name": "오리고기 보행전차", "title": "과메기 선발대 지휘관", "hp": 170, "w": 340, "h": 330, "score": 8000},
	"cannon": {"name": "오리고기 꿀 공성포", "title": "과메기 포병대 지휘관", "hp": 260, "w": 400, "h": 420, "score": 10000},
	"boat": {"name": "오리고기 상륙 지휘함", "title": "과메기 상륙대 지휘관", "hp": 330, "w": 480, "h": 440, "score": 12000},
	"tank": {"name": "초거대 과메기 전차", "title": "오리고기 사령관", "hp": 620, "w": 540, "h": 440, "score": 20000}}

# STAGES gets zones/length/theme/boss filled in from LEVELS, like the JS forEach at load time.
# Boss rigs (generated/bosses/<sheet>.png: 4x2 cells of 512px, all facing left — 0 body, 1 body damaged, 2/3 weapon A ok/broken,
# 4/5 weapon B ok/broken, 6 open hatch, 7 debris). k = body draw scale (cell px -> screen); base = feet line of the body cell.
# Parts: pivot (pu,pv) in its own cell sits on body point (u,v); ps = part scale relative to the body; mu/mv = muzzle; box = opaque bounds (cell px).
const BOSS_RIG := {
	"king": {"sheet": "walker", "k": 1.35, "base": .9, "box": [44, 82, 470, 462], "home": 300, "core": [.58, .38], "nameA": "턱 기관포 파괴", "nameB": "미사일 포드 파괴",
		"A": {"u": .36, "v": .64, "pu": .74, "pv": .6, "ps": .5, "mu": .18, "mv": .6, "box": [84, 202, 413, 420], "hp": .22, "aim": .5},
		"B": {"u": .86, "v": .2, "pu": .83, "pv": .5, "ps": .4, "mu": .15, "mv": .4, "box": [43, 122, 458, 383], "hp": .18, "rot": -.3},
		"H": {"u": .6, "v": .22, "pu": .5, "pv": .86, "ps": .38}},
	"cannon": {"sheet": "cannon", "k": 1.15, "base": .924, "box": [39, 110, 486, 473], "home": 330, "core": [.53, .5], "nameA": "꿀 박격포 파괴", "nameB": "꿀 화염방사기 파괴",
		"A": {"u": .7, "v": .4, "pu": .5, "pv": .86, "ps": .38, "mu": .17, "mv": .33, "box": [37, 105, 458, 456], "hp": .22},
		"B": {"u": .22, "v": .64, "pu": .82, "pv": .55, "ps": .45, "mu": .15, "mv": .45, "box": [70, 100, 469, 357], "hp": .18},
		"H": {"u": .84, "v": .3, "pu": .45, "pv": .74, "ps": .38}},
	"boat": {"sheet": "ship", "k": 1.4, "base": .87, "box": [54, 82, 476, 446], "home": 260, "core": [.54, .5], "nameA": "갑판 포탑 파괴", "nameB": "크레인 파괴", "left": true,
		"A": {"u": .4, "v": .36, "pu": .6, "pv": .86, "ps": .36, "mu": .17, "mv": .43, "box": [68, 189, 437, 460], "hp": .22, "aim": .6},
		"B": {"u": .74, "v": .5, "pu": .72, "pv": .72, "ps": .45, "mu": .18, "mv": .5, "box": [49, 95, 462, 404], "hp": .18},
		"H": {"u": .62, "v": .38, "pu": .5, "pv": .88, "ps": .35}},
	"tank": {"sheet": "tank", "k": 1.5, "base": .905, "box": [76, 104, 467, 463], "home": 330, "core": [.47, .49], "nameA": "주포 파괴", "nameB": "측면 개틀링 파괴",
		"A": {"u": .36, "v": .64, "pu": .6, "pv": .8, "ps": .45, "mu": .2, "mv": .5, "box": [85, 200, 408, 422], "hp": .2, "aim": .2},
		"B": {"u": .66, "v": .62, "pu": .55, "pv": .7, "ps": .45, "mu": .2, "mv": .47, "box": [80, 175, 413, 382], "hp": .16},
		"H": {"u": .6, "v": .36, "pu": .45, "pv": .84, "ps": .38}}}
static var STAGES: Array = _build_stages()

static func _build_stages() -> Array:
	var stages := [
		{"name": "방송국 습격", "sub": "꽃과 꿀의 마을 · 끊어진 방송을 되찾아라", "color": "#85bf9e"},
		{"name": "꿀 저장고 탈환", "sub": "벌집 공장 · 컨베이어와 꿀 함정을 돌파하라", "color": "#d5a94d"},
		{"name": "과메기 해안기지", "sub": "해안과 항구 · 수륙양용 부대를 격파하라", "color": "#68afb6"},
		{"name": "과메기단 본부", "sub": "해산물 요새 · 오리고기의 초거대 전차", "color": "#8c829f"}]
	for i in range(LEVELS.size()):
		var level: Dictionary = LEVELS[i]; var s: Dictionary = stages[i]
		var names := []; var total := 0
		for z in level.zones:
			names.append(z.name); total += z.len
		s.zones = names; s.length = total + BOSS_ARENA; s.theme = level.theme; s.boss = BOSSES[level.boss]
	return stages

static func clamp(v: float, a: float, b: float) -> float: return minf(b, maxf(a, v))
static func rand(a: float, b: float) -> float: return a + randf() * (b - a)
static func pick(a: Array) -> Variant: return a[randi() % a.size()]

static func intersects(a: Dictionary, b: Dictionary, r: Dictionary) -> bool:
	var t0 := 0.0; var t1 := 1.0
	var dx: float = b.x - a.x; var dy: float = b.y - a.y
	for pq in [[-dx, a.x - r.x], [dx, r.x + r.w - a.x], [-dy, a.y - r.y], [dy, r.y + r.h - a.y]]:
		var p: float = pq[0]; var q: float = pq[1]
		if p == 0:
			if q < 0: return false
		else:
			var t := q / p
			if p < 0: t0 = maxf(t0, t)
			else: t1 = minf(t1, t)
			if t0 > t1: return false
	return true

static func overlap(a: Dictionary, b: Dictionary) -> bool:
	return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y

static func _sign1(v: float) -> float:
	var s := signf(v)
	return s if s != 0 else 1.0

static func playerFrame(g) -> int:
	if g.dying > 0 or g.hurtTimer > 0: return 7
	if g.crouch: return 5
	if not g.grounded: return 6
	if absf(g.vx) > 30: return posmod(floori(g.stageTime * 12), 4)
	return 4

static func weaponPose(g) -> Dictionary:
	var frame := playerFrame(g); var v: Dictionary = VISUALS[g.weapon]; var a: Dictionary = g.aim()
	var up: bool = a.y < -.92 and not (g.dying > 0) and not (g.hurtTimer > 0) and not (g.knife > 0)
	var diagonal: bool = absf(a.x) > .2
	var aimFrame: int
	if diagonal: aimFrame = 5 if g.muzzle > .045 else 4
	elif not g.grounded: aimFrame = 6
	elif g.crouch: aimFrame = 7
	elif absf(g.vx) > 30: aimFrame = 2 + posmod(floori(g.stageTime * 9), 2)
	else: aimFrame = 1 if g.muzzle > .045 else 0
	var anchors := [[.52, .55], [.53, .55], [.54, .54], [.51, .55], [.52, .54], [.55, .67], [.55, .49], [.55, .53]]
	var rear := [[.69, .30], [.70, .34], [.72, .29], [.77, .30], [.74, .35], [.78, .36], [.70, .28], [.77, .42]]
	# Running or landing while aiming straight up uses the rear run sheet (8 run + land) with its own grip points. Its
	# rise/apex/fall frames (8-10) have the head cut off at the cell top, so jumps keep the aim sheet's rear jump pose.
	var sheet := "aim"; var sheetFrame := aimFrame
	if up and not g.crouch and not diagonal and g.grounded:
		if absf(g.vx) > 30:
			sheet = "upRun"; sheetFrame = posmod(floori(g.stageTime * 15), 8)
		elif g.landed > 0:
			sheet = "upRun"; sheetFrame = 11
	var upRun := [[.72, .30], [.72, .30], [.72, .30], [.72, .30], [.72, .28], [.72, .28], [.72, .28], [.72, .28], [.745, .13], [.745, .13], [.745, .13], [.745, .30]]
	# The pistol uses its own two-handed sheets (hero_body_pistol / hero_run_pistol): the grip sits in the clasped hands.
	var pistolBody := [[.677, .549], [.691, .56], [.699, .56], [.699, .558], [.674, .518], [.689, .611], [.691, .488], [.701, .539]]
	var pistolRun := [[.698, .508], [.705, .51], [.703, .513], [.724, .504], [.712, .492], [.746, .504], [.739, .503], [.766, .504]]
	var pistolAnchor: Array = pistolRun[posmod(floori(g.stageTime * 15), 8)] if frame < 4 and g.grounded and not g.crouch else pistolBody[frame]
	var anchor: Array = ((upRun[sheetFrame] if sheet == "upRun" else rear[aimFrame]) if up else (pistolAnchor if g.weapon == PISTOL else anchors[frame]))
	var recoil: float = maxf(0, g.muzzle) / .09 * v.recoil * .35
	var bob: float = sin(g.stageTime * 3) * .65 if g.grounded and absf(g.vx) < 30 else 0.0
	var bx: float = -a.x * recoil; var by: float = -a.y * recoil + bob
	var x: float = g.x + (anchor[0] - .5) * 108 * g.face + bx
	var y: float = g.y + (anchor[1] - 1) * 108 + by
	var reach: float = v.width * .75 * (1 - v.grip)
	var normal: float = -v.width * .75 * v.ratio * .13 * g.face
	return {"frame": frame, "up": up, "aimFrame": aimFrame, "sheet": sheet, "sheetFrame": sheetFrame, "bx": bx, "by": by, "x": x, "y": y,
		"angle": atan2(a.y * g.face, a.x * g.face), "face": g.face, "width": v.width * .75, "height": v.width * .75 * v.ratio, "grip": v.grip,
		"mx": x + a.x * reach - a.y * normal, "my": y + a.y * reach + a.x * normal, "aim": a}

# ================= game state =================
var mode := "title"
var stage := 0
var time := 0.0
var best := 0
var difficulty := "normal"
var shakeScale := 1.0
var sound: Callable = func(_n): pass
var voice: Callable = func(_t): pass
var onSave: Callable = func(_v): pass
var score := 0
var rescued := 0
var credits := 0
var kills := 0
var input: Dictionary = {}
var hp := 0
var lives := 0
var grenades := 0
var weapon := PISTOL
var unlocked: Array = []
var ammo: Array = []
var briefTime := 0.0
var storyTime := 0.0

var x := 180.0
var y := float(FLOOR)
var vx := 0.0
var vy := 0.0
var face := 1.0
var grounded := true
var crouch := false
var invincible := 0.0
var entering := false
var fireTimer := 0.0
var grenadeTimer := 0.0
var muzzle := 0.0
var coyote := 0.0
var jumpBuffer := 0.0
var dropTimer := 0.0
var standOn := ""
var camera := 0.0
var lock = null
var shake := 0.0
var hitstop := 0.0
var combo := 0
var comboTimer := 0.0
var stageTime := 0.0
var stageRescued := 0
var stageKills := 0
var stageHits := 0
var support := 0.0
var supportTimer := 0.0
var hurtTimer := 0.0
var dying := 0.0
var knife := 0.0
var throwT := 0.0
var throwPending := false
var aimLocal := 0.0
var lastShotWeapon := PISTOL
var weaponPop := 0.0
var zoneIndex := 0
var celebrate := 0.0
var chain := 0.0
var intro := 0.0
var banner := ""
var bannerTime := 0.0
var bannerMax := 2.4
var callout = null
var result = null
var continueTime := 0.0
var landed := 0.0
var spawnQueue: Array = []
var supplies: Array = []
var enemies: Array = []
var bullets: Array = []
var particles: Array = []
var corpses: Array = []
var blasts: Array = []
var popups: Array = []
var pows: Array = []
var items: Array = []
var platforms: Array = []
var hazards: Array = []
var props: Array = []
var boss = null
var ship = null
var nextId := 1
var zones: Array = []
var bossStart := 0.0

var dif: Dictionary:
	get: return DIFFICULTY.get(difficulty, DIFFICULTY.normal)
var level: Dictionary:
	get: return LEVELS[stage]

func _init() -> void:
	resetLoadout(); loadStage(); mode = "title"

func resetLoadout() -> void:
	hp = dif.hp; lives = dif.lives; grenades = GRENADE_START; weapon = PISTOL; unlocked = [PISTOL]
	ammo = []
	for w in WEAPONS: ammo.append(-1 if w.ammo < 0 else 0)

func _sound(n: String) -> void: sound.call(n)
func _voice(t: String) -> void: voice.call(t)

# ---- flow ----
func start(s := 0, story := false) -> void:
	stage = s; score = 0; rescued = 0; credits = 0; kills = 0; resetLoadout(); loadStage()
	mode = "story" if story else "briefing"; briefTime = 0; storyTime = 0

func confirm() -> void:
	match mode:
		"title": start()
		"gameover", "victory": mode = "title"
		"story": mode = "briefing"; briefTime = 0
		"briefing": begin()
		"pause": mode = "play"
		"result": nextStage()
		"continue": continueGame()

func begin() -> void:
	enterStage(); _voice("Mission " + ["one", "two", "three", "final"][stage] + ". Start!"); _sound("start")

func nextStage() -> void:
	if stage >= LEVELS.size() - 1:
		mode = "victory"; save(); _sound("victory"); _voice("Mission complete! Congratulations!"); return
	stage += 1; hp = dif.hp; grenades = maxi(grenades, GRENADE_FLOOR); loadStage(); mode = "briefing"; briefTime = 0

func pause() -> void:
	if mode == "play": mode = "pause"
	elif mode == "pause": mode = "play"

func retry() -> void:
	if not mode in ["pause", "gameover", "continue"]: return
	resetLoadout(); loadStage(); enterStage()

# Metal Slug-style opening: the hero runs in from off-screen left and control starts once they reach the start mark.
func enterStage() -> void:
	mode = "play"; intro = 2.6; entering = true; x = camera - 70; vx = 0; face = 1

func quit() -> void:
	save(); mode = "title"

func continueGame() -> void:
	if mode != "continue": return
	credits += 1; lives = dif.lives; hp = dif.hp; grenades = maxi(grenades, GRENADE_FLOOR); mode = "play"; respawn(); _voice("Let's go!")

func save() -> void:
	best = maxi(best, score); onSave.call(best)

func loadStage() -> void:
	var L: Dictionary = level
	x = 180; y = FLOOR; vx = 0; vy = 0; face = 1; grounded = true; crouch = false; invincible = 0; entering = false
	fireTimer = 0; grenadeTimer = 0; muzzle = 0; coyote = 0; jumpBuffer = 0; dropTimer = 0; standOn = ""
	camera = 0; lock = null; shake = 0; hitstop = 0; combo = 0; comboTimer = 0; stageTime = 0; stageRescued = 0; stageKills = 0; stageHits = 0
	support = 0; supportTimer = 0
	hurtTimer = 0; dying = 0; knife = 0; throwT = 0; throwPending = false; aimLocal = 0; lastShotWeapon = PISTOL; weaponPop = 0; zoneIndex = 0; celebrate = 0
	intro = 0; banner = ""; bannerTime = 0; callout = null; result = null; continueTime = 0; landed = 0
	enemies = []; bullets = []; particles = []; corpses = []; blasts = []; popups = []; pows = []; items = []; platforms = []; hazards = []; props = []
	boss = null; ship = null; nextId = 1; spawnQueue = []; supplies = []
	zones = []; var start_x := 0
	var zi := 0
	for z in L.zones:
		var waves := []
		for w in z.waves: waves.append({"at": start_x + w[0], "kind": w[1], "n": w[2], "entry": w[3], "done": false})
		zones.append({"name": z.name, "start": start_x, "end": start_x + z.len, "cleared": false, "entered": zi == 0, "waves": waves, "arena": z.arena, "arenaWave": -1, "arenaDelay": 0.0})
		for pl in z.plat:
			platforms.append({"x": float(start_x + pl[0]), "base": float(start_x + pl[0]), "y": float(pl[1]), "w": float(pl[2]), "h": 20.0, "type": pl[3] if pl.size() > 3 else "normal", "amp": float(pl[4]) if pl.size() > 4 else 52.0})  # boats: 5th value = ferry swing
		for hz in z.get("hazards", []):
			var kind: String = hz[0]
			if kind == "water": hazards.append({"x": float(start_x + hz[1]), "y": 571.0, "w": float(hz[2]), "h": 150.0, "kind": kind})
			else: hazards.append({"x": float(start_x + hz[1]), "y": 568.0, "w": float(hz[2]), "h": 12.0, "kind": kind})
		for pr in z.props:
			props.append({"x": float(start_x + pr[1]), "y": float(FLOOR), "kind": pr[0], "hp": 4.0 if pr[0] == "barrel" else 7.0, "flash": 0.0})
		for pw in z.pows:
			pows.append({"x": float(start_x + pw[1]), "y": float(FLOOR), "kind": pw[0], "state": "caged" if pw[0] == "cage" else "tied", "hp": 6.0,
				"reward": pw[2], "weapon": pw[3] if pw.size() > 3 else null, "t": rand(0, 3), "vy": 0.0, "flash": 0.0, "dropped": false})
		for tx in z.get("turrets", []):
			var tur := spawnEnemy(start_x + tx, FLOOR, "turret"); tur.zone = zi
		start_x += z.len; zi += 1
	bossStart = start_x
	# Boss arena gimmicks: walker — a ledge to dodge stomp waves from; factory — floor conveyors pushing toward the boss;
	# harbor — the player boards a big ship that casts off when the fight starts (the crane adds temporary crate platforms);
	# fortress — open ground for fire patches.
	if L.boss == "king": platforms.append({"x": float(start_x + 380), "base": float(start_x + 380), "y": 446.0, "w": 200.0, "h": 20.0, "type": "normal"})
	if L.boss == "cannon":
		for pb in [[260, 240], [600, 180]]: platforms.append({"x": float(start_x + pb[0]), "base": float(start_x + pb[0]), "y": 564.0, "w": float(pb[1]), "h": 20.0, "type": "belt"})
	if L.boss == "boat": ship = {"x": float(start_x + SHIP_SEA)}
	banner = ""; bannerTime = 0

func toast(s: String, t := 2.4) -> void:
	banner = s; bannerTime = t; bannerMax = t

## JS `call(text, sub, voice)`.
func callOut(text: String, sub := "", v := "") -> void:
	callout = {"text": text, "sub": sub, "t": 0.0}
	if v != "": _voice(v)

# ---- entities ----
func spawnEnemy(ex: float, ey: float, kind: Variant = "grunt", entry := "") -> Dictionary:
	if kind is int: kind = ["grunt", "flyer", "heavy", "hopper"][kind] if kind >= 0 and kind < 4 else "grunt"
	# ground troops never appear standing on open water: move them to the far bank
	if kind != "flyer":
		for h in hazards:
			if h.kind == "water" and ex > h.x - 20 and ex < h.x + h.w + 20: ex = h.x + h.w + 40
	var base: Dictionary = ENEMIES[kind]
	var ehp := float(roundi((base.hp + stage * 1.5) * dif.enemyHp))
	var e := {"id": nextId, "kind": kind, "x": float(ex), "y": float(ey), "vx": 0.0, "vy": 0.0, "hp": ehp, "max": ehp, "t": rand(0, 2), "shot": rand(1.4, 2.6) * dif.fire,
		"flash": 0.0, "warn": 0, "facing": -1.0, "walk": 0, "kick": 0.0, "zone": -1,
		"state": "para" if entry == "P" else ("enter" if entry != "" else "idle"), "alert": 1 if kind == "turret" else 0, "startle": 0.0,
		"range": rand(240, 420), "launch": 0.0, "peek": 0.0, "stab": 0.0, "hopT": rand(.2, .8), "air": false, "arena": false, "burst": 0, "burstT": 0.0,
		"floor": float(FLOOR), "perchL": -1e9, "perchR": 1e9, "hold": float({"shield": 300, "heavy": 380, "bomber": 360}.get(kind, 0)), "ofs": 0.0, "cover": 0.0, "coverIdx": -1}
	nextId += 1
	if kind == "flyer":
		e.y = minf(ey, rand(170, 250)); e.state = "enter" if entry != "" else "idle"
	if entry == "P": e.vy = 150.0
	enemies.append(e)
	return e

# Squads trickle in one by one (Metal Slug style) instead of popping in as a pile; members get distinct roles/slots.
func spawnWave(kind: String, n: int, entry: String, zone: int, arena := false, delay := 0.0) -> void:
	var gap := .45 if entry == "P" else (.3 if kind == "hopper" else (.4 if kind == "flyer" else .55))
	for i in range(n):
		spawnQueue.append({"t": delay + i * gap, "kind": kind, "entry": entry if entry != "" else "R", "zone": zone, "i": i, "n": n, "arena": arena})
	updateSpawns(0)

func updateSpawns(dt: float) -> void:
	for q in spawnQueue:
		q.t -= dt
		if q.t <= 0: spawnMember(q)
	spawnQueue = spawnQueue.filter(func(q): return q.t > 0)

func spawnMember(q: Dictionary) -> Dictionary:
	var kind: String = q.kind; var zone: int = q.zone; var i: int = q.i; var n: int = q.n
	var entry: String = q.entry; var ex := 0.0; var ey := float(FLOOR); var perch = null
	if entry == "T":
		perch = perchFor(i) if kind in ["grunt", "bomber", "heavy", "shield"] else null
		if perch == null: entry = "R"
	if perch != null:
		ex = perch.x + perch.w * (.3 + .4 * ((i / 2) % 2)); ey = perch.y - 180
	elif entry == "L": ex = camera - 50
	elif entry == "P":
		var span := 770.0 / n; ex = camera + 380 + span * (i + .5) + rand(-span * .2, span * .2); ey = -70 - rand(0, 50)
	else: ex = camera + 1330
	if kind == "flyer" and entry != "P": ey = 175.0 + (i % 3) * 38
	var e := spawnEnemy(ex, ey, kind, "" if perch != null else entry)
	e.zone = zone; e.facing = 1.0 if entry == "L" else -1.0; e.arena = q.arena
	if perch != null:
		e.floor = perch.y; e.perchL = perch.x + 16; e.perchR = perch.x + perch.w - 16; e.air = true; e.vy = 0.0
	# Roles: shields hold the front, heavies behind them, riflemen and pot throwers further back, each in its own slot.
	if kind == "grunt": e.range = 280.0 + i * 80 + rand(0, 40)
	elif kind == "shield": e.hold = 230.0 + i * 70
	elif kind == "heavy": e.hold = 340.0 + i * 80
	elif kind == "bomber": e.hold = 400.0 + i * 70
	elif kind == "flyer": e.ofs = (i - (n - 1) / 2.0) * 120
	return e

## A plain platform ahead of the player (on screen or just beyond it) for snipers that drop in from above.
func perchFor(i: int):
	var c := []
	for p in platforms:
		if p.type == "normal" and p.x + p.w > camera + 460 and p.x < camera + 1500: c.append(p)
	c.sort_custom(func(a, b): return a.x < b.x)
	return c[i % c.size()] if c.size() else null

func takeCover(e: Dictionary) -> void:
	if not (e.kind in ["grunt", "bomber", "heavy"]) or e.perchL > -1e8: return
	var best := -1; var bd := 1e9
	for i in range(props.size()):
		var p: Dictionary = props[i]
		if p.kind != "crate" or p.hp <= 0 or absf(p.x - x) < 220 or p.x < camera + 80 or p.x > camera + W - 80: continue
		if signf(p.x - x) != signf(e.x - x): continue
		var taken := false
		for o in enemies:
			if o != e and o.hp > 0 and o.coverIdx == i: taken = true
		if taken: continue
		var dd := absf(p.x - e.x)
		if dd < bd:
			bd = dd; best = i
	if best >= 0:
		var p: Dictionary = props[best]; e.coverIdx = best; e.cover = p.x + signf(p.x - x) * 46

## Crouch behind a claimed crate until it breaks or the hero gets around/close to it.
func holdCover(e: Dictionary, speed: float, dt: float) -> bool:
	if e.coverIdx < 0: return false
	var p = props[e.coverIdx] if e.coverIdx < props.size() else null
	if p == null or p.hp <= 0 or signf(p.x - x) != signf(e.x - x) or absf(p.x - x) < 150:
		e.coverIdx = -1; return false
	if absf(e.cover - e.x) > 6: walkEnemy(e, signf(e.cover - e.x), speed, dt)
	return true

## Living ground troops keep a little elbow room so squads read as individuals, not a pile.
# Landed ground troops that end up over open water (pushed or hopped in) step back onto the nearer bank.
func keepEnemiesOffWater() -> void:
	for e in enemies:
		if e.hp <= 0 or e.kind == "flyer" or e.kind == "turret" or e.state == "para" or e.state == "enter" or e.get("air", false) or e.get("launch", 0.0) > 0 or e.y < FLOOR - 2: continue
		for h in hazards:
			if h.kind == "water" and e.x > h.x - 20 and e.x < h.x + h.w + 20:
				e.x = h.x - 20 if e.x - h.x < h.x + h.w - e.x and not h.get("sea", false) else h.x + h.w + 20
				break

func separateEnemies(dt: float) -> void:
	var SEP := 72.0; var k := minf(1, dt * 10)
	var gr := enemies.filter(func(e): return e.hp > 0 and e.kind != "flyer" and e.kind != "turret" and e.state != "para" and e.state != "enter" and not e.air and not (e.launch > 0))
	gr.sort_custom(func(a, b): return a.x < b.x)
	for j in range(1, gr.size()):
		var a: Dictionary = gr[j - 1]; var b: Dictionary = gr[j]
		if absf(a.y - b.y) > 30: continue
		var gap: float = b.x - a.x
		if gap < SEP:
			var push := (SEP - gap) * .5 * k
			a.x = clampf(a.x - push, a.perchL, a.perchR); b.x = clampf(b.x + push, b.perchL, b.perchR)

# ---- main update ----
func update(dt: float, inp: Dictionary = {}) -> void:
	time += dt; input = inp
	if mode == "story":
		storyTime += dt * STORY_SPEED
		if storyTime >= STORY_LEN:
			mode = "briefing"; briefTime = 0
		return
	if mode == "briefing":
		briefTime += dt; return
	if mode == "continue":
		continueTime -= dt
		if continueTime <= 0:
			mode = "gameover"; save(); _sound("gameover"); _voice("Game over")
		return
	if mode == "celebrate":
		updateCelebrate(dt); return
	if mode == "result":
		result.t += dt; updateFx(dt); return
	if mode != "play": return
	if hitstop > 0:
		hitstop -= dt; return
	stageTime += dt; intro = maxf(0, intro - dt)
	hurtTimer = maxf(0, hurtTimer - dt); weaponPop = maxf(0, weaponPop - dt); invincible = maxf(0, invincible - dt)
	knife = maxf(0, knife - dt); throwT = maxf(0, throwT - dt); landed = maxf(0, landed - dt)
	if throwPending and throwT <= THROW_TIME - THROW_RELEASE: launchGrenade()
	fireTimer -= dt; grenadeTimer -= dt; muzzle -= dt; comboTimer -= dt; bannerTime -= dt; shake = maxf(0, shake - dt * 1.8)
	if callout != null:
		callout.t += dt
		if callout.t > 1.6: callout = null
	if comboTimer <= 0: combo = 0
	updatePlayer(dt, inp)
	updateEnemies(dt); updateBoss(dt); updateSupplies(dt); updateBullets(dt); updatePows(dt); updateItems(dt); updateZones(dt); updateFx(dt)
	updateSupport(dt); updateCamera(dt)

func updatePlayer(dt: float, inp: Dictionary) -> void:
	if dying > 0:
		dying -= dt; vy += 1650 * dt; x += vx * dt; y = minf(FLOOR, y + vy * dt)
		if dying <= 0:
			if lives <= 0:
				mode = "continue"; continueTime = 10; _voice("Continue?"); _sound("continue")
			else: respawn()
		return
	if entering:
		inp = {"right": x < ENTRY_X}
		if not inp.right: entering = false
	var axis := (1 if inp.get("right", false) else 0) - (1 if inp.get("left", false) else 0)
	crouch = grounded and bool(inp.get("down", false))
	if axis != 0: face = signf(axis)
	# Down + jump on a thin platform drops through it instead of jumping; belts and boats stay solid.
	if inp.get("jumpPressed", false):
		if grounded and inp.get("down", false) and standOn != "" and standOn != "belt" and standOn != "boat": dropTimer = .2
		else: jumpBuffer = .12
	dropTimer -= dt; jumpBuffer -= dt; coyote = .15 if grounded else coyote - dt
	if jumpBuffer > 0 and coyote > 0:
		vy = -810; grounded = false; jumpBuffer = 0; coyote = 0; _sound("jump"); dust(x, y, 6)
	if inp.get("jumpReleased", false) and vy < -260: vy = -260
	var target := axis * (95.0 if crouch else 300.0)
	vx += clampf(target - vx, -2400 * dt, 2400 * dt)
	var oldY := y; var wasGrounded := grounded; var fallSpeed := vy
	vy = minf(1100, vy + 1650 * dt); x += vx * dt; y += vy * dt; grounded = false; standOn = ""
	for p in platforms:
		if p.type == "boat": p.x = p.base + sin(time * 1.3) * float(p.get("amp", 52.0))
		if x > p.x - 12 and x < p.x + p.w + 12 and oldY <= p.y + 3 and y >= p.y and vy >= 0 and not (dropTimer > 0 and p.type != "belt" and p.type != "boat"):
			y = p.y; vy = 0; grounded = true; standOn = p.type
			if p.type == "belt": x += 95 * dt
			if p.type == "boat": x += cos(time * 1.3) * 1.3 * float(p.get("amp", 52.0)) * dt
	var water := false
	for h in hazards:
		if x > h.x and x < h.x + h.w and y >= 564:
			if h.kind == "water": water = true
			elif h.kind == "honey" or h.kind == "puddle":
				vx *= .75
				if randf() < .1: particles.append({"x": x, "y": FLOOR - 4.0, "vx": rand(-30, 30), "vy": -rand(40, 90), "life": .4, "max": .4, "color": "#ffbf49", "size": 4.0, "kind": "spark"})
			elif h.kind == "fire": hurt()
			elif fmod(time, 3.0) < 1.2: hurt()
	if y >= FLOOR and not water:
		y = FLOOR; vy = 0; grounded = true
	if grounded and not wasGrounded and fallSpeed > 420:
		dust(x, y, 8); landed = .12; _sound("land")
	if grounded and absf(vx) > 200 and floori(stageTime * 6) != floori((stageTime - dt) * 6): dust(x - face * 12, y, 2)
	if y > 800:
		hurt(true); return
	var left := camera - 100 if entering else camera + 30
	if lock != null and lock.has("left"): left = maxf(left, lock.left + 30)
	var right: float = lock.right - 30 if lock != null else STAGES[stage].length - 70.0
	x = clampf(x, left, right)
	# Aim sweeps toward the requested direction, like a heavy machine gun spray.
	var up := bool(inp.get("up", false)); var down := bool(inp.get("down", false)) and not grounded
	var diag := bool(inp.get("left", false) or inp.get("right", false))
	var want := -PI / 2 if up else ((PI / 4 if diag else PI / 2) if down else 0.0)
	var turn := (7.0 if weapon == 2 or weapon == 4 else 8.5) * dt
	aimLocal += clampf(want - aimLocal, -turn, turn)
	if inp.get("firePressed", false) and weapon == PISTOL and fireTimer > .08: fireTimer = 0
	if inp.get("fire", false) and fireTimer <= 0: shoot()
	if inp.get("grenadePressed", false) and grenades > 0 and grenadeTimer <= 0: throwGrenade()
	if inp.get("swapPressed", false) and unlocked.size() > 1:
		weapon = unlocked[(unlocked.find(weapon) + 1) % unlocked.size()]; weaponPop = 1; _sound("click")
	collectPows()

func aim() -> Dictionary:
	return {"x": cos(aimLocal) * face, "y": sin(aimLocal)}

func shoot() -> void:
	if ammo[weapon] == 0: dropWeapon()
	var target = knifeTarget()
	if target != null:
		knife = .22; fireTimer = .28; _sound("knife"); damageEnemy(target, 8, "knife"); burst(target.x - face * 10, target.y - 40, 8, "#fff4be", 200); return
	var w: Dictionary = WEAPONS[weapon]; var v: Dictionary = VISUALS[weapon]
	if ammo[weapon] > 0: ammo[weapon] -= 1
	var pose := weaponPose(self); var a: Dictionary = pose.aim; var spread := rand(-w.spread, w.spread); var ang := atan2(a.y, a.x) + spread
	var b := addBullet(pose.mx, pose.my, cos(ang) * w.speed, sin(ang) * w.speed, true, w.damage, v.kind)
	b.weapon = weapon; b.color = w.color
	fireTimer = w.rate; muzzle = .09; lastShotWeapon = weapon; _sound(v.sound)
	burst(pose.mx, pose.my, 10 if weapon == 3 else 2, w.color, 180 if weapon == 3 else 90)
	if weapon == 3:
		shake = maxf(shake, .25)
		particles.append({"x": pose.x - a.x * 40, "y": pose.y - a.y * 40, "vx": -a.x * 160, "vy": -a.y * 160 - 40, "life": .5, "max": .5, "color": "#d8c5c0", "size": 12.0, "kind": "smoke"})
	else:
		particles.append({"x": pose.x, "y": pose.y - 9, "vx": -face * rand(70, 130), "vy": -rand(110, 190), "life": 1.2, "max": 1.2, "color": "#efc17c", "size": 3.0, "kind": "casing", "spin": rand(-12, 12)})
	if ammo[weapon] == 0 and weapon != PISTOL: dropWeapon()

func knifeTarget():
	for e in enemies:
		if e.hp > 0 and e.kind != "turret" and e.kind != "flyer" and e.state != "para" and (e.x - x) * face > -34 and absf(e.x - x) < 80 and absf(e.y - y) < 60: return e
	return null

func dropWeapon() -> void:
	var old := weapon
	if old == PISTOL: return
	unlocked = unlocked.filter(func(w): return w != old); ammo[old] = 0; weapon = PISTOL; weaponPop = 1; toast("탄약 소진 · Glock 19")

func throwGrenade() -> void:
	grenades -= 1; grenadeTimer = .4; throwT = THROW_TIME; throwPending = true

func launchGrenade() -> void:
	throwPending = false
	bullets.append({"x": x + face * 20, "y": y - 70, "vx": face * 430 + vx * .4, "vy": -560.0, "friendly": true, "damage": 22.0, "life": 1.6, "kind": "grenade", "pierce": 0, "hit": [], "bounces": 0, "spin": 0.0})
	_sound("throw")

func addBullet(bx: float, by: float, bvx: float, bvy: float, friendly: bool, damage: float, kind: String) -> Dictionary:
	var b := {"x": bx, "y": by, "vx": bvx, "vy": bvy, "friendly": friendly, "damage": damage, "life": 3.0 if kind == "wave" else 2.5, "kind": kind, "pierce": 3 if kind == "sniper" else 0, "hit": []}
	bullets.append(b)
	return b

# ---- zones, waves, scroll locks ----
func updateZones(dt: float) -> void:
	updateSpawns(dt)
	if boss != null:
		if not boss.started and x >= (ship.x + 60 if ship != null else bossStart + 260): startBoss()
		return
	for i in range(zones.size()):
		var z: Dictionary = zones[i]
		if not z.entered and x >= z.start + 20:
			z.entered = true; zoneIndex = i; toast("AREA %d / %d · %s" % [i + 1, zones.size(), z.name])
		if z.entered and i > zoneIndex: zoneIndex = i
		for w in z.waves:
			if not w.done and x >= w.at:
				w.done = true; spawnWave(w.kind, w.n, w.entry, i)
		var prev_cleared := true
		for j in range(i):
			if not zones[j].cleared: prev_cleared = false
		if not z.cleared and lock == null and x >= z.end - 760 and prev_cleared:
			lock = {"zone": i, "cam": float(z.end - 1280), "right": float(z.end)}; z.arenaWave = -1; z.arenaDelay = .9; toast("적 부대 출현! · 전멸시켜라"); _sound("alarm")
	if lock != null and lock.zone != null:
		var z: Dictionary = zones[lock.zone]
		var alive := 0
		for e in enemies:
			if e.zone == lock.zone and e.arena and e.hp > 0: alive += 1
		for q in spawnQueue:
			if q.zone == lock.zone and q.arena: alive += 1
		z.arenaDelay -= dt
		if alive <= 1 and z.arenaDelay <= 0 and z.arenaWave < z.arena.size() - 1:
			z.arenaWave += 1; z.arenaDelay = 1.4
			if z.arenaWave > 0: toast("최후의 부대 접근! · 버텨라" if z.arenaWave == z.arena.size() - 1 else "적 증원 접근!", 1.6)
			var k := 0
			for wave in z.arena[z.arenaWave]:
				spawnWave(wave[0], wave[1], wave[2], lock.zone, true, k * .4); k += 1
		elif alive == 0 and z.arenaWave >= z.arena.size() - 1 and z.arenaDelay <= 0:
			z.cleared = true; z.clearedAt = stageTime; score += 1000; lock = null; _sound("clear")
			var last := true
			for q in zones:
				if not q.cleared: last = false
			toast("전 구역 확보! · 보스 구역으로 진입" if last else "구역 확보! +1000 · GO!")
			if last: boss = {"started": false}

func updateCamera(dt: float) -> void:
	var len: float = STAGES[stage].length
	var target := clampf(x - 470, 0, len - W)
	if lock != null: target = lock.cam
	if boss != null and boss.started: target = len - W
	var next := camera + (target - camera) * (1 - exp(-dt * (3.5 if lock != null else 6.0)))
	camera = next if lock != null else maxf(camera, next)

# ---- enemies ----
func updateEnemies(dt: float) -> void:
	var d_: Dictionary = dif
	for e in enemies:
		e.t += dt; e.flash = maxf(0, e.flash - dt); e.kick = maxf(0, e.kick - dt); e.startle = maxf(0, e.startle - dt); e.peek = maxf(0, e.peek - dt)
		if e.hp <= 0: continue
		if e.get("boat") != null: rideBoat(e)
		var onScreen: bool = e.x < camera + W + 60 and e.x > camera - 60
		if e.state == "para":
			e.y += e.vy * dt; e.x += sin(e.t * 2) * 20 * dt
			if e.y >= e.floor:
				e.y = e.floor; e.state = "idle"; e.kick = .25
			continue
		if e.launch > 0:
			e.launch -= dt; e.vy += 1250 * dt; e.x += e.vx * dt; e.y += e.vy * dt
			if e.y >= e.floor:
				e.y = e.floor; e.launch = 0.0; e.kick = .25; e.vx = 0.0; e.state = "idle"
			continue
		var dx: float = x - e.x; var d := _sign1(dx); var adx := absf(dx)
		if e.state == "enter":
			var inside: bool = e.x > camera + 40 and e.x < camera + W - 40
			if e.kind == "flyer": e.x += signf(camera + W / 2.0 - e.x) * 150 * dt
			else:
				e.x += signf(camera + W / 2.0 - e.x) * 140 * dt; e.walk = 1
			var fs := signf(camera + W / 2.0 - e.x)
			e.facing = fs if fs != 0 else -1.0
			if inside:
				e.state = "idle"; takeCover(e)
			continue
		if not onScreen and e.kind != "turret":
			# Off-screen troops sleep, but the scroll lock waits on its arena squad: march stragglers (knocked out, landed or
			# moved past water) back in, or the area can never clear.
			if lock != null and e.arena:
				e.state = "enter"; e.air = false; e.vy = 0.0; e.vx = 0.0
				if e.kind != "flyer": e.y = e.floor
			continue
		if e.kind == "turret" and (e.x > camera + W - 20 or e.x < camera - 60): continue
		if not e.alert and adx < 560:
			e.alert = 1; e.startle = .4
			if e.kind != "flyer":
				e.vy = -200.0; e.air = true
			_sound("alert")
		if e.air:
			e.vy += 1400 * dt; e.y += e.vy * dt; e.x = clampf(e.x + e.vx * dt, e.perchL, e.perchR)
			if e.y >= e.floor and e.vy > 0:
				e.y = e.floor; e.air = false; e.vy = 0.0; e.vx = 0.0
		if e.startle > 0: continue
		if considerFerry(e): continue
		e.facing = e.facing if e.kind == "shield" and e.peek <= 0 and adx < 40 else d
		e.shot -= dt; e.walk = 0
		var fire := func(rate: float) -> void:
			e.shot = rand(rate * .8, rate * 1.2) * d_.fire - stage * .12; e.kick = .22; e.warn = 0
		match e.kind:
			"grunt":
				if holdCover(e, ENEMIES.grunt.speed + stage * 8, dt): pass
				elif adx > e.range + 40: walkEnemy(e, d, ENEMIES.grunt.speed + stage * 8, dt)
				elif adx < e.range - 140 and adx > 90: walkEnemy(e, -d, 40, dt)
				if adx < 70 and absf(y - e.y) < 50:
					e.stab += dt; e.warn = 1
					if e.stab > .45:
						e.stab = 0.0; e.kick = .3
						if absf(x - e.x) < 80: hurt()
				else:
					e.stab = 0.0; e.warn = 1 if e.shot < .45 else 0
					if e.shot <= 0:
						fire.call(2.4); enemyShot(e, 0)
			"hopper":
				e.hopT -= dt
				if not e.air and e.hopT <= 0:
					e.air = true; e.vy = -rand(330, 480); e.vx = d * ENEMIES.hopper.speed * rand(.9, 1.3); e.hopT = rand(.35, .7)
				e.walk = 1; e.warn = 1 if adx < 180 else 0
			"flyer":
				var ty: float = 190 + sin(e.t * 1.7) * 40; e.y += (ty - e.y) * minf(1, dt * 2)
				var tx: float = x + e.ofs + sin(e.t * .9) * 90; e.x += clampf(tx - e.x, -ENEMIES.flyer.speed * dt, ENEMIES.flyer.speed * dt)
				e.warn = 1 if e.shot < .4 and adx < 120 else 0
				if e.shot <= 0 and adx < 140:
					fire.call(1.9); var b := addBullet(e.x, e.y + 10, 0, 60, false, 1, "bomb"); b.vy = 80.0
				elif e.shot <= 0: e.shot = .3
			"shield":
				if adx > e.hold: walkEnemy(e, d, ENEMIES.shield.speed, dt)
				e.warn = 1 if e.shot < .5 else 0
				if e.shot < .5: e.peek = maxf(e.peek, .5)
				if e.shot <= 0:
					fire.call(2.8); e.peek = .7; enemyShot(e, 0)
			"bomber":
				if holdCover(e, ENEMIES.bomber.speed, dt): pass
				elif adx > e.hold + 100: walkEnemy(e, d, ENEMIES.bomber.speed, dt)
				elif adx < e.hold - 100: walkEnemy(e, -d, 55, dt)
				e.warn = 1 if e.shot < .5 else 0
				if e.shot <= 0:
					fire.call(2.9)
					var t := 1.05; var bx: float = e.x + d * 20; var by: float = e.y - 70; var tx := x + rand(-40, 40)
					var b := addBullet(bx, by, (tx - bx) / t, (FLOOR - 8 - by - .5 * 950 * t * t) / t, false, 1, "lob"); b.life = 3.0
			"heavy":
				if holdCover(e, ENEMIES.heavy.speed, dt): pass
				elif adx > e.hold: walkEnemy(e, d, ENEMIES.heavy.speed, dt)
				e.warn = 1 if e.shot < .6 else 0
				if e.shot <= 0:
					fire.call(3.0)
					for off in [-.2, -.07, .07, .2]: enemyShot(e, off)
			"turret":
				e.facing = d; e.warn = 1 if e.shot < .6 else 0
				if e.shot <= 0:
					fire.call(2.6); e.burst = 3; e.burstT = 0.0
				if e.burst > 0:
					e.burstT -= dt
					if e.burstT <= 0:
						e.burst -= 1; e.burstT = .14; enemyShot(e, rand(-.05, .05), true)
		if e.kind != "turret" and e.kind != "flyer" and absf(dx) < 34 and absf(e.y - y) < 60 and (e.kind == "hopper" or e.air): hurt()
	separateEnemies(dt)
	keepEnemiesOffWater()
	enemies = enemies.filter(func(e): return e.hp > 0 and (e.state == "enter" or e.x > camera - 220))

# Harbor ferries: ground troops treat a boat as a bridge. Held up at a wide channel while the player is across (or on
# the boat), they hop aboard when it docks at their bank, ride it, and jump off once it docks at the player's bank.
func dockedBoat(h: Dictionary, side: float):
	for p in platforms:
		if p.type != "boat" or p.x + p.w < h.x or p.x > h.x + h.w: continue
		if (side < 0 and p.x - h.x < 50) or (side > 0 and h.x + h.w - (p.x + p.w) < 50): return p
	return null

func considerFerry(e: Dictionary) -> bool:
	if e.air or e.perchL > -1e8 or e.get("boat") != null or not (e.kind in ["grunt", "shield", "bomber", "heavy"]): return false
	for h in hazards:
		if h.kind != "water" or h.w <= 240 or h.get("sea", false): continue
		var side := 0.0
		if e.x >= h.x + h.w and e.x < h.x + h.w + 110 and x < h.x + h.w: side = 1.0
		elif e.x <= h.x and e.x > h.x - 110 and x > h.x: side = -1.0
		if side == 0: continue
		var p = dockedBoat(h, side)
		if p == null or enemies.filter(func(o): return o.hp > 0 and is_same(o.get("boat"), p)).size() >= 3: continue
		var tx: float = p.x + p.w * (.75 if side > 0 else .25)
		e.boat = p; e.boatX = p.x; e.floor = p.y; e.air = true; e.vy = -520.0; e.vx = (tx - e.x) / .64; e.facing = -side
		return true
	return false

func rideBoat(e: Dictionary) -> void:
	var p: Dictionary = e.boat
	if e.air:
		e.boatX = p.x; return
	e.x += p.x - e.boatX; e.boatX = p.x; e.perchL = p.x + 16; e.perchR = p.x + p.w - 16; e.x = clampf(e.x, e.perchL, e.perchR)
	var side := _sign1(x - e.x)
	for h in hazards:
		if h.kind != "water" or p.x + p.w < h.x or p.x > h.x + h.w: continue
		var across: bool = (side < 0 and x < h.x) or (side > 0 and x > h.x + h.w)
		if across and is_same(dockedBoat(h, side), p):
			var bank: float = h.x - 50 if side < 0 else h.x + h.w + 50
			e.boat = null; e.floor = float(FLOOR); e.perchL = -1e9; e.perchR = 1e9
			e.air = true; e.vy = -420.0; e.vx = (bank - e.x) / .69; e.facing = side
		return

func walkEnemy(e: Dictionary, dir: float, speed: float, dt: float) -> void:
	if e.air: return
	var nx: float = e.x + dir * speed * dt
	if nx < e.perchL or nx > e.perchR:
		var fs := signf(x - e.x)
		e.facing = fs if fs != 0 else e.facing
		return
	# narrow water is hopped over; wide water (harbor ferry) stops them at the bank, where they hold and fire
	for h in hazards:
		if e.perchL < -1e8 and h.kind == "water" and nx > h.x - 20 and nx < h.x + h.w + 20:
			if h.w <= 240:
				e.air = true; e.vy = -640.0; e.vx = dir * 330
			else:
				var fw := signf(x - e.x); e.facing = fw if fw != 0 else e.facing
			return
	e.x = nx; e.walk = 1
	var s := signf(x - e.x)
	e.facing = s if s != 0 else e.facing

func enemyShot(e: Dictionary, offset: float, big := false) -> void:
	var dir := _sign1(x - e.x); var size: float = ENEMIES[e.kind].size
	var sx: float = e.x + dir * size * .3; var sy: float = e.y - size * (.55 if e.kind == "turret" else .35)
	var a := atan2(y - 40 - sy, x - sx) + offset; var s: float = (320.0 if big else 250.0 + stage * 18) * dif.bullet
	addBullet(sx, sy, cos(a) * s, sin(a) * s, false, 1, "shell" if big else "enemy"); _sound("enemyShot")

func damageEnemy(e: Dictionary, n: float, src := "shot", bullet = null) -> Variant:
	if e.hp <= 0: return false
	if e.kind == "shield" and e.peek <= 0 and bullet != null and src == "shot" and signf(bullet.vx) == -e.facing and absf(bullet.vy) < absf(bullet.vx) * .7:
		_sound("ting")
		particles.append({"x": e.x + e.facing * 40, "y": e.y - 45, "vx": -bullet.vx * .2, "vy": -rand(80, 200), "life": .3, "max": .3, "color": "#fff", "size": 4.0, "kind": "spark"})
		return "block"
	e.hp -= n; e.flash = .1
	if e.hp <= 0: killEnemy(e, src)
	return true

func killEnemy(e: Dictionary, src: String) -> void:
	var base: Dictionary = ENEMIES[e.kind]
	combo += 1; comboTimer = 2.8; kills += 1; stageKills += 1
	var pts := roundi(base.score * mini(combo, 8) * dif.score / 10.0) * 10; score += pts
	popups.append({"x": e.x, "y": e.y - base.size, "text": "+" + str(pts), "t": 0.0})
	var blast := src == "explosion"
	corpses.append({"x": e.x, "y": e.y, "vx": rand(-260, 260) if blast else -signf(x - e.x) * rand(90, 160), "vy": -rand(520, 720) if blast else -rand(220, 320),
		"spin": rand(-12, 12) if blast else signf(e.x - x) * 3, "rot": 0.0, "size": float(base.size), "kind": e.kind, "life": 1.8 if blast else 1.2, "max": 1.8 if blast else 1.2,
		"style": src, "facing": e.facing, "settle": 0.0})
	burst(e.x, e.y - base.size * .4, 10 if src == "knife" else 14, "#ffc86a", 230)
	for i in range(4):
		particles.append({"x": e.x, "y": e.y - base.size * .4, "vx": rand(-200, 200), "vy": -rand(150, 380), "life": 1.0, "max": 1.0, "color": pick(["#ffbf49", "#f7e3a1", "#6fbf5a"]), "size": rand(4, 7), "kind": "debris", "spin": rand(-10, 10)})
	_sound("bigDie" if e.kind == "turret" or e.kind == "heavy" else "enemyDie")
	if e.kind == "turret" or e.kind == "heavy":
		explode(e.x, e.y - 50, 120, 0, "fx"); hitstop = .07
	elif combo >= 3: hitstop = maxf(hitstop, .025)
	if combo > 0 and combo % 5 == 0:
		callOut(str(combo) + " COMBO!", "", ""); _sound("combo")
	if randf() < (.6 if e.kind == "heavy" else .12): dropItem(e.x, e.y - 40, "ammo" if randf() < .5 else "medal")

# ---- bullets & explosions ----
func updateBullets(dt: float) -> void:
	var explosions := []
	for b in bullets:
		b.life -= dt; var old := {"x": b.x, "y": b.y}
		if b.kind in ["grenade", "lob", "honey", "shell2", "fire", "crate"]: b.vy += 950 * dt
		if b.kind == "spray": b.vy += 420 * dt
		if b.kind == "bomb": b.vy += 700 * dt
		b.x += b.vx * dt; b.y += b.vy * dt
		if b.kind == "rocket":
			b.vx *= 1 + dt * 1.2; b.vy *= 1 + dt * 1.2
			if randf() < .8: particles.append({"x": b.x, "y": b.y, "vx": -b.vx * .06, "vy": rand(-15, 15), "life": .45, "max": .45, "color": "#e7dbd6", "size": rand(6, 11), "kind": "smoke"})
		if b.kind == "grenade":
			b.spin += dt * 14
			if b.y >= 568:
				b.y = 568.0; b.vy *= -.45; b.vx *= .7; b.bounces += 1; _sound("bounce")
			if b.bounces >= 2 or b.life <= 0 or grenadeContact(old, b):
				explosions.append({"x": b.x, "y": b.y - 10, "r": 165.0, "dmg": 22.0, "owner": "player"}); b.life = 0.0
		if b.kind == "crate" and b.y >= FLOOR - 56:
			b.life = 0.0; addShake(.3); _sound("crate"); dust(b.x, FLOOR, 8)
			if absf(b.x - x) < 52 and y > FLOOR - 60: hurt()
			platforms.append({"x": b.x - 40, "base": b.x - 40, "y": FLOOR - 56.0, "w": 80.0, "h": 20.0, "type": "crate", "life": 9.0})
		if b.kind == "spray" and b.y >= 568:
			b.life = 0.0
			if randf() < .12: hazards.append({"x": b.x - 40, "y": 568.0, "w": 80.0, "h": 12.0, "kind": "puddle", "life": 4.0})
		if b.kind == "fire" and b.y >= 568:
			b.life = 0.0; explosions.append({"x": b.x, "y": b.y - 10, "r": 120.0, "dmg": 0.0, "owner": "enemy"}); hazards.append({"x": b.x - 55, "y": 568.0, "w": 110.0, "h": 12.0, "kind": "fire", "life": 5.0})
		if b.kind == "lob" or b.kind == "honey" or b.kind == "bomb" or b.kind == "shell2":
			if b.y >= 568:
				b.life = 0.0
				if b.kind == "honey":
					burst(b.x, b.y, 14, "#ffbf49", 220); hazards.append({"x": b.x - 50, "y": 568.0, "w": 100.0, "h": 12.0, "kind": "puddle", "life": 6.0})
					if absf(b.x - x) < 70: hurt()
				else: explosions.append({"x": b.x, "y": b.y - 10, "r": 110.0 if b.kind == "shell2" else 80.0, "dmg": 0.0, "owner": "enemy"})
		if b.kind == "wave":
			b.y = FLOOR - 14.0
			if randf() < .5: dust(b.x, FLOOR, 1)
		if b.friendly and b.kind != "grenade":
			for e in enemies:
				if e.hp <= 0 or b.hit.has(e.id): continue
				var s: float = ENEMIES[e.kind].size
				if intersects(old, b, {"x": e.x - s * .4, "y": e.y - s * .75, "w": s * .8, "h": s * .75}):
					var r = damageEnemy(e, b.damage, "shot", b); b.hit.append(e.id)
					spark(b.x, b.y, b.kind)
					if b.kind == "rocket": explosions.append({"x": b.x, "y": b.y, "r": 150.0, "dmg": 16.0, "owner": "player"})
					if (r is String and r == "block") or b.pierce <= 0:
						b.life = 0.0; break
					b.pierce -= 1
			if b.life > 0:
				for c in pows:
					if c.state == "caged" and intersects(old, b, {"x": c.x - 43, "y": c.y - 95, "w": 86, "h": 95}):
						damageCage(c, b.damage); spark(b.x, b.y, "cage"); b.life = 0.0; break
			if b.life > 0:
				for p in props:
					if p.hp > 0 and intersects(old, b, {"x": p.x - 28, "y": p.y - 56, "w": 56, "h": 56}):
						damageProp(p, b.damage); spark(b.x, b.y, "prop")
						if b.kind == "rocket": explosions.append({"x": b.x, "y": b.y, "r": 150.0, "dmg": 16.0, "owner": "player"})
						b.life = 0.0; break
			if b.life > 0 and boss != null and boss.started and not boss.dead and boss.state != "enter":
				for k in ["A", "B"]:
					if b.life > 0 and not boss.parts[k].dead and intersects(old, b, bossPartBox(k)):
						damageBossPart(k, b.damage); spark(b.x, b.y, "boss"); b.life = 0.0
						if b.kind == "rocket": explosions.append({"x": b.x, "y": b.y, "r": 150.0, "dmg": 10.0, "owner": "player"})
				if b.life > 0 and intersects(old, b, bossBox()):
					hitBossBody(b.damage); spark(b.x, b.y, "boss"); b.life = 0.0
					if b.kind == "rocket": explosions.append({"x": b.x, "y": b.y, "r": 150.0, "dmg": 10.0, "owner": "player"})
		elif not b.friendly and dying <= 0:
			var hh := 38.0 if crouch else 68.0; var box := {"x": x - 15, "y": y - hh, "w": 30, "h": hh}
			var hit: bool = (absf(b.x - x) < 26 and y > FLOOR - 30) if b.kind == "wave" else intersects(old, b, box)
			if hit:
				hurt()
				if b.kind != "wave":
					b.life = 0.0
					if b.kind in ["lob", "bomb", "shell2"]: explosions.append({"x": b.x, "y": b.y, "r": 80.0, "dmg": 0.0, "owner": "enemy"})
		if b.x < camera - 300 or b.x > camera + W + 400 or b.y < -400 or b.y > 780: b.life = 0.0
	bullets = bullets.filter(func(b): return b.life > 0)
	for p in explosions: explode(p.x, p.y, p.r, p.dmg, p.owner)

func spark(sx: float, sy: float, kind: String) -> void:
	particles.append({"x": sx, "y": sy, "vx": 0.0, "vy": 0.0, "life": .12, "max": .12, "color": "#fff8d0", "size": 18.0 if kind == "rocket" else 11.0, "kind": "flash"})
	burst(sx, sy, 3, "#fff1b7", 150)

func explode(ex: float, ey: float, r := 150.0, dmg := 22.0, owner := "player") -> void:
	blasts.append({"x": ex, "y": ey, "r": r, "t": 0.0, "max": .55})
	for i in range(8):
		particles.append({"x": ex + rand(-r * .3, r * .3), "y": ey + rand(-r * .3, r * .1), "vx": rand(-60, 60), "vy": -rand(30, 110), "life": rand(.7, 1.3), "max": 1.3, "color": "#c9bcb8", "size": rand(r * .12, r * .22), "kind": "smoke"})
	for i in range(6):
		particles.append({"x": ex, "y": ey, "vx": rand(-320, 320), "vy": -rand(200, 520), "life": 1.1, "max": 1.1, "color": pick(["#6b4b3f", "#8c6b55", "#ffbf49"]), "size": rand(4, 8), "kind": "debris", "spin": rand(-14, 14)})
	addShake(.55 if r > 140 else .35); _sound("explode" if r > 140 else "explodeSmall")
	if owner == "enemy":
		if Vector2(x - ex, y - 30 - ey).length() < r * .6: hurt()
		return
	if owner == "fx" or not dmg: return
	for e in enemies:
		if Vector2(e.x - ex, e.y - ENEMIES[e.kind].size * .4 - ey).length() < r: damageEnemy(e, dmg, "explosion")
	for c in pows:
		if c.state == "caged" and Vector2(c.x - ex, c.y - 40 - ey).length() < r: damageCage(c, 9)
	for p in props:
		if p.hp > 0 and Vector2(p.x - ex, p.y - 28 - ey).length() < r: damageProp(p, dmg)
	if boss != null and boss.started and not boss.dead and boss.state != "enter":
		for k in ["A", "B"]:
			var ph := bossPartBox(k)
			if not boss.parts[k].dead and ex > ph.x - r * .5 and ex < ph.x + ph.w + r * .5 and ey > ph.y - r * .5 and ey < ph.y + ph.h + r * .5: damageBossPart(k, dmg)
		var h := bossBox()
		if ex > h.x - r * .5 and ex < h.x + h.w + r * .5 and ey > h.y - r * .5 and ey < h.y + h.h + r * .5:
			hitBossBody(dmg); hitstop = maxf(hitstop, .04)

func addShake(n: float) -> void:
	shake = minf(1, maxf(shake, n))

func damageProp(p: Dictionary, n: float) -> void:
	if p.hp <= 0: return
	p.hp -= n; p.flash = .1
	if p.hp > 0:
		_sound("thud"); return
	score += 50
	if p.kind == "barrel": explode(p.x, p.y - 30, 170, 24, "player")
	else:
		_sound("crate")
		for i in range(8):
			particles.append({"x": p.x, "y": p.y - 30, "vx": rand(-240, 240), "vy": -rand(200, 450), "life": 1.0, "max": 1.0, "color": pick(["#c99152", "#a87444", "#f6ce86"]), "size": rand(6, 12), "kind": "debris", "spin": rand(-12, 12)})
		if randf() < .7: dropItem(p.x, p.y - 40, pick(["weapon", "medal", "food", "ammo"]))

func damageCage(c: Dictionary, n: float) -> void:
	if c.state != "caged": return
	c.hp -= n; c.flash = .1; _sound("thud")
	if c.hp <= 0:
		c.state = "tied"; _sound("crate")
		for i in range(10):
			particles.append({"x": c.x, "y": c.y - 50, "vx": rand(-240, 240), "vy": -rand(150, 400), "life": 1.0, "max": 1.0, "color": "#7d8b78", "size": rand(5, 9), "kind": "debris", "spin": rand(-12, 12)})

# ---- POWs (captured honeybees) & items ----
func updatePows(dt: float) -> void:
	for p in pows:
		p.t += dt
		if p.state == "thanks" and p.t > .55 and not p.dropped:
			p.dropped = true; dropItem(p.x + face * 10, p.y - 60, p.reward, p.weapon)
		if p.state == "thanks" and p.t > 1.3:
			p.state = "leave"; p.t = 0.0
		if p.state == "leave":
			p.x -= 260 * dt; p.y -= 140 * dt
	pows = pows.filter(func(p): return p.state != "leave" or p.t < 2.5)

func collectPows() -> void:
	for p in pows:
		if p.state == "tied" and absf(x - p.x) < 60 and absf(y - p.y) < 90:
			p.state = "thanks"; p.t = 0.0; rescued += 1; stageRescued += 1; score += roundi(1000 * dif.score)
			popups.append({"x": p.x, "y": p.y - 110, "text": "THANK YOU!", "t": 0.0, "big": true}); _sound("rescue"); _voice("Thank you!")
			for i in range(10):
				particles.append({"x": p.x, "y": p.y - 50, "vx": rand(-160, 160), "vy": -rand(120, 300), "life": .9, "max": .9, "color": pick(["#ffd8d9", "#fff2b6", "#bee9d0"]), "size": rand(3, 6), "kind": "spark"})

func dropItem(ix: float, iy: float, kind: String, w = null) -> void:
	if kind == "weapon" and w == null: w = randomWeapon()
	items.append({"x": ix, "y": iy, "vy": -260.0, "kind": kind, "weapon": w, "t": 0.0, "grounded": false, "life": 999.0 if kind == "weapon" or kind == "support" else 12.0})

func updateItems(dt: float) -> void:
	for it in items:
		it.t += dt; it.life -= dt
		if not it.grounded:
			it.vy += 1200 * dt; it.y += it.vy * dt
			var fl := float(FLOOR)
			for p in platforms:
				if it.x > p.x and it.x < p.x + p.w and it.y - it.vy * dt <= p.y + 2 and it.y >= p.y: fl = minf(fl, p.y)
			for h in hazards:
				if h.kind == "water" and it.x > h.x and it.x < h.x + h.w:
					fl = H + 100.0; break
			if it.y >= fl:
				it.y = fl; it.vy = 0.0; it.grounded = true
		if dying <= 0 and absf(x - it.x) < 48 and y - 90 < it.y and y + 10 > it.y - 40:
			takeItem(it); it.life = -1.0
	items = items.filter(func(it): return it.life > 0 and it.y < H + 50)

func takeItem(it: Dictionary) -> void:
	match it.kind:
		"weapon": giveWeapon(it.weapon)
		"bomb":
			grenades = mini(30, grenades + 10); callOut("BOMB +10", "수류탄 보충", "Bomb!"); _sound("pickup")
		"food":
			hp = mini(dif.hp, hp + 2); score += 500; popups.append({"x": it.get("x", x), "y": it.get("y", y) - 50, "text": "+500", "t": 0.0}); callOut("HONEY CHURRO!", "체력 회복", ""); _sound("food")
		"medal":
			score += 1000; popups.append({"x": it.get("x", x), "y": it.get("y", y) - 50, "text": "+1000", "t": 0.0}); _sound("medal")
		"ammo":
			if weapon != PISTOL: ammo[weapon] = mini(WEAPONS[weapon].ammo, ammo[weapon] + ceili(WEAPONS[weapon].ammo * .4))
			else: giveWeapon(randomWeapon())  # ammo with only the Glock in hand turns into a gun
			score += 100; _sound("pickup")
		"support":
			support = 22; supportTimer = 0; callOut("HONEY SUPPORT!", "22초 지원 사격", "Support!"); _sound("rescue")

func weaponPool() -> Array:
	var pool := []
	for i in range(stage + 1): pool.append_array(WEAPON_UNLOCK[i])
	return pool

func randomWeapon() -> int:
	return pick(weaponPool())

func giveWeapon(w: int) -> void:
	var had: bool = unlocked.has(w) and ammo[w] > 0
	if not unlocked.has(w): unlocked.append(w)
	var full: int = WEAPONS[w].ammo
	ammo[w] = -1 if full < 0 else (mini(full * 2, ammo[w] + full) if had else full)
	weapon = w; weaponPop = 1.2; muzzle = 0
	if w != PISTOL:
		callOut(WEAPONS[w].name + "!", WEAPONS[w].label, WEAPONS[w].call); _sound("weapon")

func updateSupport(dt: float) -> void:
	if support <= 0: return
	support -= dt; supportTimer -= dt
	if supportTimer < 0:
		supportTimer = .3
		var ox := x - face * 55; var oy := y - 95; var t = null
		for e in enemies:
			if e.hp > 0 and (e.x - x) * face > 0 and absf(e.x - x) < 650:
				t = e; break
		var a: float = atan2(t.y - 30 - oy, t.x - ox) if t != null else (.1 if face > 0 else PI - .1)
		addBullet(ox, oy, cos(a) * 900, sin(a) * 900, true, 3, "support")

# ---- player damage & death ----
func hurt(fall := false) -> void:
	if dying > 0 or mode != "play": return
	if (invincible > 0 or entering or knife > 0) and not fall: return  # brief i-frames during the melee swing
	hp -= 2 if fall else 1; stageHits += 1; invincible = 1.6; hurtTimer = .3; addShake(.5); combo = 0; _sound("hurt")
	burst(x, y - 40, 12, "#ffafc3", 200)
	if fall:
		respawnPoint(); y = -40; vy = 0
	elif hp > 0:
		vx = -face * 240; vy = minf(vy, -220); grounded = false
	if hp <= 0:
		hp = 0; lives -= 1; dying = 1.4; vx = -face * 160; vy = -420; _sound("die")
		if weapon != PISTOL:
			ammo[weapon] = 0; var w := weapon; unlocked = unlocked.filter(func(u): return u != w); weapon = PISTOL

## Respawns drop in from the top-left of the current screen (past open water and anything the lock walls off).
func respawnPoint() -> void:
	var rx: float = camera + 140
	if lock != null and lock.has("left"): rx = maxf(rx, lock.left + 60)
	for i in range(40):
		var wet := false
		for h in hazards:
			if h.kind == "water" and rx > h.x - 30 and rx < h.x + h.w + 30: wet = true
		if not wet: break
		rx += 30
	x = rx; vx = 0

func respawn() -> void:
	hp = dif.hp; respawnPoint(); y = -60; vy = 200; dying = 0; invincible = 3; grenades = maxi(grenades, GRENADE_FLOOR); hurtTimer = 0; toast("다시 출동! · 남은 목숨 %d" % lives)

# ---- bosses ----
# Bosses are rigs of parts (BOSS_RIG): a body plus weapon A/B with their own HP, and a hatch that releases troops and supply bees.
# Pattern 0 fires weapon A, 1 weapon B, 2 is the body's own move; a destroyed weapon's pattern is skipped.
# A rig with "left": true sits on the left of the arena mirrored to face right (boss.flip). The renderer draws the rig
# inside a mirrored transform, so it asks for raw (unmirrored) points; gameplay always uses world points.
func bossSign(raw := false) -> float:
	return -1.0 if boss.get("flip", false) and not raw else 1.0

## Direction the boss faces: -1 (left, the default) or 1 for a flipped boss.
func bossFwd() -> float:
	return 1.0 if boss.get("flip", false) else -1.0

func bossBodyPt(u: float, v: float, raw := false) -> Dictionary:
	var b: Dictionary = boss; var r: Dictionary = BOSS_RIG[b.type]; var S: float = 512.0 * r.k
	return {"x": b.x + (u - .5) * S * bossSign(raw), "y": b.y + (v - r.base) * S}

func bossPartPt(pname: String, cu: float, cv: float, raw := false) -> Dictionary:
	var b: Dictionary = boss; var r: Dictionary = BOSS_RIG[b.type]; var P: Dictionary = r[pname]; var S: float = 512.0 * r.k
	var pv := bossBodyPt(P.u, P.v, raw); var a: float = float(b.parts[pname].ang) + float(P.get("rot", 0.0))
	var dx: float = (cu - P.pu) * S * P.ps; var dy: float = (cv - P.pv) * S * P.ps
	return {"x": pv.x + (dx * cos(a) - dy * sin(a)) * bossSign(raw), "y": pv.y + dx * sin(a) + dy * cos(a)}

func bossPartBox(pname: String, raw := false) -> Dictionary:
	var b: Dictionary = boss; var r: Dictionary = BOSS_RIG[b.type]; var P: Dictionary = r[pname]; var S: float = 512.0 * r.k * P.ps
	var pv := bossBodyPt(P.u, P.v, raw); var q: Array = P.box
	var l: float = (q[0] / 512.0 - P.pu) * S if bossSign(raw) > 0 else -(q[2] / 512.0 - P.pu) * S
	return {"x": pv.x + l, "y": pv.y + (q[1] / 512.0 - P.pv) * S, "w": (q[2] - q[0]) / 512.0 * S, "h": (q[3] - q[1]) / 512.0 * S}

func bossMuzzle(pname: String, raw := false) -> Dictionary:
	var P: Dictionary = BOSS_RIG[boss.type][pname]
	return bossPartPt(pname, P.mu, P.mv, raw)

func bossBox() -> Dictionary:
	var b: Dictionary = boss; var r: Dictionary = BOSS_RIG[b.type]; var S: float = 512.0 * r.k; var q: Array = r.box
	var l: float = (q[0] / 512.0 - .5) * S if bossSign() > 0 else -(q[2] / 512.0 - .5) * S
	return {"x": b.x + l, "y": b.y + (q[1] / 512.0 - r.base) * S, "w": (q[2] - q[0]) / 512.0 * S, "h": (q[3] - q[1]) / 512.0 * S}

## Clamp an x into the open floor in front of the boss (crates, supply drops).
func bossFrontClamp(px: float, margin: float, edge: float) -> float:
	var h := bossBox()
	if boss.get("flip", false): return clampf(px, h.x + h.w + margin, camera + W - edge)
	return clampf(px, camera + edge, h.x - margin)

func bossHalf() -> float:
	var r: Dictionary = BOSS_RIG[boss.type]
	return (r.box[2] - r.box[0]) / 1024.0 * 512.0 * r.k

func startBoss() -> void:
	var type: String = level.boss; var c: Dictionary = BOSSES[type]; var r: Dictionary = BOSS_RIG[type]; var len: float = STAGES[stage].length
	var bhp := float(roundi(c.hp * (1.25 if difficulty == "hard" else (.8 if difficulty == "easy" else 1.0))))
	var flip: bool = r.get("left", false)
	var home: float = len - W + r.home if flip else len - r.home
	var parts := {}
	for k in ["A", "B"]:
		var php := float(roundi(bhp * r[k].hp))
		parts[k] = {"hp": php, "max": php, "dead": false, "flash": 0.0, "recoil": 0.0, "ang": 0.0}
	boss = {"type": type, "started": true, "x": home, "home": home, "y": float(FLOOR), "hp": bhp, "max": bhp, "active": true, "dead": false, "t": 0.0, "phase": 1, "flash": 0.0,
		"warn": false, "pattern": 0, "state": "enter", "clock": 2.6, "recoil": 0.0, "track": 0.0, "vx": 0.0, "vy": 0.0, "air": false, "shots": 0, "sweep": null, "zones": [],
		"aimX": null, "aimY": null, "burst": false, "parts": parts, "hatch": {"clock": 7.0, "open": 0.0, "released": false, "count": 0}, "charge": 0, "chargeDir": 0,
		"sink": 0.0, "landed": false, "crashed": false, "flip": flip}
	var b: Dictionary = boss
	if type == "king":
		b.y = FLOOR - 900.0; b.air = true
	elif type == "boat": b.y = FLOOR + 420.0
	else: b.x = len + 420
	if flip: lock = {"zone": null, "cam": len - W, "right": len, "left": home + bossHalf() - 40}
	else: lock = {"zone": null, "cam": len - W, "right": home - bossHalf() + 40}
	# Harbor: the ship casts off — open sea opens up behind it, where the landing ship surfaces.
	if ship != null:
		ship.sea = {"x": ship.x, "y": 571.0, "w": 0.0, "h": 150.0, "kind": "water", "sea": true}; hazards.append(ship.sea)
		lock.left = ship.x - 10
	callOut("WARNING!", c.title + " · " + c.name, "Warning! Big tank approaching!" if type == "tank" else "Warning! Boss approaching!")
	_sound("warning"); addShake(.4)

func bossEnter(dt: float) -> void:
	var b: Dictionary = boss; var len: float = STAGES[stage].length
	match b.type:
		"king":  # drops from the sky and slams down
			if b.air:
				b.vy += 1900 * dt; b.y += b.vy * dt
				if b.y >= FLOOR:
					b.y = float(FLOOR); b.air = false; b.vy = 0.0; b.landed = true; addShake(1); _sound("slam"); dust(b.x, FLOOR, 26); dust(b.x - 160, FLOOR, 10); dust(b.x + 160, FLOOR, 10)
					for p in platforms: p.shake = .8
		"cannon":  # rams in from the right through the factory wall
			b.x += (b.home - b.x) * (1 - exp(-dt * 3)); addShake(.14)
			if not b.crashed and b.x < len + 120:
				b.crashed = true; explode(len - 40, FLOOR - 160, 190, 0, "fx")
				for i in range(18):
					particles.append({"x": len - 30, "y": FLOOR - rand(20, 320), "vx": -rand(120, 520), "vy": -rand(80, 420), "life": 1.6, "max": 1.6, "color": pick(["#b98b5a", "#8a6a4a", "#d8c0a0"]), "size": rand(10, 22), "kind": "debris", "spin": rand(-10, 10)})
		"boat":  # rises out of the water
			var k: float = maxf(0, b.clock) / 2.6; b.y = FLOOR + 420 * k * k
			if randf() < .5: particles.append({"x": b.x + rand(-280, 280), "y": FLOOR - 4.0, "vx": rand(-90, 90), "vy": -rand(160, 380), "life": .8, "max": .8, "color": "#e9fbff", "size": rand(5, 10), "kind": "spark"})
		_:  # rolls in, crushing what's in its way
			b.x += (b.home - b.x) * (1 - exp(-dt * 2.4)); addShake(.12)
			for p in props:
				var h := bossBox()
				if p.hp > 0 and p.x > h.x and p.x < h.x + h.w: damageProp(p, 99)
	if b.clock <= 0:
		b.x = b.home; b.y = float(FLOOR); b.air = false; b.vy = 0.0; b.state = "idle"; b.clock = 1.0

func updateBoss(dt: float) -> void:
	var b = boss
	if b == null or not b.started or b.get("dead", false): return
	var track_x: float = b.x; var grounded: bool = not b.air
	b.t += dt; b.clock -= dt; b.flash = maxf(0, b.flash - dt); b.recoil = maxf(0, b.recoil - dt * 3)
	b.warn = b.state == "windup"
	for p in platforms:
		if p.get("shake", 0.0) > 0: p.shake = maxf(0, p.shake - dt)
	for k in ["A", "B"]:
		var pt: Dictionary = b.parts[k]; pt.flash = maxf(0, pt.flash - dt); pt.recoil = maxf(0, pt.recoil - dt * 3)
	if ship != null and ship.has("sea"):
		ship.sail = float(ship.get("sail", 0.0)) + SHIP_SPEED * dt * minf(1, b.t / 2.2)  # scenery scroll (eases in as it casts off)
		var open := minf(1, b.t / 2.2); ship.sea.x = ship.x - SHIP_SEA * open; ship.sea.w = SHIP_SEA * open
	if b.state == "enter":
		bossEnter(dt)
		if grounded: b.track += b.x - track_x
		return
	if b.phase == 1 and (b.hp < b.max * .5 or (b.parts.A.dead and b.parts.B.dead)): bossRage()
	if b.air:
		b.vy += 1600 * dt; b.y += b.vy * dt; b.x += b.vx * dt
		if b.y >= FLOOR:
			b.y = float(FLOOR); b.air = false; b.vy = 0.0; bossLand()
	var fast: bool = b.phase == 2
	bossAim(dt)
	if b.charge: bossChargeStep(dt)
	if b.state == "idle":
		if not b.air and not b.charge:
			if b.type == "king": b.x += (b.home - b.x) * minf(1, dt * 1.5)
			elif b.type != "boat": b.x = b.home + sin(b.t * 1.2) * 12
		if b.clock <= 0:
			if b.pattern != 2 and b.parts["A" if b.pattern == 0 else "B"].dead: bossNextPattern()
			b.state = "windup"; b.clock = .75 if fast else 1.0; planBoss(); _sound("charge")
	elif b.state == "windup" and b.clock <= 0:
		b.state = "attack"; b.clock = 1.0 if fast else 1.25; b.shots = 0; bossAttack()
	elif b.state == "attack":
		bossSustain(dt)
		if b.clock <= 0 and not b.air and not b.charge and b.sweep == null:
			b.state = "recover"; b.clock = .6
	elif (b.state == "recover" or b.state == "break") and b.clock <= 0:
		bossNextPattern(); b.state = "idle"; b.clock = .5 if fast else 1.05
	if b.type == "boat": b.y = FLOOR + sin(b.t * 1.6) * 6
	updateHatch(dt)
	if grounded: b.track += b.x - track_x
	var h := bossBox()
	if b.flip: pass
	elif b.type != "king" or not b.air: lock.right = minf(STAGES[stage].length, b.x - bossHalf() + 40)
	if dying <= 0 and overlap({"x": x - 14, "y": y - 68, "w": 28, "h": 68}, {"x": h.x + 30, "y": h.y + h.h * .35, "w": h.w - 60, "h": h.h * .65}): hurt()

func bossNextPattern() -> void:
	var b: Dictionary = boss
	for i in range(3):
		b.pattern = (b.pattern + 1) % 3
		if b.pattern == 2 or not b.parts["A" if b.pattern == 0 else "B"].dead: return
	b.pattern = 2

# Guns track the player smoothly within their arc.
func bossAim(dt: float) -> void:
	var b: Dictionary = boss
	for k in ["A", "B"]:
		var p: Dictionary = b.parts[k]; var P: Dictionary = BOSS_RIG[b.type][k]
		if p.dead or not P.has("aim"): continue
		var pv := bossBodyPt(P.u, P.v); var locked: bool = b.state == "attack" and b.pattern == (0 if k == "A" else 1) and b.aimX != null
		var tx: float = b.aimX if locked else x; var ty: float = b.aimY if locked else y
		var raw: float = atan2(ty - 50 - pv.y, (tx - pv.x) * bossSign()) - PI
		var norm: float = fposmod(raw + PI, TAU) - PI
		var target: float = clampf(norm, -P.aim, P.aim)
		p.ang += clampf(target - p.ang, -dt * 1.6, dt * 1.6)

func bossRage() -> void:
	var b: Dictionary = boss
	b.phase = 2; b.state = "break"; b.clock = 1.3; b.sweep = null; b.charge = 0; addShake(.8); hitstop = .12
	for i in range(14):
		particles.append({"x": b.x + rand(-200, 170), "y": b.y - rand(60, 260), "vx": rand(-260, 220), "vy": rand(-420, -120), "life": 1.8, "max": 1.8, "color": "#8c9b70", "size": rand(14, 26), "kind": "armor", "spin": rand(-8, 8)})
	explode(b.x + bossFwd() * 40, b.y - 200, 170, 0, "fx"); callOut("ARMOR BREAK!", "코어 노출 · 공격이 거세진다!", ""); _sound("alarm")
	b.hatch.clock = minf(b.hatch.clock, 2.5)

func bossMouth() -> Dictionary:
	var b: Dictionary = boss
	if b.pattern == 2 or b.parts["A" if b.pattern == 0 else "B"].dead:
		var core: Array = BOSS_RIG[b.type].core
		return bossBodyPt(core[0], core[1])
	return bossMuzzle("A" if b.pattern == 0 else "B")

func _bossLob(m: Dictionary, kind: String, tx: float, t: float) -> Dictionary:
	var bl := addBullet(m.x, m.y, (tx - m.x) / t, (FLOOR - 8 - m.y - .5 * 950 * t * t) / t, false, 1, kind); bl.life = 4.0
	return bl

func bossAttack() -> void:
	var b: Dictionary = boss; var fast: bool = b.phase == 2
	var ax: float = b.aimX if b.aimX != null else x; var ay: float = b.aimY if b.aimY != null else y
	b.recoil = 1.0; addShake(.25); _sound("bossFire")
	if b.pattern < 2: b.parts["A" if b.pattern == 0 else "B"].recoil = 1.0
	var m := bossMouth()
	match b.type + str(b.pattern):
		"king0", "tank1": b.sweep = 0.0  # chin guns burst / gatling sweep
		"king1":  # missile volley
			var n := 6 if fast else 4
			for i in range(n): _bossLob(m, "lob", ax + (i - (2.5 if fast else 1.5)) * 95, 1 + i * .1)
		"king2":  # jump stomp
			b.air = true; b.vy = -860.0; b.vx = clampf((maxf(ax + 170, b.home - 520) - b.x) / 1.075, -520, 120); _sound("jump")
		"cannon0":  # honey mortar
			for i in range(6 if fast else 4): _bossLob(m, "honey", ax + (i - (2.5 if fast else 1.5)) * 90, 1 + i * .12)
		"cannon1": b.sweep = 0.0  # flamethrower
		"cannon2", "tank2":  # ram / advance
			b.charge = 1; b.chargeDir = -1; _sound("charge")
		"boat0":  # deck guns
			for i in range(5 if fast else 3): _bossLob(m, "shell2", ax + (i - (2.0 if fast else 1.0)) * 120, 1.1 + i * .15)
		"boat1":  # crane drops crates (and a soldier)
			var cm := bossMuzzle("B")
			for i in range(3 if fast else 2):
				var cx: float = bossFrontClamp(ax + (i - (1.0 if fast else .5)) * 150, 60, 80)
				var bl := addBullet(cx, -60 - i * 80, 0, 120, false, 1, "crate"); bl.life = 4.0
			if enemies.filter(func(e): return e.hp > 0).size() < 5:
				var e := spawnEnemy(cm.x, cm.y, "grunt"); e.launch = 1.5; e.vx = bossFwd() * 180; e.vy = -200.0; e.alert = 1; e.arena = true
		"boat2":  # landing party
			for i in range(4 if fast else 3):
				var e := spawnEnemy(b.x + bossFwd() * (120 + i * 30), b.y - 180, "hopper"); e.launch = 1.6; e.vx = bossFwd() * (260 + i * 90); e.vy = -420.0 - i * 50; e.alert = 1
		"tank0":  # main cannon fire shells
			for i in range(2 if fast else 1):
				var bl := _bossLob(m, "fire", ax + i * 140, 1.15 + i * .2); bl.life = 5.0

# Lock the attack target when the windup starts and describe the danger zones so the renderer can telegraph them.
func planBoss() -> void:
	var b: Dictionary = boss; var m := bossMouth(); var fast: bool = b.phase == 2; var zs := []
	b.aimX = x; b.aimY = y
	var aimA := atan2(y - 40 - m.y, x - m.x)
	var h := bossBox()
	var land := func(lx: float, ly: float, lvx: float, lvy: float, gr: float) -> float:
		var a := .5 * gr; var t := (-lvy + sqrt(lvy * lvy + 4 * a * maxf(0, FLOOR - 8 - ly))) / (2 * a)
		return lx + lvx * t
	match b.type + str(b.pattern):
		"king0": zs.append({"kind": "cone", "x": m.x, "y": m.y, "angle": aimA, "spread": .4, "r": 1500.0})
		"king1":
			for i in range(6 if fast else 4): zs.append({"kind": "spot", "x": x + (i - (2.5 if fast else 1.5)) * 95, "r": 70.0})
		"king2":
			var lx: float = b.x + clampf((maxf(x + 170, b.home - 520) - b.x) / 1.075, -520, 120) * 1.075
			zs.append({"kind": "spot", "x": lx, "r": 150.0}); zs.append({"kind": "lane", "x": lx - 120, "dir": -1}); zs.append({"kind": "lane", "x": lx + 120, "dir": 1})
		"cannon0":
			for i in range(6 if fast else 4): zs.append({"kind": "spot", "x": x + (i - (2.5 if fast else 1.5)) * 90, "r": 70.0})
		"cannon1": zs.append({"kind": "cone", "x": m.x, "y": m.y, "angle": PI + .12, "spread": .5, "r": 520.0})
		"cannon2", "tank2": zs.append({"kind": "lane", "x": h.x, "dir": -1})
		"boat0":
			for i in range(5 if fast else 3): zs.append({"kind": "spot", "x": x + (i - (2.0 if fast else 1.0)) * 120, "r": 80.0})
		"boat1":
			for i in range(3 if fast else 2): zs.append({"kind": "drop", "x": bossFrontClamp(x + (i - (1.0 if fast else .5)) * 150, 60, 80)})
		"boat2":
			for i in range(4 if fast else 3): zs.append({"kind": "drop", "x": land.call(b.x + bossFwd() * (120 + i * 30), b.y - 180, bossFwd() * (260 + i * 90), -420.0 - i * 50, 1250.0)})
		"tank0":
			for i in range(2 if fast else 1): zs.append({"kind": "spot", "x": x + i * 140, "r": 90.0})
		"tank1": zs.append({"kind": "cone", "x": m.x, "y": m.y, "angle": PI - .25, "spread": .9, "r": 1500.0})
	b.zones = zs

func bossSustain(dt: float) -> void:
	var b: Dictionary = boss
	if b.sweep == null: return
	b.sweep += dt; var fast: bool = b.phase == 2; var s: float = dif.bullet
	if b.type == "cannon":  # flamethrower: short-range spray of honey globs
		var fm := bossMuzzle("B"); var every := .035 if fast else .05; var mx := 34 if fast else 24
		while b.shots * every < b.sweep and b.shots < mx:
			var a := PI + .12 + rand(-.25, .25); var sp := rand(380, 520) * s
			var bl := addBullet(fm.x, fm.y, cos(a) * sp, sin(a) * sp, false, 1, "spray"); bl.life = rand(.8, 1.05); b.shots += 1
		b.parts.B.recoil = .5
		if b.shots >= mx: b.sweep = null
		return
	var k := "A" if b.type == "king" else "B"; var m := bossMuzzle(k); var every2 := .07 if fast else .1; var total := 14 if fast else 10
	while b.shots * every2 < b.sweep and b.shots < total:
		var t: float = float(b.shots) / (total - 1)
		var tax: float = b.aimX if b.aimX != null else x; var tay: float = b.aimY if b.aimY != null else y
		var a: float = atan2(tay - 40 - m.y, tax - m.x) + sin(t * 6) * .1 if b.type == "king" else PI + .5 - t * 1.0
		var sp2: float = 330 * s
		addBullet(m.x, m.y, cos(a) * sp2, sin(a) * sp2, false, 1, "enemy"); b.shots += 1; b.parts[k].recoil = .6; _sound("enemyShot")
	if b.shots >= total: b.sweep = null

# Ram (cannon train) / advance (tank): drive at the player, then back off to home.
func bossChargeStep(dt: float) -> void:
	var b: Dictionary = boss; var stop: float = b.home - (420 if b.phase == 2 else 330)
	if b.chargeDir < 0:
		b.x -= (520 if b.phase == 2 else 400) * dt; addShake(.1)
		if randf() < .4: dust(b.x + bossHalf() * .6, FLOOR, 1)
		if b.type == "tank" and b.phase == 2 and randf() < dt * 1.2 and enemies.filter(func(e): return e.hp > 0).size() < 5:
			var m := bossMuzzle("A"); var e := spawnEnemy(m.x, m.y, "hopper"); e.launch = 1.4; e.vx = -240.0; e.vy = -300.0; e.alert = 1
		if b.x <= stop:
			b.x = stop; b.chargeDir = 1; addShake(.4); _sound("slam")
	else:
		b.x += 200 * dt
		if b.x >= b.home:
			b.x = b.home; b.charge = 0; b.chargeDir = 0

func bossLand() -> void:
	var b: Dictionary = boss
	addShake(.7); _sound("slam"); dust(b.x, FLOOR, 18)
	for p in platforms: p.shake = .6
	for dir in [-1, 1]: addBullet(b.x + dir * 120, FLOOR - 14, dir * 360 * dif.bullet, 0, false, 1, "wave")
	if b.phase == 2:
		for dir in [-1, 1]: addBullet(b.x + dir * 120, FLOOR - 14, dir * 250 * dif.bullet, 0, false, 1, "wave")

# Hatch: every so often it pops open and releases soldiers, and (every other time, or when the player runs low) a supply bee.
func updateHatch(dt: float) -> void:
	var b: Dictionary = boss; var hc: Dictionary = b.hatch
	hc.clock -= dt
	if hc.open > 0: hc.open -= dt
	if hc.clock <= 0 and b.state != "break":
		hc.clock = 7.0 if b.phase == 2 else 10.0; hc.open = 1.6; hc.released = false; _sound("alarm")
	if hc.open > 0 and hc.open < 1.1 and not hc.released:
		hc.released = true; hc.count += 1
		var P: Dictionary = BOSS_RIG[b.type].H; var o := bossBodyPt(P.u, P.v)
		var kinds: Array = {"king": ["grunt", "hopper"], "cannon": ["bomber", "grunt"], "boat": ["hopper", "grunt"], "tank": ["grunt", "heavy"]}[b.type]
		var n := 2 if b.phase == 2 else 1
		if enemies.filter(func(e): return e.hp > 0).size() < 6:
			for i in range(n):
				var e := spawnEnemy(o.x + bossFwd() * 20, o.y - 30, kinds[(hc.count + i) % 2]); e.launch = 1.6; e.vx = bossFwd() * (200 + i * 110); e.vy = -420.0 - i * 60; e.alert = 1
		var low: bool = grenades == 0 or hp < dif.hp * .6 or weapon == PISTOL
		if hc.count % 2 == 1 or low: releaseSupply(o.x, o.y - 40)

func releaseSupply(sx: float, sy: float) -> void:
	var item := "bomb" if grenades == 0 else ("food" if hp < dif.hp else ("weapon" if weapon == PISTOL else "ammo"))  # bombs only when out
	var tx: float = bossFrontClamp(x + rand(-80, 80), 90, 120)
	supplies.append({"x": sx, "y": sy, "tx": tx, "ty": rand(200, 250), "item": item, "weapon": randomWeapon() if item == "weapon" else null, "t": 0.0, "state": "fly", "dropped": false})
	popups.append({"x": sx, "y": sy - 30, "text": "보급!", "t": 0.0}); _sound("rescue")

func updateSupplies(dt: float) -> void:
	for s in supplies:
		s.t += dt
		if s.state == "fly":
			var dx: float = s.tx - s.x; var dy: float = s.ty - s.y; var d := sqrt(dx * dx + dy * dy); var sp := 280 * dt
			if d <= sp + 2:
				s.x = s.tx; s.y = s.ty; s.state = "drop"; s.t = 0.0
			else:
				s.x += dx / d * sp; s.y += dy / d * sp
		elif s.state == "drop":
			if not s.dropped and s.t > .25:
				s.dropped = true; dropItem(s.x, s.y + 20, s.item, s.weapon)
			if s.t > .6:
				s.state = "leave"; s.t = 0.0
		else:
			s.x -= 220 * dt; s.y -= 180 * dt
	supplies = supplies.filter(func(s): return s.state != "leave" or s.t < 2.5)

# A grenade goes off the moment it touches a live enemy or the boss.
func grenadeContact(old: Dictionary, b: Dictionary) -> bool:
	for e in enemies:
		var s: float = ENEMIES[e.kind].size
		if e.hp > 0 and intersects(old, b, {"x": e.x - s * .4, "y": e.y - s * .75, "w": s * .8, "h": s * .75}): return true
	return boss != null and boss.started and not boss.dead and boss.state != "enter" and intersects(old, b, bossBox())

# Weapons have their own HP (not shown on screen): shooting one off ends its attack and chips the core.
func damageBossPart(pname: String, n: float) -> void:
	var b = boss
	if b == null or not b.started or b.get("dead", false) or b.state == "enter": return
	var p: Dictionary = b.parts[pname]
	if p.dead: return
	p.hp -= n; p.flash = .06; score += 5
	if p.hp <= 0:
		p.hp = 0.0; p.dead = true; var m := bossPartBox(pname)
		explode(m.x + m.w / 2, m.y + m.h / 2, 170, 0, "fx"); hitstop = .08; score += roundi(1500 * dif.score)
		popups.append({"x": m.x + m.w / 2, "y": m.y, "text": "+" + str(roundi(1500 * dif.score)), "t": 0.0, "big": true})
		bossDebris(m.x + m.w / 2, m.y + m.h / 2, 6)
		callOut("WEAPON DESTROYED!", BOSS_RIG[b.type].nameA if pname == "A" else BOSS_RIG[b.type].nameB, "")
		b.hp = maxf(1, b.hp - roundi(b.max * .1))
		if (b.pattern == 0 and pname == "A") or (b.pattern == 1 and pname == "B"):
			b.sweep = null
			if b.state == "windup" or b.state == "attack":
				b.state = "recover"; b.clock = .4

# Body hits: armored (30%) while either weapon still works; the exposed core in phase 2 takes full damage.
func hitBossBody(n: float) -> void:
	var b: Dictionary = boss
	damageBoss(n * .3 if b.phase == 1 and (not b.parts.A.dead or not b.parts.B.dead) else n)

func bossDebris(dx: float, dy: float, n: int) -> void:
	for i in range(n):
		particles.append({"x": dx + rand(-30, 30), "y": dy + rand(-30, 30), "vx": rand(-360, 260), "vy": -rand(260, 620), "life": 1.8, "max": 1.8, "color": "#6b4b3f", "size": rand(34, 56), "kind": "bossdebris", "chunk": i % 4, "sheet": BOSS_RIG[boss.type].sheet, "spin": rand(-8, 8)})

func damageBoss(n: float) -> void:
	var b = boss
	if b == null or not b.started or b.get("dead", false) or b.state == "enter": return
	b.hp -= n; b.flash = .06; score += 5
	if b.hp <= 0:
		b.hp = 0.0; b.dead = true; b.active = false; b.sink = 0.0; b.sweep = null; b.charge = 0; var c: Dictionary = BOSSES[b.type]; score += roundi(c.score * dif.score)
		for k in ["A", "B"]:
			if not b.parts[k].dead:
				b.parts[k].dead = true; var m := bossPartBox(k); bossDebris(m.x + m.w / 2, m.y + m.h / 2, 3)
		for bl in bullets:
			if not bl.friendly: bl.life = 0.0
		for e in enemies:
			if e.hp > 0:
				e.hp = 0.0
				corpses.append({"x": e.x, "y": e.y, "vx": rand(-260, 260), "vy": -rand(500, 700), "spin": rand(-12, 12), "rot": 0.0, "size": float(ENEMIES[e.kind].size), "kind": e.kind, "life": 1.8, "max": 1.8, "style": "explosion", "facing": e.facing, "settle": 0.0})
		enemies = []; spawnQueue = []; hitstop = .25; addShake(1); _sound("bossDie")
		# MISSION COMPLETE waits until the wreck has finished blowing apart (see updateCelebrate).
		mode = "celebrate"; celebrate = CELEBRATE_TIME; chain = 0; callout = null; save()

func updateCelebrate(dt: float) -> void:
	celebrate -= dt; chain -= dt; shake = maxf(0, shake - dt * 1.2)
	# A win mid-jump still lands first; the victory dance only starts on the ground.
	if not grounded and dying <= 0:
		var oldY := y
		vy = minf(1100, vy + 1650 * dt); vx *= .9; x += vx * dt; y += vy * dt
		for p in platforms:
			if x > p.x - 12 and x < p.x + p.w + 12 and oldY <= p.y + 3 and y >= p.y and vy >= 0:
				y = p.y; grounded = true
		if y >= FLOOR:
			y = FLOOR; grounded = true
		if grounded:
			vy = 0; vx = 0; dust(x, y, 8); landed = .12
	if callout != null: callout.t = minf(callout.t + dt * .5, 1.2)
	var b: Dictionary = boss
	b.sink = minf(1, b.get("sink", 0.0) + dt / 3.2); b.t += dt
	if celebrate > CELEBRATE_BURST - .2 and chain <= 0:
		chain = .16; var h := bossBox(); explode(h.x + rand(0, h.w), h.y + rand(0, h.h), rand(90, 170), 0, "fx"); shake = minf(shake, .35)  # chain blasts rumble gently; the final burst still jolts
	if celebrate <= CELEBRATE_CALLOUT and not b.get("cleared", false):
		b.cleared = true; callOut("MISSION COMPLETE!", "", "Mission complete!")
	if celebrate <= CELEBRATE_BURST and not b.get("burst", false):
		b.burst = true; explode(b.x, b.y - 150, 260, 0, "fx"); addShake(1); bossDebris(b.x, b.y - 150, 8)
		for i in range(40):
			particles.append({"x": b.x + rand(-180, 120), "y": b.y + rand(-200, -70), "vx": rand(-420, 300), "vy": rand(-650, -150), "life": 3.0, "max": 3.0, "color": "#fff", "size": rand(20, 36), "kind": "fish", "spin": rand(-8, 8)})
	updateFx(dt)
	if celebrate <= 0: finishStage()

func finishStage() -> void:
	var t := floori(stageTime); var par: int = level.par
	var rows := [
		{"label": "허니비 구출", "detail": "%d × 1000" % stageRescued, "value": stageRescued * 1000},
		{"label": "처치한 과메기", "detail": "%d × 50" % stageKills, "value": stageKills * 50},
		{"label": "클리어 시간", "detail": "%d:%02d" % [floori(t / 60.0), t % 60], "value": maxi(0, par - t) * 20},
		{"label": "노 데미지", "detail": ("피격 %d회" % stageHits) if stageHits else "PERFECT!", "value": 0 if stageHits else 5000}]
	var bonus := 0
	for r in rows: bonus += r.value
	var total := stageRescued + (0 if stageHits else 2) + (1 if t < par else 0)
	score += bonus; save()
	result = {"rows": rows, "bonus": bonus, "rank": "S" if total >= 6 else ("A" if total >= 4 else ("B" if total >= 2 else "C")), "t": 0.0}
	mode = "result"; _sound("result")

# ---- particles & effects ----
func updateFx(dt: float) -> void:
	for p in particles:
		p.life -= dt; p.x += p.vx * dt; p.y += p.vy * dt
		if p.kind == "smoke":
			p.vy -= 20 * dt; p.vx *= .98; p.size += dt * 14
		elif p.kind != "flash":
			p.vy += (700 if p.kind == "fish" else 900) * dt
			if (p.kind == "casing" or p.kind == "debris") and p.y > FLOOR - 2 and p.vy > 0:
				p.y = FLOOR - 2.0; p.vy *= -.35; p.vx *= .6
		if p.get("spin", 0): p.rot = p.get("rot", 0.0) + p.spin * dt
	particles = particles.filter(func(p): return p.life > 0)
	if particles.size() > 320: particles = particles.slice(particles.size() - 320)
	for c in corpses:
		c.life -= dt; c.vy += 1300 * dt; c.x += c.vx * dt; c.y += c.vy * dt; c.rot += c.spin * dt
		if c.y >= FLOOR and c.vy > 0:
			c.y = float(FLOOR); c.vy *= -.25; c.vx *= .5; c.spin *= .4
			if c.style != "explosion" and absf(c.vy) < 80:
				c.vy = 0.0; c.spin = 0.0
		# Ease into the knocked-out pose instead of snapping, so the body never visibly pops in size.
		if c.vy == 0:
			c.settle = minf(1, c.get("settle", 0.0) + dt * 6); c.rot += (0 - c.rot) * minf(1, dt * 10)
	corpses = corpses.filter(func(c): return c.life > 0)
	for b in blasts: b.t += dt
	blasts = blasts.filter(func(b): return b.t < b.max)
	for p in popups: p.t += dt
	popups = popups.filter(func(p): return p.t < (1.4 if p.get("big", false) else .9))
	for p in props: p.flash = maxf(0, p.flash - dt)
	for p in pows: p.flash = maxf(0, p.get("flash", 0.0) - dt)
	for h in hazards:
		if h.has("life"): h.life -= dt
	hazards = hazards.filter(func(h): return not h.has("life") or h.life > 0)
	for p in platforms:
		if p.has("life"): p.life -= dt
	platforms = platforms.filter(func(p): return not p.has("life") or p.life > 0)

func burst(bx: float, by: float, count: int, color: String, speed: float) -> void:
	for i in range(count):
		var a := rand(0, PI * 2); var s := rand(speed * .3, speed); var life := rand(.2, .6)
		particles.append({"x": bx, "y": by, "vx": cos(a) * s, "vy": sin(a) * s, "life": life, "max": life, "color": color, "size": rand(2, 6), "kind": "spark"})

func dust(dx: float, dy: float, n: int) -> void:
	for i in range(n):
		particles.append({"x": dx + rand(-14, 14), "y": dy - 4, "vx": rand(-90, 90), "vy": -rand(10, 60), "life": rand(.3, .55), "max": .55, "color": "#efe2cf", "size": rand(5, 10), "kind": "smoke"})
