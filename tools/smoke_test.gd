extends SceneTree
func _init():
    var s = load("res://shaders/test_smoke.gdshader")
    if s == null:
        print("FAIL: test_smoke null")
        quit(1)
    print("SUCCESS: test_smoke loaded ok")
    quit(0)
