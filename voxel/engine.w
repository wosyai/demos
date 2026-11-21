%%start
host = extern wasm "showcase" {
	unsafe unit(*?u8, i32) mesh;
	unsafe unit(*?u8, i32) frame;
	unsafe unit(*?u8, i32) outline;
	unsafe unit(*?u8, i32) water;
};

f32[6] blank_vertex = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
u8[24] blank_cells = [
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
];
u8[24][24] blank_layer = [
	blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells,
	blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells, blank_cells
];
u8[24][24][16] world = [
	blank_layer, blank_layer, blank_layer, blank_layer, blank_layer, blank_layer, blank_layer, blank_layer, blank_layer, blank_layer, blank_layer, blank_layer,
	blank_layer, blank_layer, blank_layer, blank_layer
];
f32[6][24] blank_vertices = [
	blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex,
	blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex
];
f32[6][24][24] blank_mesh_row = [
	blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices,
	blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices, blank_vertices
];
f32[6][24][24][24] blank_mesh_layer = [
	blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row,
	blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row, blank_mesh_row
];
f32[6][24][24][24][12] vertices = [
	blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer, blank_mesh_layer
];
f32[6] blank_wire_vertex = [0.0, 0.0, 0.0, 0.9, 1.0, 0.54];
f32[6][24] wire = [
	blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex,
	blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex,
	blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex,
	blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex, blank_wire_vertex
];
f32 sea_level = 1.72;
f32[6] sea_a = [-88.0, sea_level, -88.0, 0.0, 0.0, 0.0];
f32[6] sea_b = [-88.0, sea_level, 112.0, 0.0, 0.0, 0.0];
f32[6] sea_c = [112.0, sea_level, 112.0, 0.0, 0.0, 0.0];
f32[6] sea_d = [112.0, sea_level, -88.0, 0.0, 0.0, 0.0];
f32[6][6] sea = [sea_a, sea_b, sea_c, sea_a, sea_c, sea_d];
f32[25] frame_values = [
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
];
i32 write_position = 0;
i32 wire_position = 0;
i32 selected_hit = -2;
i32 target_hit = -1;
bool target_dirty = true;
bool orientation_dirty = true;
f32 sin_yaw = 0.0;
f32 cos_yaw = 1.0;
f32 sin_pitch = 0.0;
f32 cos_pitch = 1.0;
i32 controls = 0;
i32 pulse_controls = 0;
i32 selected_material = 2;
bool flying = false;
bool grounded = false;
bool ground_contact_dirty = false;
bool jump_pending = false;
f32 vertical_speed = 0.0;
f32 player_radius = 0.30;
f32 player_feet = 1.62;
f32 player_head = 0.18;
f32 contact_skin = 0.0001;
f32 camera_x = 32.0;
f32 camera_y = 16.5;
f32 camera_z = 34.5;
f32 yaw = -0.72664234;
f32 pitch = -0.379571;
f32 clock_seconds = 0.0;

u64(i32) index_of = fn(value) { core.int_extend<u64>(value) };

bool(i32, i32, i32) inside = fn(x, y, z) {
	x >= 0 && x < 24 && y >= 0 && y < 16 && z >= 0 && z < 24
};

u8(i32, i32, i32) cell = fn(x, y, z) {
	if (inside(x, y, z)) { world[index_of(y)][index_of(z)][index_of(x)] } else { 0 }
};

i32(i32) abs_i = fn(value) {
	if (value < 0) { -value } else { value }
};

i32(i32, i32, i32) height_at = fn(x, z, seed) {
	i32 dx = x - 11;
	i32 dz = z - 11;
	i32 ring = dx * dx + dz * dz;
	i32 wave = (abs_i(x * 3 + z + seed) % 13 + abs_i(z * 3 - x + seed * 2) % 13) / 8;
	7 - ring / 29 + wave
};

bool(i32, i32, i32, i32) has_tree = fn(x, z, seed, height) {
	height >= 5 && (x * 29 + z * 13 + x * z * 3 + seed) % 113 == 7
};

u8(i32, i32, bool) terrain = fn(y, height, tree) {
	if (y == 0) { 3 } else {
		if (y <= height && height >= 1) {
			if (height <= 3 && y >= height - 1) { 4 } else {
				if (y == height) { 1 } else {
					if (y >= height - 2) { 2 } else { 3 }
				}
			}
		} else {
			if (tree && y <= height + 3) { 5 } else { 0 }
		}
	}
};

