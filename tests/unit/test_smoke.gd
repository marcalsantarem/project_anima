extends GutTest
## Teste smoke: garante que o GUT roda headless neste projeto.


func test_smoke_passes() -> void:
	assert_true(true, "GUT está executando")
