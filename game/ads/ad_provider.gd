class_name AdProvider
extends RefCounted

# Base contract for ad networks. Show methods may await internally and must return whether the ad completed.


func is_rewarded_ready(_placement: StringName) -> bool:
	return false


func show_rewarded(_placement: StringName) -> bool:
	return false


func is_interstitial_ready() -> bool:
	return false


func show_interstitial() -> bool:
	return false
