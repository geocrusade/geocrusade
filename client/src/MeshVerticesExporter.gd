extends MeshInstance


func _ready():

	var file = File.new()
	var all_verts = []

	var verts = mesh.get_faces()
	for i in range(verts.size()):
		var vert : Vector3 = verts[i]
		all_verts.append({X = vert.x, Y = vert.y, Z = vert.z})

	file.open("res://%s_vertices.json" % name, File.WRITE)
	file.store_string(JSON.print(all_verts))
	file.close()
