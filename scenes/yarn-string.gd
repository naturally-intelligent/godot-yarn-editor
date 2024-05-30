extends Line2D
class_name YarnString

func set_string_line(p1: Vector2, p2: Vector2):
	points[0] = p1
	points[1] = p2
	$Arrow.position = p2
	$Arrow.rotation = p2.angle_to_point(p1) + PI/2
	$Label.position = p1
	
func set_label(text: String):
	$Label.text = text