unit(i32, i32, i32, i32, bool) fill_column = fn(x, y, z, height, tree) {
	if (y >= 16) { } else {
		world[index_of(y)][index_of(z)][index_of(x)] = terrain(y, height, tree);
		fill_column(x, y + 1, z, height, tree)
	}
};

unit(i32, i32, i32) fill_row = fn(x, z, seed) {
	if (x >= 24) { } else {
		i32 height = height_at(x, z, seed);
		fill_column(x, 0, z, height, has_tree(x, z, seed, height));
		fill_row(x + 1, z, seed)
	}
};

unit(i32, i32) fill_terrain = fn(z, seed) {
	if (z >= 24) { } else {
		fill_row(0, z, seed);
		fill_terrain(z + 1, seed)
	}
};

unit(i32, i32, i32, i32) leaf_cross = fn(x, y, z, size) {
	if (cell(x, y, z) == 0 && inside(x, y, z)) { world[index_of(y)][index_of(z)][index_of(x)] = 6; };
	if (size > 0) {
		if (cell(x - 1, y, z) == 0 && inside(x - 1, y, z)) { world[index_of(y)][index_of(z)][index_of(x - 1)] = 6; };
		if (cell(x + 1, y, z) == 0 && inside(x + 1, y, z)) { world[index_of(y)][index_of(z)][index_of(x + 1)] = 6; };
		if (cell(x, y, z - 1) == 0 && inside(x, y, z - 1)) { world[index_of(y)][index_of(z - 1)][index_of(x)] = 6; };
		if (cell(x, y, z + 1) == 0 && inside(x, y, z + 1)) { world[index_of(y)][index_of(z + 1)][index_of(x)] = 6; };
	};
};

unit(i32, i32, i32) leaf_row = fn(x, z, seed) {
	if (x >= 24) { } else {
		i32 height = height_at(x, z, seed);
		if (has_tree(x, z, seed, height)) {
			leaf_cross(x, height + 3, z, 1);
			leaf_cross(x, height + 4, z, 1);
			leaf_cross(x, height + 5, z, 0);
		};
		leaf_row(x + 1, z, seed)
	}
};

unit(i32, i32) fill_leaves = fn(z, seed) {
	if (z >= 24) { } else {
		leaf_row(0, z, seed);
		fill_leaves(z + 1, seed)
	}
};

unit(f32, f32, f32, f32, f32, f32) vertex = fn(x, y, z, r, g, b) {
	i32 at = write_position;
	u64 outer = index_of(at / 13824);
	u64 layer = index_of(at / 576 % 24);
	u64 row = index_of(at / 24 % 24);
	u64 col = index_of(at % 24);
	vertices[outer][layer][row][col][0] = x;
	vertices[outer][layer][row][col][1] = y;
	vertices[outer][layer][row][col][2] = z;
	vertices[outer][layer][row][col][3] = r;
	vertices[outer][layer][row][col][4] = g;
	vertices[outer][layer][row][col][5] = b;
	write_position = at + 1;
};

