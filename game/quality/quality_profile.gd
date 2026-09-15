class_name QualityProfile
extends Resource

@export var id := &"high"
@export_range(0, 24) var particles_per_burst := 12
@export var screen_shake := true
@export var hit_stop := true
@export var trails := true
@export_range(0, 2) var shelter_idle_level := 2
@export var parallax := true
@export_range(1, 2) var atlas_scale := 2
@export_range(30, 120) var max_fps := 60
@export_range(0.5, 1.0) var tween_scale := 1.0
