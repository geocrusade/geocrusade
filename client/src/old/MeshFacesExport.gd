extends Spatial

func _ready():
	
	var file = File.new()
	var all_verts = []

	for child in get_children():
		if child is StaticBody:
			var basis = child.global_transform.basis
			var mesh = child.get_node("CSGMesh").mesh
			var verts = mesh.get_faces()
			for i in range(verts.size()):
				var vert : Vector3 = verts[i]
				vert = basis.xform(vert)
				vert += child.global_transform.origin
				all_verts.append({x = vert.x, y = vert.y, z = vert.z})

	file.open("res://%s_vertices.json" % name, File.WRITE)
	file.store_string(JSON.print(all_verts))
	file.close()
			

func _is_intersecting_mesh(p1 : Vector3, p2 : Vector3, verts : Array) -> bool:
	for i in range(0, verts.size()-3, 3):
		var v1 = verts[i]
		var v2 = verts[i+1]
		var v3 = verts[i+2]
		if _is_intersecting_triangle(p1, p2, v1, v2, v3):
			return true
	
	return false
	
func _is_intersecting_triangle(p1 : Vector3, p2 : Vector3, v1 : Vector3, v2 : Vector3, v3 : Vector3) -> bool:
	var s1 = _signed_volume(p1, v1, v2, v3)
	var s2 = _signed_volume(p2, v1, v2, v3)
	
	if _same_sign(s1, s2):
		return false
	
	var s3 = _signed_volume(p1, p2, v1, v2)
	var s4 = _signed_volume(p1, p2, v2, v3)

	if not _same_sign(s3, s4):
		return false
	
	var s5 = _signed_volume(p1, p2, v3, v1)
	
	if not _same_sign(s4, s5):
		return false
	
	return true
	
func _same_sign(a : float, b : float) -> bool:
	return a*b >= 0.0
	
func _signed_volume(a : Vector3, b : Vector3, c : Vector3, d : Vector3) -> float:
	var ba = b - a
	var ca = c - a
	var da = d - a 
	return (1.0 / 6.0) * ba.cross(ca).dot(da)
				 