unit(i32, i32, i32, i32, u8) face = fn(ix, iy, iz, side, material) {
	f32 x = core.sint_to_float<f32>(ix);
	f32 y = core.sint_to_float<f32>(iy);
	f32 z = core.sint_to_float<f32>(iz);
	f32 r = if (material == 1) { 0.37 } else { if (material == 2) { 0.53 } else { if (material == 3) { 0.50 } else { if (material == 4) { 0.85 } else { if (material == 5) { 0.58 } else { 0.27 } } } } };
	f32 g = if (material == 1) { 0.67 } else { if (material == 2) { 0.34 } else { if (material == 3) { 0.55 } else { if (material == 4) { 0.73 } else { if (material == 5) { 0.40 } else { 0.52 } } } } };
	f32 b = if (material == 1) { 0.30 } else { if (material == 2) { 0.23 } else { if (material == 3) { 0.61 } else { if (material == 4) { 0.48 } else { if (material == 5) { 0.25 } else { 0.29 } } } } };
	f32 shade = if (side == 3) { 1.00 } else { if (side == 2) { 0.50 } else { if (side < 2) { 0.75 } else { 0.87 } } };
	r = r * shade;
	g = g * shade;
	b = b * shade;
	if (side == 0) {
		vertex(x, y, z, r, g, b);
		vertex(x, y, z + 1.0, r, g, b);
		vertex(x, y + 1.0, z + 1.0, r, g, b);
		vertex(x, y, z, r, g, b);
		vertex(x, y + 1.0, z + 1.0, r, g, b);
		vertex(x, y + 1.0, z, r, g, b);
	};
	if (side == 1) {
		vertex(x + 1.0, y, z + 1.0, r, g, b);
		vertex(x + 1.0, y, z, r, g, b);
		vertex(x + 1.0, y + 1.0, z, r, g, b);
		vertex(x + 1.0, y, z + 1.0, r, g, b);
		vertex(x + 1.0, y + 1.0, z, r, g, b);
		vertex(x + 1.0, y + 1.0, z + 1.0, r, g, b);
	};
	if (side == 2) {
		vertex(x, y, z + 1.0, r, g, b);
		vertex(x, y, z, r, g, b);
		vertex(x + 1.0, y, z, r, g, b);
		vertex(x, y, z + 1.0, r, g, b);
		vertex(x + 1.0, y, z, r, g, b);
		vertex(x + 1.0, y, z + 1.0, r, g, b);
	};
	if (side == 3) {
		vertex(x, y + 1.0, z, r, g, b);
		vertex(x, y + 1.0, z + 1.0, r, g, b);
		vertex(x + 1.0, y + 1.0, z + 1.0, r, g, b);
		vertex(x, y + 1.0, z, r, g, b);
		vertex(x + 1.0, y + 1.0, z + 1.0, r, g, b);
		vertex(x + 1.0, y + 1.0, z, r, g, b);
	};
	if (side == 4) {
		vertex(x + 1.0, y, z, r, g, b);
		vertex(x, y, z, r, g, b);
		vertex(x, y + 1.0, z, r, g, b);
		vertex(x + 1.0, y, z, r, g, b);
		vertex(x, y + 1.0, z, r, g, b);
		vertex(x + 1.0, y + 1.0, z, r, g, b);
	};
	if (side == 5) {
		vertex(x, y, z + 1.0, r, g, b);
		vertex(x + 1.0, y, z + 1.0, r, g, b);
		vertex(x + 1.0, y + 1.0, z + 1.0, r, g, b);
		vertex(x, y, z + 1.0, r, g, b);
		vertex(x + 1.0, y + 1.0, z + 1.0, r, g, b);
		vertex(x, y + 1.0, z + 1.0, r, g, b);
	};
};

unit(i32, i32, i32) mesh_row = fn(x, y, z) {
	if (x >= 24) { } else {
		u8 material = world[index_of(y)][index_of(z)][index_of(x)];
		if (material != 0) {
			if (cell(x - 1, y, z) == 0) { face(x, y, z, 0, material); };
			if (cell(x + 1, y, z) == 0) { face(x, y, z, 1, material); };
			if (cell(x, y - 1, z) == 0) { face(x, y, z, 2, material); };
			if (cell(x, y + 1, z) == 0) { face(x, y, z, 3, material); };
			if (cell(x, y, z - 1) == 0) { face(x, y, z, 4, material); };
			if (cell(x, y, z + 1) == 0) { face(x, y, z, 5, material); };
		};
		mesh_row(x + 1, y, z)
	}
};

unit(i32, i32) mesh_layer = fn(y, z) {
	if (z >= 24) { } else {
		mesh_row(0, y, z);
		mesh_layer(y, z + 1)
	}
};

unit(i32) mesh_cells = fn(y) {
	if (y >= 16) { } else {
		mesh_layer(y, 0);
		mesh_cells(y + 1)
	}
};

i32() rebuild = fn {
	write_position = 0;
	mesh_cells(0);
	i32 count = write_position;
	unsafe { host.mesh(core.pointer_cast<*?u8>(&?vertices[0][0][0][0][0]), count); };
	count
};

i32(i32) generate = fn(seed) {
	i32 bounded = seed % 16381;
	fill_terrain(0, bounded);
	fill_leaves(0, bounded);
	reset_camera();
	publish_water();
	rebuild()
};

i32(i32, i32, i32, i32) edit = fn(x, y, z, material) {
	if (inside(x, y, z) && material >= 0 && material < 7) {
		u8 new_material = core.int_trunc<u8>(material);
		u64 ix = index_of(x);
		u64 iy = index_of(y);
		u64 iz = index_of(z);
		if (world[iy][iz][ix] == new_material) { 0 } else {
			world[iy][iz][ix] = new_material;
			target_dirty = true;
			ground_contact_dirty = true;
			1
		}
	} else { 0 }
};

i32(f32) floor_i = fn(value) {
	i32 truncated = core.float_to_sint_trunc<i32>(value);
	if (value < core.sint_to_float<f32>(truncated)) { truncated - 1 } else { truncated }
};

i32(f32) step_sign = fn(value) {
	if (value < 0.0) { -1 } else { if (value > 0.0) { 1 } else { 0 } }
};

