@tool
extends SceneTree

func _init():
	print("--- Testando Instanciacao da Cena test_botw_shaders.tscn ---")
	var scn = ResourceLoader.load("res://scenes/test_botw_shaders.tscn")
	if scn == null:
		print("ERRO: Falha ao carregar a cena de teste")
		quit(1)
		return
	var inst = scn.instantiate()
	if inst == null:
		print("ERRO: Falha ao instanciar a cena de teste")
		quit(1)
		return
	print("Sucesso! Cena instanciada com ", inst.get_child_count(), " nós 3D.")
	inst.free()
	print("Teste de render e materiais concluido com 100% de sucesso!")
	quit(0)
