class_name FrameStats
extends RefCounted
## Tempos de quadro da partida inteira num histograma de 1 ms (pré-alocado, sem alocar por quadro).
## Percentis com resolução de 1 ms (limite superior do balde).

const BUCKETS := 256 ## 0..254 ms; o último balde acumula ≥ 255 ms

var hist := PackedInt32Array()
var count := 0
var sum_ms := 0.0
var max_ms := 0.0
var over_33 := 0
var over_50 := 0
var over_100 := 0


func _init() -> void:
	hist.resize(BUCKETS)


func add(ms: float) -> void:
	hist[clampi(int(ms), 0, BUCKETS - 1)] += 1
	count += 1
	sum_ms += ms
	if ms > max_ms:
		max_ms = ms
	if ms > 33.0:
		over_33 += 1
		if ms > 50.0:
			over_50 += 1
			if ms > 100.0:
				over_100 += 1


func avg_ms() -> float:
	return sum_ms / count if count > 0 else 0.0


## Percentil `p` (0–100) em ms.
func percentile(p: float) -> float:
	return FrameStats.hist_percentile(hist, count, p)


static func hist_percentile(h: Array, total: int, p: float) -> float:
	if total <= 0:
		return 0.0
	var rank := maxi(1, ceili(clampf(p, 0.0, 100.0) / 100.0 * total))
	var acc := 0
	for i in h.size():
		acc += int(h[i])
		if acc >= rank:
			return float(i + 1)
	return float(h.size())


## Dicionário serializável (o histograma vai cortado no último balde não vazio).
func to_dict() -> Dictionary:
	var last := 0
	for i in BUCKETS:
		if hist[i] > 0:
			last = i
	return {
		"count": count, "avg_ms": snappedf(avg_ms(), 0.01), "max_ms": snappedf(max_ms, 0.01),
		"over_33": over_33, "over_50": over_50, "over_100": over_100,
		"hist_1ms": Array(hist.slice(0, last + 1)),
	}