f32(f32) distance_delta = fn(direction) {
	if (direction > 0.0) { 1.0 / direction } else {
		if (direction < 0.0) { -1.0 / direction } else { 100000.0 }
	}
};

f32(f32, f32, i32) first_distance = fn(origin, direction, index) {
	f32 base = core.sint_to_float<f32>(index);
	if (direction > 0.0) { (base + 1.0 - origin) / direction } else {
		if (direction < 0.0) { (base - origin) / direction } else { 100000.0 }
	}
};

i32(i32, i32, i32, i32, i32, i32, i32, f32, f32, f32, f32, f32, f32, i32) pick_step = fn(x, y, z, side, sx, sy, sz, tx, ty, tz, dx, dy, dz, remaining) {
	if (cell(x, y, z) != 0) { x + y * 32 + z * 512 + side * 16384 } else {
		bool leaving = (x < 0 && sx <= 0) || (x >= 24 && sx >= 0) || (y < 0 && sy <= 0) || (y >= 16 && sy >= 0) || (z < 0 && sz <= 0) || (z >= 24 && sz >= 0);
		if (remaining == 0 || leaving) { -1 } else {
			if (tx <= ty && tx <= tz) {
				i32 next_side = if (sx > 0) { 0 } else { 1 };
				pick_step(x + sx, y, z, next_side, sx, sy, sz, tx + dx, ty, tz, dx, dy, dz, remaining - 1)
			} else {
				if (ty <= tz) {
					i32 next_side = if (sy > 0) { 2 } else { 3 };
					pick_step(x, y + sy, z, next_side, sx, sy, sz, tx, ty + dy, tz, dx, dy, dz, remaining - 1)
				} else {
					i32 next_side = if (sz > 0) { 4 } else { 5 };
					pick_step(x, y, z + sz, next_side, sx, sy, sz, tx, ty, tz + dz, dx, dy, dz, remaining - 1)
				}
			}
		}
	}
};

i32(f32, f32, f32, f32, f32, f32) pick = fn(ox, oy, oz, dx, dy, dz) {
	bool inside_ray_range = ox >= -128.0 && ox <= 128.0 && oy >= -128.0 && oy <= 128.0 && oz >= -128.0 && oz <= 128.0;
	bool finite_direction = dx >= -1.0 && dx <= 1.0 && dy >= -1.0 && dy <= 1.0 && dz >= -1.0 && dz <= 1.0;
	if (!inside_ray_range || !finite_direction || (dx == 0.0 && dy == 0.0 && dz == 0.0)) { -1 } else {
		i32 x = floor_i(ox);
		i32 y = floor_i(oy);
		i32 z = floor_i(oz);
		pick_step(x, y, z, 3, step_sign(dx), step_sign(dy), step_sign(dz), first_distance(ox, dx, x), first_distance(oy, dy, y), first_distance(oz, dz, z), distance_delta(dx), distance_delta(dy), distance_delta(dz), 420)
	}
};

f32(f32, f32, f32) clamp_f = fn(value, low, high) {
	if (value < low) { low } else { if (value > high) { high } else { value } }
};

f32(f32) wrap_yaw = fn(angle) {
	f32 period = 6.283185307;
	i32 turns = core.float_to_sint_trunc<i32>(angle / period);
	f32 wrapped = angle - core.sint_to_float<f32>(turns) * period;
	if (wrapped > 3.141592654) { wrapped - period } else {
		if (wrapped < -3.141592654) { wrapped + period } else { wrapped }
	}
};

f32(f32) sine = fn(angle) {
	f32 phase = wrap_yaw(angle);
	f32 folded = if (phase > 1.570796327) { 3.141592654 - phase } else {
		if (phase < -1.570796327) { -3.141592654 - phase } else { phase }
	};
	f32 square = folded * folded;
	folded * (1.0 + square * (-0.166666667 + square * (0.008333333 + square * (-0.000198413 + square * (0.000002756 + square * -0.000000025)))))
};

f32(f32) cosine = fn(angle) { sine(angle + 1.570796327) };

i32(i32, i32, i32) spawn_height = fn(x, y, z) {
	if (y < 0 || cell(x, y, z) != 0) { y + 1 } else { spawn_height(x, y - 1, z) }
};

i32(i32, i32) spawn_tile = fn(x, z) {
	if (inside(x, 0, z)) {
		i32 height = spawn_height(x, 15, z);
		if (height > 0) { x + 24 * z + 576 * height } else { -1 }
	} else { -1 }
};

