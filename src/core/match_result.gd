class_name MatchResult
extends RefCounted
## Saída da partida, emitida em `match_ended(result)`.

enum Outcome { VICTORY, DEFEAT }

var outcome: Outcome = Outcome.DEFEAT
var wave_reached: int = 0
var waves_total: int = 0
var particles: int = 0 ## Partículas acumuladas na partida
var enemies_killed: int = 0
var duration_s: float = 0.0
