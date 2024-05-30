extends Line2D
class_name YarnString

func set_string_line(p1: Vector2, p2: Vector2):
	points[0] = p1
	points[1] = p2
	$Arrow.position = p2
	$Arrow.rotation = p2.angle_to_point(p1) + PI/2
	var size_x = $Label.size
	size_x.y = 0
	$Label.position = (p1 + p2 - size_x/2) / 2
	if p1.x >= p2.x:
		$Label.rotation = p2.angle_to_point(p1)
	else:
		$Label.rotation = p1.angle_to_point(p2)
	
func set_label(text: String):
	$Label.text = text