i32(i32, i32) search_spawn_ring = fn(distance, dx) {
	if (dx > distance) { -1 } else {
		i32 dz = distance - abs_i(dx);
		i32 north = spawn_tile(12 + dx, 16 - dz);
		if (north >= 0) { north } else {
			i32 south = if (dz > 0) { spawn_tile(12 + dx, 16 + dz) } else { -1 };
			if (south >= 0) { south } else { search_spawn_ring(distance, dx + 1) }
		}
	}
};

i32(i32) search_spawn = fn(distance) {
	if (distance > 28) { -1 } else {
		i32 tile = search_spawn_ring(distance, -distance);
		if (tile >= 0) { tile } else { search_spawn(distance + 1) }
	}
};

unit() spawn_player = fn {
	i32 tile = search_spawn(0);
	if (tile >= 0) {
		camera_x = core.sint_to_float<f32>(tile % 24) + 0.5;
		camera_y = core.sint_to_float<f32>(tile / 576) + player_feet;
		camera_z = core.sint_to_float<f32>((tile / 24) % 24) + 0.5;
		grounded = true;
	} else {
		camera_x = 12.5;
		camera_y = 10.0;
		camera_z = 16.5;
		flying = true;
		grounded = false;
	};
	ground_contact_dirty = false;
	jump_pending = false;
	vertical_speed = 0.0;
	selected_hit = -2;
	target_dirty = true;
};

unit() clear_controls = fn {
	controls = 0;
	pulse_controls = 0;
	jump_pending = false;
};

unit() reset_camera = fn {
	flying = false;
	spawn_player();
	yaw = -0.72664234;
	pitch = -0.21;
	clear_controls();
	orientation_dirty = true;
};

unit() toggle_flight = fn {
	flying = !flying;
	grounded = false;
	ground_contact_dirty = !flying;
	jump_pending = false;
	vertical_speed = 0.0;
};

unit(i32, i32) control = fn(action, down) {
	if (action >= 0 && action < 8) {
		i32 bit = 1 << action;
		if (down != 0) {
			bool first_press = ((controls | pulse_controls) & bit) == 0;
			controls = controls | bit;
			if (first_press && action == 4 && !flying) { jump_pending = true; };
			if (first_press && action == 7) { toggle_flight(); };
		} else { controls = controls & ~bit; };
	};
};

unit(i32) pulse_control = fn(action) {
	if (action == 7) {
		if ((controls & 128) == 0) { toggle_flight(); };
	} else {
		if (action >= 0 && action < 7) {
			i32 bit = 1 << action;
			bool first_press = ((controls | pulse_controls) & bit) == 0;
			pulse_controls = pulse_controls | bit;
			if (first_press && action == 4 && !flying) { jump_pending = true; };
		};
	};
};

i32(i32) active = fn(mask) { if (((controls | pulse_controls) & mask) != 0) { 1 } else { 0 } };

unit(f32, f32) look = fn(dx, dy) {
	if (dx >= -10000.0 && dx <= 10000.0 && dy >= -10000.0 && dy <= 10000.0) {
		f32 next_yaw = wrap_yaw(yaw + dx * 0.0034);
		f32 next_pitch = clamp_f(pitch - dy * 0.0034, -1.46, 1.35);
		if (next_yaw != yaw || next_pitch != pitch) {
			yaw = next_yaw;
			pitch = next_pitch;
			orientation_dirty = true;
			target_dirty = true;
		};
	};
};

bool(i32, i32, i32, i32, i32, i32) solid_layers = fn(x0, x1, y, last_y, z0, z1) {
	if (y > last_y) { false } else {
		cell(x0, y, z0) != 0
			|| (x1 != x0 && cell(x1, y, z0) != 0)
			|| (z1 != z0 && (cell(x0, y, z1) != 0 || (x1 != x0 && cell(x1, y, z1) != 0)))
			|| solid_layers(x0, x1, y + 1, last_y, z0, z1)
	}
};

bool(f32, f32, f32) player_collides = fn(x, y, z) {
	solid_layers(
		floor_i(x - player_radius + contact_skin),
		floor_i(x + player_radius - contact_skin),
		floor_i(y - player_feet + contact_skin),
		floor_i(y + player_head - contact_skin),
		floor_i(z - player_radius + contact_skin),
		floor_i(z + player_radius - contact_skin)
	)
};

bool(i32, i32, i32) overlaps_player = fn(x, y, z) {
	f32 block_x = core.sint_to_float<f32>(x);
	f32 block_y = core.sint_to_float<f32>(y);
	f32 block_z = core.sint_to_float<f32>(z);
	camera_x - player_radius + contact_skin < block_x + 1.0
		&& camera_x + player_radius - contact_skin > block_x
		&& camera_y - player_feet + contact_skin < block_y + 1.0
		&& camera_y + player_head - contact_skin > block_y
		&& camera_z - player_radius + contact_skin < block_z + 1.0
		&& camera_z + player_radius - contact_skin > block_z
};

