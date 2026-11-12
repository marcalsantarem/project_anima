class_name MetaDaily
extends RefCounted
## Bônus da 1ª vitória do dia. `today` é injetado ("YYYY-MM-DD", data local).


static func is_first_win_today(profile: PlayerProfile, today: String) -> bool:
	return today != "" and PlayerProfile.is_valid_date(today) and profile.last_first_win_date != today


static func mark_first_win(profile: PlayerProfile, today: String) -> void:
	if today != "" and PlayerProfile.is_valid_date(today):
		profile.last_first_win_date = today
