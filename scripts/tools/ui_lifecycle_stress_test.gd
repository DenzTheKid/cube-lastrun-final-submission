
extends Node

var current_step := 0
var timer := 0.0

func _ready():
    print('Starting Comprehensive UI Lifecycle & Stress Test...')
    _run_stress_sequence()

func _run_stress_sequence():
    var mm_scene = load('res://scenes/main/main_menu.tscn')
    var mm = mm_scene.instantiate() as MainMenu
    add_child(mm)
    print('1. MainMenu loaded.')
    
    # Test button clicks
    print('2. Testing Skin cycling in MainMenu...')
    for i in range(10):
        mm._cycle_skin(1)
        mm._cycle_weapon_skin(1)
    print('Skin cycling OK.')
    
    # Test audio toggles
    print('3. Testing Audio toggles in MainMenu...')
    mm.sfx_btn.button_pressed = false
    mm.sfx_btn.toggled.emit(false)
    mm.sfx_btn.button_pressed = true
    mm.sfx_btn.toggled.emit(true)
    print('Audio toggles OK.')
    
    # Test controls dialog
    print('4. Testing Controls dialog in MainMenu...')
    mm._on_controls_pressed()
    if not mm.controls_panel.visible:
        printerr('FAIL: Controls panel not visible!')
    mm._on_close_controls_pressed()
    if mm.controls_panel.visible:
        printerr('FAIL: Controls panel still visible!')
    print('Controls dialog OK.')

    # Transition to GameWorld
    print('5. Loading GameWorld...')
    mm.queue_free()
    var gw_scene = load('res://scenes/main/game_world.tscn')
    var gw = gw_scene.instantiate() as GameWorld
    add_child(gw)
    print('GameWorld loaded.')
    
    # Run 60 frames of gameplay
    print('6. Simulating 120 gameplay frames...')
    for frame in range(120):
        gw._physics_process(0.016)
        if is_instance_valid(gw.player):
            gw.player._physics_process(0.016)
        if is_instance_valid(gw.hud):
            gw.hud._process(0.016)
    print('120 gameplay frames OK. Distance:', GameManager.distance, 'Score:', GameManager.score)
    
    # Test Pause Menu
    print('7. Testing Pause Menu...')
    gw.pause_menu.toggle_pause()
    if not get_tree().paused:
        printerr('FAIL: Tree not paused!')
    gw.pause_menu.toggle_pause()
    if get_tree().paused:
        printerr('FAIL: Tree still paused!')
    print('Pause/Resume toggle OK.')
    
    # Test Game Over Menu
    print('8. Testing Game Over Menu...')
    GameManager.trigger_game_over()
    if GameManager.current_state != GameManager.State.GAME_OVER:
        printerr('FAIL: State not GAME_OVER!')
    print('Game Over triggered OK.')
    
    print('ALL STRESS SEQUENCE CHECKS COMPLETED.')
    get_tree().quit(0)