f32(f32, f32, f32, f32) contact_position = fn(prior, next, low_extent, high_extent) {
	if (next > prior) {
		core.sint_to_float<f32>(floor_i(next + high_extent - contact_skin)) - high_extent
	} else {
		core.sint_to_float<f32>(floor_i(next - low_extent + contact_skin) + 1) + low_extent
	}
};

unit(f32, f32, f32, i32) move_player_steps = fn(dx, dy, dz, remaining) {
	if (dx != 0.0) {
		f32 next_x = clamp_f(camera_x + dx, -20.0, 44.0);
		if (next_x != camera_x && player_collides(next_x, camera_y, camera_z)) {
			next_x = contact_position(camera_x, next_x, player_radius, player_radius);
		};
		camera_x = next_x;
	};
	if (dz != 0.0) {
		f32 next_z = clamp_f(camera_z + dz, -20.0, 44.0);
		if (next_z != camera_z && player_collides(camera_x, camera_y, next_z)) {
			next_z = contact_position(camera_z, next_z, player_radius, player_radius);
		};
		camera_z = next_z;
	};
	f32 remaining_dy = dy;
	if (dy != 0.0) {
		f32 next_y = camera_y + dy;
		if (flying) { next_y = clamp_f(next_y, 1.8, 35.0); };
		if (next_y != camera_y && player_collides(camera_x, next_y, camera_z)) {
			next_y = contact_position(camera_y, next_y, player_feet, player_head);
			remaining_dy = 0.0;
			vertical_speed = 0.0;
		};
		camera_y = next_y;
	};
	if (remaining > 1) { move_player_steps(dx, remaining_dy, dz, remaining - 1); };
};

unit(f32, f32, f32) move_camera = fn(dt, sy, cy) {
	if (dt > 0.0) {
		i32 forward = active(1) - active(2);
		i32 right = active(8) - active(4);
		i32 up = if (flying) { active(16) - active(32) } else { 0 };
		i32 axes = forward * forward + right * right + up * up;
		f32 normal = if (axes == 3) { 0.577350269 } else { if (axes == 2) { 0.707106781 } else { 1.0 } };
		f32 speed = if (active(64) == 1) { 8.0 } else { 4.8 };
		f32 stride = dt * speed * normal;
		f32 f = core.sint_to_float<f32>(forward);
		f32 r = core.sint_to_float<f32>(right);
		f32 dx = (sy * f + cy * r) * stride;
		f32 dz = (0.0 - cy * f + sy * r) * stride;
		if (!flying) {
			if (ground_contact_dirty) {
				grounded = vertical_speed <= 0.0 && player_collides(camera_x, camera_y - 0.018, camera_z);
				ground_contact_dirty = false;
			};
			if (jump_pending && grounded) { vertical_speed = 7.4; grounded = false; };
			vertical_speed = if (grounded) { 0.0 } else { clamp_f(vertical_speed - 22.0 * dt, -18.0, 8.0) };
		};
		jump_pending = false;
		f32 dy = if (flying) { core.sint_to_float<f32>(up) * stride } else { vertical_speed * dt };
		f32 previous_x = camera_x;
		f32 previous_y = camera_y;
		f32 previous_z = camera_z;
		if (dx != 0.0 || dy != 0.0 || dz != 0.0) {
			if (dt <= 0.015) { move_player_steps(dx, dy, dz, 1); } else {
				if (dt <= 0.03) { move_player_steps(dx * 0.5, dy * 0.5, dz * 0.5, 2); } else {
					move_player_steps(dx * 0.25, dy * 0.25, dz * 0.25, 4);
				};
			};
			if (!flying) { grounded = vertical_speed <= 0.0 && player_collides(camera_x, camera_y - 0.018, camera_z); };
		};
		if (camera_y < -6.0) { spawn_player(); };
		if (camera_x != previous_x || camera_y != previous_y || camera_z != previous_z) { target_dirty = true; };
		pulse_controls = 0;
	};
};

unit(f32, f32, f32, f32, f32, f32) wire_edge = fn(x0, y0, z0, x1, y1, z1) {
	i32 at = wire_position;
	u64 origin = index_of(at);
	u64 terminal = index_of(at + 1);
	wire[origin][0] = x0;
	wire[origin][1] = y0;
	wire[origin][2] = z0;
	wire[terminal][0] = x1;
	wire[terminal][1] = y1;
	wire[terminal][2] = z1;
	wire_position = at + 2;
};

