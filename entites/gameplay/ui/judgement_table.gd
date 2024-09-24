class_name JudgementTable
extends PanelContainer

@onready var acc_node := $GridContainer/Acc
@onready var f_acc_node := $GridContainer/F_Acc
@onready var inacc_node := $GridContainer/Inacc
@onready var f_inacc_node := $GridContainer/F_Inacc
@onready var miss_node := $GridContainer/Miss
@onready var late_early_node := $GridContainer/LateEarly
@onready var top_combo_node := $GridContainer/TopCombo

func apply_skin(skin: SkinManager) -> void:
	if skin.resource_exists("colour/accurate"):
		acc_node.get_node("Icon").modulate = skin.resources["colour"]["accurate"]
		f_acc_node.get_node("Icon").modulate = skin.resources["colour"]["accurate"]
	if skin.resource_exists("colour/inaccurate"):
		inacc_node.get_node("Icon").modulate = skin.resources["colour"]["inaccurate"]
		f_inacc_node.get_node("Icon").modulate = skin.resources["colour"]["inaccurate"]
	if skin.resource_exists("colour/miss"):
		miss_node.get_node("Icon").modulate = skin.resources["colour"]["miss"]
	
	if skin.resource_exists("colour/late"):
		late_early_node.get_node("Late").modulate = skin.resources["colour"]["late"]
	if skin.resource_exists("colour/early"):
		late_early_node.get_node("Early").modulate = skin.resources["colour"]["early"]

func update_visual(score: ScoreData) -> void:
	acc_node.get_node("Label").text = str(score.accurate_hits)
	f_acc_node.get_node("Label").text = str(score.f_accurate_hits)
	inacc_node.get_node("Label").text = str(score.inaccurate_hits)
	f_inacc_node.get_node("Label").text = str(score.f_inaccurate_hits)
	miss_node.get_node("Label").text = str(score.miss_count)
	
	late_early_node.get_node("Late").text = str(score.late_hits)
	late_early_node.get_node("Early").text = str(score.early_hits)
	
	top_combo_node.get_node("Label").text = str(score.top_combo)