unit(i32) publish_outline = fn(hit) {
	if (hit != selected_hit) {
		selected_hit = hit;
		wire_position = 0;
		if (hit >= 0) {
			f32 x = core.sint_to_float<f32>(hit % 32);
			f32 y = core.sint_to_float<f32>((hit / 32) % 16);
			f32 z = core.sint_to_float<f32>((hit / 512) % 32);
			f32 x0 = x - 0.012;
			f32 y0 = y - 0.012;
			f32 z0 = z - 0.012;
			f32 x1 = x + 1.012;
			f32 y1 = y + 1.012;
			f32 z1 = z + 1.012;
			wire_edge(x0, y0, z0, x1, y0, z0);
			wire_edge(x1, y0, z0, x1, y0, z1);
			wire_edge(x1, y0, z1, x0, y0, z1);
			wire_edge(x0, y0, z1, x0, y0, z0);
			wire_edge(x0, y1, z0, x1, y1, z0);
			wire_edge(x1, y1, z0, x1, y1, z1);
			wire_edge(x1, y1, z1, x0, y1, z1);
			wire_edge(x0, y1, z1, x0, y1, z0);
			wire_edge(x0, y0, z0, x0, y1, z0);
			wire_edge(x1, y0, z0, x1, y1, z0);
			wire_edge(x1, y0, z1, x1, y1, z1);
			wire_edge(x0, y0, z1, x0, y1, z1);
		};
		unsafe { host.outline(core.pointer_cast<*?u8>(&?wire[0][0]), wire_position); };
	};
};

unit() publish_water = fn {
	unsafe { host.water(core.pointer_cast<*?u8>(&?sea[0][0]), 6); };
};

unit(f32, f32, f32, f32, f32, f32, f32, f32, i32) publish_frame = fn(x, y, z, sy, cy, sp, cp, view_pitch, hit) {
	f32 q = 1.920982127;
	f32 qw = q / frame_values[20];
	f32 depth = -1.00170358;
	f32 near = -0.32027257;
	f32 zz = sy * cp * x + sp * y - cy * cp * z;
	frame_values[0] = qw * cy;
	frame_values[1] = 0.0 - q * sy * sp;
	frame_values[2] = 0.0 - depth * sy * cp;
	frame_values[3] = sy * cp;
	frame_values[4] = 0.0;
	frame_values[5] = q * cp;
	frame_values[6] = 0.0 - depth * sp;
	frame_values[7] = sp;
	frame_values[8] = qw * sy;
	frame_values[9] = q * cy * sp;
	frame_values[10] = depth * cy * cp;
	frame_values[11] = 0.0 - cy * cp;
	frame_values[12] = qw * (0.0 - cy * x - sy * z);
	frame_values[13] = q * (sy * sp * x - cp * y - cy * sp * z);
	frame_values[14] = depth * zz + near;
	frame_values[15] = 0.0 - zz;
	frame_values[16] = x;
	frame_values[17] = y;
	frame_values[18] = z;
	frame_values[19] = view_pitch;
	frame_values[21] = clock_seconds;
	frame_values[22] = if (flying) { 1.0 } else { 0.0 };
	frame_values[23] = if (grounded) { 1.0 } else { 0.0 };
	frame_values[24] = core.sint_to_float<f32>(selected_material);
	unsafe { host.frame(core.pointer_cast<*?u8>(&?frame_values[0]), hit); };
};

unit() update_orientation = fn {
	if (orientation_dirty) {
		sin_yaw = sine(yaw);
		cos_yaw = cosine(yaw);
		sin_pitch = sine(pitch);
		cos_pitch = cosine(pitch);
		orientation_dirty = false;
	};
};

i32(i32, f32, f32, f32) visible_hit = fn(hit, dx, dy, dz) {
	if (hit < 0 || dy >= 0.0) { hit } else {
		i32 side = hit / 16384;
		f32 x = core.sint_to_float<f32>(hit % 32);
		f32 y = core.sint_to_float<f32>((hit / 32) % 16);
		f32 z = core.sint_to_float<f32>((hit / 512) % 32);
		if (y >= 2.0) { hit } else {
			f32 entry = if (side == 0) { (x - camera_x) / dx } else {
				if (side == 1) { (x + 1.0 - camera_x) / dx } else {
					if (side == 2) { (y - camera_y) / dy } else {
						if (side == 3) { (y + 1.0 - camera_y) / dy } else {
							if (side == 4) { (z - camera_z) / dz } else { (z + 1.0 - camera_z) / dz }
						}
					}
				}
			};
			if (camera_y + dy * entry >= sea_level) { hit } else { -1 }
		}
	}
};

i32() current_view_target = fn {
	if (target_dirty) {
		f32 dx = sin_yaw * cos_pitch;
		f32 dy = sin_pitch;
		f32 dz = 0.0 - cos_yaw * cos_pitch;
		target_hit = visible_hit(pick(camera_x, camera_y, camera_z, dx, dy, dz), dx, dy, dz);
		target_dirty = false;
	};
	target_hit
};

unit(f32, f32, i32) tick = fn(dt, aspect, playing) {
	f32 zero = 0.0;
	f32 upper_step = 0.06;
	f32 step = if (dt > zero && dt <= 3.402823466e38) { clamp_f(dt, zero, upper_step) } else { zero };
	frame_values[20] = if (aspect >= 0.05 && aspect <= 20.0) { aspect } else { 1.0 };
	clock_seconds = clock_seconds + step;
	update_orientation();
	if (playing != 0) {
		move_camera(step, sin_yaw, cos_yaw);
		i32 hit = current_view_target();
		publish_outline(hit);
		publish_frame(camera_x, camera_y, camera_z, sin_yaw, cos_yaw, sin_pitch, cos_pitch, pitch, hit);
	} else {
		publish_outline(-1);
		f32 intro = if (frame_values[20] > 1.17) { 4.5 } else { 0.0 };
		publish_frame(32.0 - 0.747411 * intro, 16.5, 34.5 + 0.664362 * intro, -0.664362, 0.747411, -0.370522, 0.928823, -0.379571, -1);
	};
};

i32(i32) edit_view = fn(material) {
	update_orientation();
	i32 hit = current_view_target();
	if (hit < 0) { -1 } else {
		i32 side = hit / 16384;
		i32 x = hit % 32;
		i32 y = (hit / 32) % 16;
		i32 z = (hit / 512) % 32;
		if (material > 0) {
			if (side == 0) { x = x - 1; };
			if (side == 1) { x = x + 1; };
			if (side == 2) { y = y - 1; };
			if (side == 3) { y = y + 1; };
			if (side == 4) { z = z - 1; };
			if (side == 5) { z = z + 1; };
		};
		if (inside(x, y, z)) {
			if (material > 0 && overlaps_player(x, y, z)) { -3 } else {
				i32 changed = edit(x, y, z, material);
				if (changed == 1) { rebuild(); };
				changed
			}
		} else { -2 }
	}
};
unit(i32) select_material = fn(material) {
	if (material >= 1 && material <= 6) { selected_material = material; };
};

unit(i32) cycle_material = fn(delta) {
	if (delta > 0) {
		selected_material = if (selected_material == 6) { 1 } else { selected_material + 1 };
	};
	if (delta < 0) {
		selected_material = if (selected_material == 1) { 6 } else { selected_material - 1 };
	};
};

i32() place_selected = fn { edit_view(selected_material) };
i32 seed_phase = 4;
bool seed_trim = false;
bool seed_negative = false;
i64 seed_magnitude = 0;

i32() default_seed = fn { 471 };

unit(i32) seed_begin = fn(trim) {
	seed_phase = 0;
	seed_trim = trim != 0;
	seed_negative = false;
	seed_magnitude = 0;
};

bool(i32) seed_trim_space = fn(value) {
	(value >= 9 && value <= 13) || value == 32 || value == 160 || value == 5760
		|| (value >= 8192 && value <= 8202) || value == 8232 || value == 8233
		|| value == 8239 || value == 8287 || value == 12288 || value == 65279
};

i32() reject_seed = fn { seed_phase = 4; 0 };

i32(i32) seed_code_unit = fn(value) {
	if (seed_phase == 4) { 0 } else {
		if (value >= 48 && value <= 57) {
			if (seed_phase == 3) { reject_seed() } else {
				i64 next = seed_magnitude * 10 + core.int_extend<i64>(value - 48);
				i64 limit = if (seed_negative) { 2147483648 } else { 2147483647 };
				if (next > limit) { reject_seed() } else {
					seed_magnitude = next;
					seed_phase = 2;
					1
				}
			}
		} else {
			if (seed_phase == 0 && value == 45) {
				seed_negative = true;
				seed_phase = 1;
				1
			} else {
				if (seed_trim && seed_phase != 1 && seed_trim_space(value)) {
					if (seed_phase == 2) { seed_phase = 3; };
					1
				} else { reject_seed() }
			}
		}
	}
};

i64() seed_end = fn {
	if (seed_phase == 2 || seed_phase == 3) {
		if (seed_negative) { -seed_magnitude } else { seed_magnitude }
	} else { 2147483648 }
};

%%end
