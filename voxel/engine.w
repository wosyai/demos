%%start
host = extern wasm "showcase" {
	unsafe unit(*?u8, i32) mesh;
	unsafe unit(*?u8, i32, i32) atlas;
	unsafe unit(*?u8, i32) frame;
	unsafe unit(*?u8, i32) outline;
	unsafe unit(*?u8, i32) water;
	unsafe unit(*?u8, i32) player;
	unit(f32, f32) aim;
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
f32[6][24][24] avatar_vertices = blank_mesh_row;
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
u8[4] blank_texel = [0, 0, 0, 0];
u8[4][16] blank_tile_line = [
	blank_texel, blank_texel, blank_texel, blank_texel, blank_texel, blank_texel, blank_texel, blank_texel,
	blank_texel, blank_texel, blank_texel, blank_texel, blank_texel, blank_texel, blank_texel, blank_texel
];
u8[4][16][8] blank_atlas_line = [
	blank_tile_line, blank_tile_line, blank_tile_line, blank_tile_line, blank_tile_line, blank_tile_line, blank_tile_line, blank_tile_line
];
u8[4][16][8][16] block_atlas = [
	blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line,
	blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line, blank_atlas_line
];
bool atlas_ready = false;
f32[29] frame_values = [
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 1.0, 0.0, 0.0
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
i32 held_edits = 0;
i32 repeat_edit_mode = -1;
f32 repeat_edit_wait = 0.0;
i32 selected_material = 2;
bool flying = false;
bool grounded = false;
bool ground_contact_dirty = false;
bool jump_pending = false;
f32 vertical_speed = 0.0;
bool third_person = false;
bool avatar_visible = false;
bool aim_was_offset = false;
i32 avatar_position = 0;
f32 avatar_x = 0.0;
f32 avatar_y = 0.0;
f32 avatar_z = 0.0;
f32 avatar_yaw = 0.0;
f32 view_scale = 1.920982127;
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
f32 sea_phase = 0.0;
f32 sea_level = 2.55;
f32 sea_low = 2.55;
f32 tide_span = 1.85;
f32 lamp_offset = 0.90;
f32 lamp_limit = 3.2;
i32 beacon_state = 0;
i32 bridge_blocks = 7;
i32 sandbox_material = 2;
f32 beacon_elapsed = 0.0;
f32 lamp_wet = 0.0;
f32 tide_progress = 0.0;
u8[24][24][16] sandbox_cells = world;
f32 swell = 0.18;
f32 chop = 0.10;
bool sea_mesh_ready = false;
f32[19] blank_sea_samples = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
f32[19][19] sea_samples = [
	blank_sea_samples, blank_sea_samples, blank_sea_samples, blank_sea_samples, blank_sea_samples,
	blank_sea_samples, blank_sea_samples, blank_sea_samples, blank_sea_samples, blank_sea_samples,
	blank_sea_samples, blank_sea_samples, blank_sea_samples, blank_sea_samples, blank_sea_samples,
	blank_sea_samples, blank_sea_samples, blank_sea_samples, blank_sea_samples
];
f32[6][6] blank_sea_quad = [blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex, blank_vertex];
f32[6][6][18] blank_sea_row = [
	blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad,
	blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad,
	blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad, blank_sea_quad
];
f32[6][6][18][18] sea_vertices = [
	blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row,
	blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row,
	blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row, blank_sea_row
];

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

i32(i32, i32, i32) sample_pattern = fn(x, z, seed) {
	i32 residue = (x * 41 + z * 67 + (seed + 16381) * 97 + x * z * 13) % 251;
	(residue * residue * 11 + residue * 79 + x * 17 + z * 37) % 251
};

i32(i32, i32, i32, i32) terrain_pattern = fn(x, z, seed, offset) {
	i32 turn = (seed + 16381) / 251;
	i32 opening_turn = (default_seed() + 16381) / 251;
	i32 high_bits = (turn + 251 - opening_turn) % 251;
	i32 weight = 1 + x * 17 + z * 43 + x * z * 29;
	i32 mix = (high_bits * weight) % 251;
	sample_pattern(x, z, seed + offset + mix)
};

i32(i32, i32, i32, i32, i32) slope_noise = fn(x, z, seed, offset, span) {
	i32 ix = x / span;
	i32 iz = z / span;
	i32 dx = x % span;
	i32 dz = z % span;
	i32 near = terrain_pattern(ix, iz, seed, offset) * (span - dx) + terrain_pattern(ix + 1, iz, seed, offset) * dx;
	i32 far = terrain_pattern(ix, iz + 1, seed, offset) * (span - dx) + terrain_pattern(ix + 1, iz + 1, seed, offset) * dx;
	(near * (span - dz) + far * dz) / (span * span)
};

i32(i32, i32, i32) region_height = fn(x, z, seed) {
	i32 wide = slope_noise(x, z, seed, 0, 7);
	i32 small = slope_noise(x, z, seed, 379, 3);
	4 + (wide * 3 + small) / 155
};

i32(i32, i32, i32) height_at = fn(x, z, seed) {
	i32 edge_x = if (x < 8) { 8 - x } else { if (x > 14) { x - 14 } else { 0 } };
	i32 edge_z = if (z < 12) { 12 - z } else { if (z > 17) { z - 17 } else { 0 } };
	i32 edge = if (edge_x > edge_z) { edge_x } else { edge_z };
	if (edge == 0) { region_height(12, 16, seed) } else {
		i32 base = region_height(x, z, seed);
		if (edge < 3) { (region_height(12, 16, seed) * (3 - edge) + base * edge) / 3 } else { base }
	}
};

i32(i32, i32) min_i = fn(a, b) { if (a < b) { a } else { b } };

i32(i32, i32, i32) coastal_height = fn(x, z, seed) {
	i32 d = min_i(min_i(x, 23 - x), min_i(z, 23 - z));
	if (d < 3) { d } else { min_i(height_at(x, z, seed), d) }
};

bool(i32, i32, i32, i32) has_tree = fn(x, z, seed, height) {
	if ((x == 8 && z == 8) || (x == 5 && z == 11)) { true } else {
		if (x < 2 || x > 21 || z < 2 || z > 21 || height < 5 || (x >= 5 && x <= 16 && z >= 9 && z <= 19)) { false } else {
			i32 grove_x = x / 5;
			i32 grove_z = z / 5;
			i32 near_x = 1 + terrain_pattern(grove_x, grove_z, seed, 75) % 3;
			i32 near_z = 1 + terrain_pattern(grove_z, grove_x, seed, 119) % 3;
			x % 5 == near_x && z % 5 == near_z
		}
	}
};

u8(i32, i32, bool, bool) terrain = fn(y, height, tree, sandy) {
	if (y == height) { if (sandy) { 4 } else { 1 } } else {
		if (y < height) {
			if (y >= height - 2) { if (sandy) { 4 } else { 2 } } else { 3 }
		} else {
			if (tree && y <= height + 3) { 5 } else { 0 }
		}
	}
};

unit(i32, i32, i32, i32, bool, bool) fill_column = fn(x, y, z, height, tree, sandy) {
	if (y >= 16) { } else {
		world[index_of(y)][index_of(z)][index_of(x)] = terrain(y, height, tree, sandy);
		fill_column(x, y + 1, z, height, tree, sandy)
	}
};

unit(i32, i32, i32) fill_row = fn(x, z, seed) {
	if (x >= 24) { } else {
		i32 height = coastal_height(x, z, seed);
		bool sandy = height <= 2 || (height <= 5 && terrain_pattern(x / 3, z / 3, seed, 204) % 4 == 0);
		fill_column(x, 0, z, height, has_tree(x, z, seed, height), sandy);
		fill_row(x + 1, z, seed)
	}
};

unit(i32, i32) fill_terrain = fn(z, seed) {
	if (z >= 24) { } else {
		fill_row(0, z, seed);
		fill_terrain(z + 1, seed)
	}
};

unit(i32, i32, i32, i32, i32, bool) crown_line = fn(x, y, z, dx, radius, trim) {
	if (dx <= radius) {
		if ((!trim || abs_i(dx) < radius) && inside(x + dx, y, z) && cell(x + dx, y, z) == 0) {
			world[index_of(y)][index_of(z)][index_of(x + dx)] = 6;
		};
		crown_line(x, y, z, dx + 1, radius, trim);
	};
};

unit(i32, i32, i32, i32, i32, bool) crown_layer = fn(x, y, z, dz, radius, trim) {
	if (dz <= radius) {
		crown_line(x, y, z + dz, -radius, radius, trim && abs_i(dz) == radius);
		crown_layer(x, y, z, dz + 1, radius, trim);
	};
};

unit(i32, i32, i32) leaf_row = fn(x, z, seed) {
	if (x >= 24) { } else {
		i32 height = coastal_height(x, z, seed);
		if (has_tree(x, z, seed, height)) {
			crown_layer(x, height + 3, z, -2, 2, true);
			crown_layer(x, height + 4, z, -1, 1, false);
			crown_layer(x, height + 5, z, -1, 1, true);
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

unit(i32, i32, i32) write_texel = fn(x, y, tile) {
	i32 speckle = sample_pattern(x, y, tile * 197) % 23 - 11;
	i32 cluster = sample_pattern(x / 3, y / 3, tile * 233) % 25 - 12;
	i32 mark = if ((x * 5 + y * 3 + x * y) % 23 == 0) { 12 } else { 0 };
	i32 noise = speckle + cluster;
	i32 red = 0;
	i32 green = 0;
	i32 blue = 0;
	bool grass = tile == 0 || (tile == 1 && y >= 11 + sample_pattern(x, 0, 55) % 4);
	if (grass) {
		red = 100 + noise + mark;
		green = 157 + noise + mark;
		blue = 55 + noise / 2;
	} else {
		if (tile <= 2) {
			red = 134 + noise;
			green = 92 + noise / 2;
			blue = 57 + noise / 2;
		};
		if (tile == 3) {
			i32 seam = if ((x + y / 4) % 8 == 0 && y % 6 < 4) { -20 } else { 0 };
			red = 131 + noise + seam;
			green = 142 + noise + seam;
			blue = 147 + noise + seam;
		};
		if (tile == 4) {
			red = 211 + noise / 2;
			green = 188 + noise / 2 + mark;
			blue = 125 + noise / 2;
		};
		if (tile == 5) {
			i32 groove = if ((x + sample_pattern(x / 2, 0, 517) % 5) % 4 == 0) { -24 } else { 0 };
			red = 144 + noise + groove;
			green = 100 + noise + groove;
			blue = 57 + noise / 2 + groove;
		};
		if (tile == 6) {
			i32 dx = abs_i(2 * x - 15);
			i32 dy = abs_i(2 * y - 15);
			i32 ring = if (dx > dy) { dx } else { dy };
			i32 grain = if (ring % 6 == 1) { -32 } else { 0 };
			red = 196 + speckle + grain;
			green = 151 + speckle + grain;
			blue = 88 + speckle + grain;
		};
		if (tile == 7) {
			red = 62 + noise + mark;
			green = 122 + noise * 2 + mark;
			blue = 64 + noise / 2;
		};
	};
	u64 ay = index_of(y);
	u64 at = index_of(tile);
	u64 ax = index_of(x);
	block_atlas[ay][at][ax][0] = core.int_trunc<u8>(red);
	block_atlas[ay][at][ax][1] = core.int_trunc<u8>(green);
	block_atlas[ay][at][ax][2] = core.int_trunc<u8>(blue);
	block_atlas[ay][at][ax][3] = 255;
};

unit(i32, i32, i32) atlas_pixels = fn(x, y, tile) {
	if (x < 16) { write_texel(x, y, tile); atlas_pixels(x + 1, y, tile); };
};

unit(i32, i32) atlas_tiles = fn(y, tile) {
	if (tile < 8) { atlas_pixels(0, y, tile); atlas_tiles(y, tile + 1); };
};

unit(i32) atlas_scan = fn(y) {
	if (y < 16) { atlas_tiles(y, 0); atlas_scan(y + 1); };
};

unit() prepare_atlas = fn {
	if (!atlas_ready) {
		atlas_scan(0);
		unsafe { host.atlas(core.pointer_cast<*?u8>(&?block_atlas[0][0][0][0]), 128, 16); };
		atlas_ready = true;
	};
};

i32(u8, i32) face_tile = fn(material, side) {
	if (material == 1) {
		if (side == 3) { 0 } else { if (side == 2) { 2 } else { 1 } }
	} else {
		if (material == 2) { 2 } else {
			if (material == 3) { 3 } else {
				if (material == 4) { 4 } else {
					if (material == 5) { if (side == 2 || side == 3) { 6 } else { 5 } } else { 7 }
				}
			}
		}
	}
};

unit(f32, f32, f32, f32, f32, f32) vertex = fn(x, y, z, u, v, light) {
	i32 at = write_position;
	u64 outer = index_of(at / 13824);
	u64 layer = index_of(at / 576 % 24);
	u64 row = index_of(at / 24 % 24);
	u64 col = index_of(at % 24);
	vertices[outer][layer][row][col][0] = x;
	vertices[outer][layer][row][col][1] = y;
	vertices[outer][layer][row][col][2] = z;
	vertices[outer][layer][row][col][3] = u;
	vertices[outer][layer][row][col][4] = v;
	vertices[outer][layer][row][col][5] = light;
	write_position = at + 1;
};

unit(i32, i32, i32, i32, u8) face = fn(ix, iy, iz, side, material) {
	f32 x = core.sint_to_float<f32>(ix);
	f32 y = core.sint_to_float<f32>(iy);
	f32 z = core.sint_to_float<f32>(iz);
	f32 tile = core.sint_to_float<f32>(face_tile(material, side));
	f32 u0 = tile * 0.125 + 0.00390625;
	f32 u1 = tile * 0.125 + 0.12109375;
	f32 v0 = 0.03125;
	f32 v1 = 0.96875;
	f32 light = if (material == 7) { 1.18 } else {
		if (material == 8) { 1.85 } else {
			if (side == 3) { 1.00 } else { if (side == 2) { 0.57 } else { if (side < 2) { 0.79 } else { 0.89 } } }
		}
	};
	if (side == 0) {
		vertex(x, y, z, u0, v0, light);
		vertex(x, y, z + 1.0, u1, v0, light);
		vertex(x, y + 1.0, z + 1.0, u1, v1, light);
		vertex(x, y, z, u0, v0, light);
		vertex(x, y + 1.0, z + 1.0, u1, v1, light);
		vertex(x, y + 1.0, z, u0, v1, light);
	};
	if (side == 1) {
		vertex(x + 1.0, y, z + 1.0, u0, v0, light);
		vertex(x + 1.0, y, z, u1, v0, light);
		vertex(x + 1.0, y + 1.0, z, u1, v1, light);
		vertex(x + 1.0, y, z + 1.0, u0, v0, light);
		vertex(x + 1.0, y + 1.0, z, u1, v1, light);
		vertex(x + 1.0, y + 1.0, z + 1.0, u0, v1, light);
	};
	if (side == 2) {
		vertex(x, y, z + 1.0, u0, v0, light);
		vertex(x, y, z, u1, v0, light);
		vertex(x + 1.0, y, z, u1, v1, light);
		vertex(x, y, z + 1.0, u0, v0, light);
		vertex(x + 1.0, y, z, u1, v1, light);
		vertex(x + 1.0, y, z + 1.0, u0, v1, light);
	};
	if (side == 3) {
		vertex(x, y + 1.0, z, u0, v0, light);
		vertex(x, y + 1.0, z + 1.0, u1, v0, light);
		vertex(x + 1.0, y + 1.0, z + 1.0, u1, v1, light);
		vertex(x, y + 1.0, z, u0, v0, light);
		vertex(x + 1.0, y + 1.0, z + 1.0, u1, v1, light);
		vertex(x + 1.0, y + 1.0, z, u0, v1, light);
	};
	if (side == 4) {
		vertex(x + 1.0, y, z, u0, v0, light);
		vertex(x, y, z, u1, v0, light);
		vertex(x, y + 1.0, z, u1, v1, light);
		vertex(x + 1.0, y, z, u0, v0, light);
		vertex(x, y + 1.0, z, u1, v1, light);
		vertex(x + 1.0, y + 1.0, z, u0, v1, light);
	};
	if (side == 5) {
		vertex(x, y, z + 1.0, u0, v0, light);
		vertex(x + 1.0, y, z + 1.0, u1, v0, light);
		vertex(x + 1.0, y + 1.0, z + 1.0, u1, v1, light);
		vertex(x, y, z + 1.0, u0, v0, light);
		vertex(x + 1.0, y + 1.0, z + 1.0, u1, v1, light);
		vertex(x, y + 1.0, z + 1.0, u0, v1, light);
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

i32(i32, i32) beacon_ground = fn(x, z) {
	i32 base = if (x >= 1 && x <= 22 && ((z >= 17 && z <= 22) || (z >= 1 && z <= 8))) { 4 } else { 0 };
	if ((x >= 10 && x <= 13 && z == 16) || (x >= 18 && x <= 20 && z >= 15 && z <= 16)) { 4 } else {
		if (x >= 19 && x <= 21 && z >= 13 && z <= 14) { 5 } else {
			if (x >= 20 && x <= 22 && z >= 11 && z <= 12) { 6 } else {
				if (x >= 19 && x <= 21 && z >= 9 && z <= 10) { 4 } else {
					if (x >= 3 && x <= 6 && (z == 8 || z == 16)) { 3 } else {
						if (x >= 3 && x <= 6 && z >= 9 && z <= 15) { 2 } else {
							if (x == 11 && (z == 10 || z == 12 || z == 14)) { 3 } else {
								if (x >= 10 && x <= 13 && z >= 2 && z <= 5) { 5 } else { base }
							}
						}
					}
				}
			}
		}
	}
};

bool(i32, i32, i32) soft_plug = fn(x, y, z) {
	x >= 4 && x <= 5 && z == 12 && (y == 3 || y == 4)
};

bool(i32, i32, i32) bridge_slot = fn(x, y, z) {
	x >= 10 && x <= 13 && y == 4 && z >= 9 && z <= 15
};

u8(i32, i32, i32, i32) beacon_tile = fn(x, y, z, ground) {
	if (x >= 10 && x <= 13 && z >= 2 && z <= 4 && y >= 6 && y <= 11) {
		if (y == 11 && x >= 11 && x <= 12 && z == 3) { 7 } else {
			bool wall = x == 10 || x == 13 || z == 2;
			if (y == 9 || (y == 10 && x >= 11 && x <= 12 && z == 3)) { 3 } else {
				if (y < 9 && wall) { if (y == 7) { 4 } else { 3 } } else { 0 }
			}
		}
	} else {
		if (soft_plug(x, y, z)) { 4 } else {
			bool cut_wall = (x == 3 || x == 6) && (z == 11 || z == 12) && (y == 3 || y == 4);
			bool cut_top = x >= 3 && x <= 6 && (z == 11 || z == 12) && y == 5;
			if (cut_wall || cut_top) { 3 } else {
				if (y > ground) { 0 } else {
					if (y == ground) {
						if (y <= 3 || (x >= 10 && x <= 13 && z >= 2 && z <= 5)) { 4 } else {
							if (z >= 9 && z <= 16 && x >= 18) { 3 } else { 1 }
						}
					} else { if (y >= ground - 2) { 2 } else { 3 } }
				}
			}
		}
	}
};

unit(i32, i32, i32, i32) beacon_column = fn(x, y, z, ground) {
	if (y < 16) {
		world[index_of(y)][index_of(z)][index_of(x)] = beacon_tile(x, y, z, ground);
		beacon_column(x, y + 1, z, ground);
	};
};

unit(i32, i32) beacon_row = fn(x, z) {
	if (x < 24) {
		beacon_column(x, 0, z, beacon_ground(x, z));
		beacon_row(x + 1, z);
	};
};

unit(i32) build_beacon_island = fn(z) {
	if (z < 24) {
		beacon_row(0, z);
		build_beacon_island(z + 1);
	};
};

i32() start_beacon = fn {
	if (beacon_state == 0) {
		sandbox_cells = world;
		sandbox_material = selected_material;
	};
	beacon_state = 1;
	beacon_elapsed = 0.0;
	lamp_wet = 0.0;
	tide_progress = 0.0;
	bridge_blocks = 7;
	sea_level = sea_low;
	sea_phase = 0.0;
	build_beacon_island(0);
	clear_controls();
	camera_x = 11.5;
	camera_y = 5.0 + player_feet;
	camera_z = 21.5;
	yaw = 0.0;
	pitch = -0.10;
	orientation_dirty = true;
	target_dirty = true;
	selected_hit = -2;
	grounded = true;
	flying = false;
	ground_contact_dirty = false;
	vertical_speed = 0.0;
	selected_material = 5;
	prepare_atlas();
	publish_water();
	rebuild()
};

i32() leave_beacon = fn {
	if (beacon_state == 0) { 0 } else {
		beacon_state = 0;
		world = sandbox_cells;
		selected_material = sandbox_material;
		sea_level = sea_low;
		sea_phase = 0.0;
		reset_camera();
		publish_water();
		rebuild()
	}
};

i32(i32) generate = fn(seed) {
	if (beacon_state != 0) { selected_material = sandbox_material; };
	beacon_state = 0;
	sea_level = sea_low;
	i32 bounded = seed % 16381;
	fill_terrain(0, bounded);
	fill_leaves(0, bounded);
	reset_camera();
	prepare_atlas();
	sea_phase = 0.0;
	publish_water();
	rebuild()
};

i32(i32, i32, i32, i32) write_cell = fn(x, y, z, material) {
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

i32(i32, i32, i32, i32) edit = fn(x, y, z, material) {
	if (beacon_state == 0) { write_cell(x, y, z, material) } else { -4 }
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

i32(i32, i32, i32, i32, i32, i32, i32, f32, f32, f32, f32, f32, f32, f32, i32) pick_step = fn(x, y, z, side, sx, sy, sz, tx, ty, tz, dx, dy, dz, reach, remaining) {
	if (cell(x, y, z) != 0) { x + y * 32 + z * 512 + side * 16384 } else {
		bool leaving = (x < 0 && sx <= 0) || (x >= 24 && sx >= 0) || (y < 0 && sy <= 0) || (y >= 16 && sy >= 0) || (z < 0 && sz <= 0) || (z >= 24 && sz >= 0);
		if (remaining == 0 || leaving) { -1 } else {
			if (tx <= ty && tx <= tz) {
				i32 next_side = if (sx > 0) { 0 } else { 1 };
				if (tx <= reach) { pick_step(x + sx, y, z, next_side, sx, sy, sz, tx + dx, ty, tz, dx, dy, dz, reach, remaining - 1) } else { -1 }
			} else {
				if (ty <= tz) {
					i32 next_side = if (sy > 0) { 2 } else { 3 };
					if (ty <= reach) { pick_step(x, y + sy, z, next_side, sx, sy, sz, tx, ty + dy, tz, dx, dy, dz, reach, remaining - 1) } else { -1 }
				} else {
					i32 next_side = if (sz > 0) { 4 } else { 5 };
					if (tz <= reach) { pick_step(x, y, z + sz, next_side, sx, sy, sz, tx, ty, tz + dz, dx, dy, dz, reach, remaining - 1) } else { -1 }
				}
			}
		}
	}
};

i32(f32, f32, f32, f32, f32, f32, f32) pick_in_range = fn(ox, oy, oz, dx, dy, dz, reach) {
	bool inside_ray_range = ox >= -128.0 && ox <= 128.0 && oy >= -128.0 && oy <= 128.0 && oz >= -128.0 && oz <= 128.0;
	bool finite_direction = dx >= -1.0 && dx <= 1.0 && dy >= -1.0 && dy <= 1.0 && dz >= -1.0 && dz <= 1.0;
	if (!inside_ray_range || !finite_direction || (dx == 0.0 && dy == 0.0 && dz == 0.0)) { -1 } else {
		i32 x = floor_i(ox);
		i32 y = floor_i(oy);
		i32 z = floor_i(oz);
		pick_step(x, y, z, 3, step_sign(dx), step_sign(dy), step_sign(dz), first_distance(ox, dx, x), first_distance(oy, dy, y), first_distance(oz, dz, z), distance_delta(dx), distance_delta(dy), distance_delta(dz), reach, 420)
	}
};

i32(f32, f32, f32, f32, f32, f32) pick = fn(ox, oy, oz, dx, dy, dz) {
	pick_in_range(ox, oy, oz, dx, dy, dz, 3.402823466e38)
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
	held_edits = 0;
	repeat_edit_mode = -1;
	repeat_edit_wait = 0.0;
};

unit() reset_camera = fn {
	flying = false;
	spawn_player();
	yaw = -0.72664234;
	pitch = -0.10;
	clear_controls();
	orientation_dirty = true;
};

unit() toggle_flight = fn {
	if (beacon_state == 0) {
		flying = !flying;
		grounded = false;
		ground_contact_dirty = !flying;
		jump_pending = false;
		vertical_speed = 0.0;
	};
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
		f32 immersion = if (!flying && camera_y - player_feet < sea_level + swell + chop) {
			clamp_f((sea_surface(camera_x, camera_z) - (camera_y - player_feet)) / (player_feet + player_head), 0.0, 1.0)
		} else { 0.0 };
		f32 stride = dt * speed * normal * (1.0 - 0.65 * immersion);
		f32 f = core.sint_to_float<f32>(forward);
		f32 r = core.sint_to_float<f32>(right);
		f32 dx = (sy * f + cy * r) * stride;
		f32 dz = (0.0 - cy * f + sy * r) * stride;
		if (!flying) {
			if (ground_contact_dirty) {
				grounded = vertical_speed <= 0.0 && player_collides(camera_x, camera_y - 0.018, camera_z);
				ground_contact_dirty = false;
			};
			if (jump_pending) {
				if (grounded) {
					vertical_speed = 7.4 - 2.0 * immersion;
					grounded = false;
				} else {
					if (immersion >= 0.15 && vertical_speed < 3.8) { vertical_speed = 3.8; };
				};
			};
			f32 lift = if (immersion > 0.0 && active(16) == 1) { 48.0 } else { 35.0 };
			f32 acceleration = lift * immersion - 22.0;
			if (acceleration > 0.0) { grounded = false; };
			vertical_speed = if (grounded) { 0.0 } else {
				f32 damped = vertical_speed * (1.0 - 4.0 * immersion * dt);
				clamp_f(damped + acceleration * dt, -18.0, 8.0)
			};
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

f32(i32) sea_coordinate = fn(index) {
	if (index == 0) { -192.0 } else {
		if (index == 18) { 192.0 } else { core.sint_to_float<f32>(index - 1) * 4.0 - 20.0 }
	}
};

f32(f32, f32) sea_wave = fn(x, z) {
	sea_level + swell * sine(0.23 * x + 0.19 * z - sea_phase)
		+ chop * sine(-0.35 * x + 0.24 * z - 2.0 * sea_phase)
};

unit(i32, i32, f32) sample_sea_row = fn(x, z, pz) {
	if (x < 19) {
		sea_samples[index_of(z)][index_of(x)] = sea_wave(sea_coordinate(x), pz);
		sample_sea_row(x + 1, z, pz);
	};
};

unit(i32) sample_sea = fn(z) {
	if (z < 19) {
		sample_sea_row(0, z, sea_coordinate(z));
		sample_sea(z + 1);
	};
};

f32(f32, f32) sea_surface = fn(x, z) {
	f32 gx = (clamp_f(x, -20.0, 44.0) + 20.0) * 0.25;
	f32 gz = (clamp_f(z, -20.0, 44.0) + 20.0) * 0.25;
	i32 ix = min_i(floor_i(gx), 15);
	i32 iz = min_i(floor_i(gz), 15);
	f32 u = gx - core.sint_to_float<f32>(ix);
	f32 v = gz - core.sint_to_float<f32>(iz);
	u64 left = index_of(ix + 1);
	u64 right = left + 1;
	u64 near = index_of(iz + 1);
	u64 far = near + 1;
	f32 b = sea_samples[near][right];
	f32 c = sea_samples[far][left];
	if (u + v <= 1.0) {
		f32 a = sea_samples[near][left];
		a + (b - a) * u + (c - a) * v
	} else {
		f32 d = sea_samples[far][right];
		d + (c - d) * (1.0 - u) + (b - d) * (1.0 - v)
	}
};

unit(i32, i32, u64, i32, i32) write_sea_vertex = fn(x, z, corner, sx, sz) {
	u64 ix = index_of(x);
	u64 iz = index_of(z);
	if (!sea_mesh_ready) {
		sea_vertices[iz][ix][corner][0] = sea_coordinate(sx);
		sea_vertices[iz][ix][corner][2] = sea_coordinate(sz);
	};
	sea_vertices[iz][ix][corner][1] = sea_samples[index_of(sz)][index_of(sx)];
};

unit(i32, i32) sea_mesh_row = fn(x, z) {
	if (x < 18) {
		write_sea_vertex(x, z, 0, x, z);
		write_sea_vertex(x, z, 1, x, z + 1);
		write_sea_vertex(x, z, 2, x + 1, z);
		write_sea_vertex(x, z, 3, x + 1, z + 1);
		write_sea_vertex(x, z, 4, x + 1, z);
		write_sea_vertex(x, z, 5, x, z + 1);
		sea_mesh_row(x + 1, z);
	};
};

unit(i32) sea_mesh = fn(z) {
	if (z < 18) {
		sea_mesh_row(0, z);
		sea_mesh(z + 1);
	};
};

unit() publish_water = fn {
	sample_sea(0);
	sea_mesh(0);
	sea_mesh_ready = true;
	unsafe { host.water(core.pointer_cast<*?u8>(&?sea_vertices[0][0][0][0]), 1944); };
};

unit(f32, f32, f32, f32, f32, f32, f32, f32, i32) publish_frame = fn(x, y, z, sy, cy, sp, cp, view_pitch, hit) {
	f32 q = view_scale;
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
	frame_values[25] = core.sint_to_float<f32>(beacon_state);
	frame_values[26] = 1.0 - lamp_wet / lamp_limit;
	frame_values[27] = tide_progress;
	frame_values[28] = core.sint_to_float<f32>(bridge_blocks);
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

i32() current_view_target = fn {
	if (target_dirty) {
		f32 dx = sin_yaw * cos_pitch;
		f32 dy = sin_pitch;
		f32 dz = 0.0 - cos_yaw * cos_pitch;
		target_hit = pick_in_range(camera_x, camera_y, camera_z, dx, dy, dz, 5.0);
		target_dirty = false;
	};
	target_hit
};

i32() cycle_camera = fn {
	third_person = !third_person;
	if (third_person) { 1 } else { 0 }
};

unit(f32, f32, f32, f32, f32, f32) avatar_vertex = fn(x, y, z, r, g, b) {
	u64 row = index_of(avatar_position / 24);
	u64 col = index_of(avatar_position % 24);
	avatar_vertices[row][col][0] = camera_x + cos_yaw * x + sin_yaw * z;
	avatar_vertices[row][col][1] = camera_y + y;
	avatar_vertices[row][col][2] = camera_z + sin_yaw * x - cos_yaw * z;
	avatar_vertices[row][col][3] = r;
	avatar_vertices[row][col][4] = g;
	avatar_vertices[row][col][5] = b;
	avatar_position = avatar_position + 1;
};

unit(f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) avatar_face = fn(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz, r, g, b) {
	avatar_vertex(ax, ay, az, r, g, b);
	avatar_vertex(bx, by, bz, r, g, b);
	avatar_vertex(cx, cy, cz, r, g, b);
	avatar_vertex(ax, ay, az, r, g, b);
	avatar_vertex(cx, cy, cz, r, g, b);
	avatar_vertex(dx, dy, dz, r, g, b);
};

unit(f32, f32, f32, f32, f32, f32, f32, f32, f32) avatar_box = fn(x0, x1, y0, y1, z0, z1, r, g, b) {
	avatar_face(x0,y0,z0, x0,y0,z1, x0,y1,z1, x0,y1,z0, r*0.82,g*0.82,b*0.82);
	avatar_face(x1,y0,z1, x1,y0,z0, x1,y1,z0, x1,y1,z1, r*0.94,g*0.94,b*0.94);
	avatar_face(x0,y0,z1, x0,y0,z0, x1,y0,z0, x1,y0,z1, r*0.64,g*0.64,b*0.64);
	avatar_face(x0,y1,z0, x0,y1,z1, x1,y1,z1, x1,y1,z0, r,g,b);
	avatar_face(x1,y0,z0, x0,y0,z0, x0,y1,z0, x1,y1,z0, r*0.89,g*0.89,b*0.89);
	avatar_face(x0,y0,z1, x1,y0,z1, x1,y1,z1, x0,y1,z1, r*0.75,g*0.75,b*0.75);
};

unit(bool) publish_avatar = fn(visible) {
	if (visible) {
		if (!avatar_visible || avatar_x != camera_x || avatar_y != camera_y || avatar_z != camera_z || avatar_yaw != yaw) {
			avatar_x = camera_x;
			avatar_y = camera_y;
			avatar_z = camera_z;
			avatar_yaw = yaw;
			avatar_position = 0;
			avatar_box(-0.19,0.19, -0.23,0.15, -0.18,0.18, 0.91,0.66,0.39);
			avatar_box(-0.2,0.2, -0.84,-0.23, -0.13,0.13, 0.21,0.53,0.39);
			avatar_box(-0.28,-0.202, -0.79,-0.25, -0.095,0.095, 0.63,0.42,0.26);
			avatar_box(0.202,0.28, -0.79,-0.25, -0.095,0.095, 0.63,0.42,0.26);
			avatar_box(-0.17,-0.021, -1.59,-0.84, -0.13,0.13, 0.22,0.32,0.45);
			avatar_box(0.021,0.17, -1.59,-0.84, -0.13,0.13, 0.22,0.32,0.45);
			avatar_box(-0.2,0.2, 0.151,0.178, -0.19,0.19, 0.29,0.17,0.09);
			avatar_box(-0.131,0.131, -0.69,-0.36, -0.193,-0.132, 0.76,0.42,0.21);
			unsafe { host.player(core.pointer_cast<*?u8>(&?avatar_vertices[0][0][0]), avatar_position); };
		};
	} else {
		if (avatar_visible) {
			unsafe { host.player(core.pointer_cast<*?u8>(&?avatar_vertices[0][0][0]), 0); };
		};
	};
	avatar_visible = visible;
};

f32(i32, f32, f32, f32, f32, f32, f32) ray_hit_distance = fn(hit, ox, oy, oz, dx, dy, dz) {
	i32 side = hit / 16384;
	f32 x = core.sint_to_float<f32>(hit % 32);
	f32 y = core.sint_to_float<f32>((hit / 32) % 16);
	f32 z = core.sint_to_float<f32>((hit / 512) % 32);
	if (side < 2 && dx != 0.0) {
		(x + (if (side == 1) { 1.0 } else { 0.0 }) - ox) / dx
	} else {
		if (side >= 4 && dz != 0.0) {
			(z + (if (side == 5) { 1.0 } else { 0.0 }) - oz) / dz
		} else {
			if (dy != 0.0) { (y + (if (side == 3) { 1.0 } else { 0.0 }) - oy) / dy } else { 0.0 }
		}
	}
};

unit() center_aim = fn {
	if (aim_was_offset) {
		host.aim(0.0, 0.0);
		aim_was_offset = false;
	};
};

f32(f32, f32, f32, f32, f32, f32, f32) camera_boom_probe = fn(ox, oy, oz, dx, dy, dz, reach) {
	f32 ex = ox + dx * reach;
	f32 ey = oy + dy * reach;
	f32 ez = oz + dz * reach;
	bool outside = (ox < 0.0 && ex < 0.0) || (ox >= 24.0 && ex >= 24.0)
		|| (oy < 0.0 && ey < 0.0) || (oy >= 16.0 && ey >= 16.0)
		|| (oz < 0.0 && ez < 0.0) || (oz >= 24.0 && ez >= 24.0);
	if (reach <= 0.0 || outside) { reach } else {
		i32 hit = pick_in_range(ox, oy, oz, dx, dy, dz, reach);
		if (hit < 0) { reach } else {
			bool starts_in_hit = hit % 32 == floor_i(ox) && (hit / 32) % 16 == floor_i(oy)
				&& (hit / 512) % 32 == floor_i(oz);
			if (starts_in_hit) { 0.0 } else {
				clamp_f(ray_hit_distance(hit, ox, oy, oz, dx, dy, dz) - 0.29, 0.0, reach)
			}
		}
	}
};

f32(f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) camera_corner = fn(near_x, near_y, near_z, ux, uy, uz, sx, sz, dx, dy, dz, reach) {
	camera_boom_probe(near_x + ux + sx, near_y + uy, near_z + uz + sz, dx, dy, dz, reach)
};

bool(i32, f32, f32, f32, f32, f32, f32) camera_sees_target = fn(hit, view_x, view_y, view_z, target_x, target_y, target_z) {
	f32 dx = target_x - view_x;
	f32 dy = target_y - view_y;
	f32 dz = target_z - view_z;
	f32 ax = if (dx < 0.0) { 0.0 - dx } else { dx };
	f32 ay = if (dy < 0.0) { 0.0 - dy } else { dy };
	f32 az = if (dz < 0.0) { 0.0 - dz } else { dz };
	f32 xy = if (ax > ay) { ax } else { ay };
	f32 reach = if (xy > az) { xy } else { az };
	if (reach <= 0.0) { true } else {
		i32 viewed = pick_in_range(view_x, view_y, view_z, dx / reach, dy / reach, dz / reach, reach);
		viewed >= 0 && viewed % 16384 == hit % 16384
	}
};

unit(i32) publish_play_frame = fn(hit) {
	if (!third_person) {
		publish_avatar(false);
		center_aim();
		publish_frame(camera_x, camera_y, camera_z, sin_yaw, cos_yaw, sin_pitch, cos_pitch, pitch, hit);
	} else {
		f32 fx = sin_yaw * cos_pitch;
		f32 fy = sin_pitch;
		f32 fz = 0.0 - cos_yaw * cos_pitch;
		f32 back = 0.967;
		f32 shoulder = 0.18;
		f32 lift = 0.18;
		f32 dx = 0.0 - back * fx + shoulder * cos_yaw - lift * sin_yaw * sin_pitch;
		f32 dy = 0.0 - back * fy + lift * cos_pitch;
		f32 dz = 0.0 - back * fz + shoulder * sin_yaw + lift * cos_yaw * sin_pitch;
		f32 center = camera_boom_probe(camera_x, camera_y, camera_z, dx, dy, dz, 3.9);
		f32 near_x = camera_x + fx * 0.16;
		f32 near_y = camera_y + fy * 0.16;
		f32 near_z = camera_z + fz * 0.16;
		f32 half_height = 0.16 / view_scale;
		f32 half_width = half_height * frame_values[20];
		f32 ux = 0.0 - sin_yaw * sin_pitch * half_height;
		f32 uy = cos_pitch * half_height;
		f32 uz = cos_yaw * sin_pitch * half_height;
		f32 sx = cos_yaw * half_width;
		f32 sz = sin_yaw * half_width;
		f32 corner0 = camera_corner(near_x, near_y, near_z, ux, uy, uz, sx, sz, dx, dy, dz, center);
		f32 corner1 = camera_corner(near_x, near_y, near_z, ux, uy, uz, 0.0 - sx, 0.0 - sz, dx, dy, dz, corner0);
		f32 corner2 = camera_corner(near_x, near_y, near_z, 0.0 - ux, 0.0 - uy, 0.0 - uz, sx, sz, dx, dy, dz, corner1);
		f32 distance = camera_corner(near_x, near_y, near_z, 0.0 - ux, 0.0 - uy, 0.0 - uz, 0.0 - sx, 0.0 - sz, dx, dy, dz, corner2);
		f32 eye_x = camera_x + dx * distance;
		f32 eye_y = camera_y + dy * distance;
		f32 eye_z = camera_z + dz * distance;
		f32 aim_distance = if (hit < 0) { 5.0 } else {
			clamp_f(ray_hit_distance(hit, camera_x, camera_y, camera_z, fx, fy, fz), 0.0, 5.0)
		};
		f32 aim_check = aim_distance + 0.035;
		bool visible = if (hit < 0) { true } else {
			camera_sees_target(hit, eye_x, eye_y, eye_z,
				camera_x + fx * aim_check, camera_y + fy * aim_check, camera_z + fz * aim_check)
		};
		if (visible) {
			f32 depth = clamp_f(aim_distance + back * distance, 0.16, 9.0);
			f32 projected = view_scale * distance / depth;
			aim_was_offset = true;
			host.aim(clamp_f(0.0 - shoulder * projected / frame_values[20], -0.94, 0.94),
				clamp_f(0.0 - lift * projected, -0.94, 0.94));
			publish_avatar(distance >= 1.42);
			publish_frame(eye_x, eye_y, eye_z, sin_yaw, cos_yaw, sin_pitch, cos_pitch, pitch, hit);
		} else {
			publish_avatar(false);
			center_aim();
			publish_frame(camera_x, camera_y, camera_z, sin_yaw, cos_yaw, sin_pitch, cos_pitch, pitch, hit);
		};
	};
};

unit(f32) update_tide = fn(dt) {
	beacon_elapsed = beacon_elapsed + dt;
	tide_progress = clamp_f((beacon_elapsed - 3.0) / 13.0, 0.0, 1.0);
	sea_level = sea_low + tide_span * tide_progress;
};

bool(f32) update_beacon = fn(dt) {
	bool at_lamp = camera_x >= 11.0 && camera_x < 13.0 && camera_z >= 3.0 && camera_z < 4.0
		&& grounded && camera_y - player_feet >= 5.99 && camera_y - player_feet <= 6.05;
	if (at_lamp) {
		beacon_state = 2;
		world[11][3][11] = 8;
		world[11][3][12] = 8;
		clear_controls();
		true
	} else {
		f32 lantern_y = camera_y - lamp_offset;
		if (lantern_y < sea_level + swell + chop) {
			bool wet = lantern_y < sea_surface(camera_x, camera_z);
			lamp_wet = clamp_f(lamp_wet + (if (wet) { dt } else { 0.0 - 0.65 * dt }), 0.0, lamp_limit);
		} else {
			if (lamp_wet > 0.0) { lamp_wet = clamp_f(lamp_wet - 0.65 * dt, 0.0, lamp_limit); };
		};
		if (lamp_wet >= lamp_limit) { beacon_state = 3; clear_controls(); };
		false
	}
};

unit(f32, f32, i32) tick = fn(dt, aspect, playing) {
	f32 zero = 0.0;
	f32 upper_step = 0.06;
	f32 step = if (dt > zero && dt <= 3.402823466e38) { clamp_f(dt, zero, upper_step) } else { zero };
	frame_values[20] = if (aspect >= 0.05 && aspect <= 20.0) { aspect } else { 1.0 };
	clock_seconds = clock_seconds + step;
	update_orientation();
	if (playing != 0) {
		if (beacon_state < 2) {
			if (step > 0.0) {
				if (beacon_state == 1) { update_tide(step); };
				sea_phase = wrap_yaw(sea_phase + step * 0.92);
				publish_water();
			};
			move_camera(step, sin_yaw, cos_yaw);
			advance_edits(step);
			if (beacon_state == 1 && step > 0.0 && update_beacon(step)) { rebuild(); };
		};
		i32 hit = if (beacon_state >= 2) { -1 } else { current_view_target() };
		publish_outline(hit);
		publish_play_frame(hit);
	} else {
		publish_outline(-1);
		publish_avatar(false);
		center_aim();
		publish_frame(camera_x, camera_y, camera_z, sin_yaw, cos_yaw, sin_pitch, cos_pitch, pitch, -1);
	};
};

i32(i32, i32, i32, i32) edit_beacon = fn(x, y, z, material) {
	if (beacon_state != 1) { -4 } else {
		bool slot = bridge_slot(x, y, z);
		u8 present = cell(x, y, z);
		if (material == 0 && slot && present == 5) {
			write_cell(x, y, z, 0);
			bridge_blocks = bridge_blocks + 1;
			rebuild();
			1
		} else {
			if (material == 0 && soft_plug(x, y, z) && present == 4) {
				write_cell(x, y, z, 0);
				rebuild();
				1
			} else {
				if (material == 5 && slot && present == 0 && bridge_blocks > 0) {
					write_cell(x, y, z, 5);
					bridge_blocks = bridge_blocks - 1;
					rebuild();
					1
				} else { -4 }
			}
		}
	}
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
				if (beacon_state == 0) {
					i32 changed = write_cell(x, y, z, material);
					if (changed == 1) { rebuild(); };
					changed
				} else { edit_beacon(x, y, z, material) }
			}
		} else { -2 }
	}
};

i32(i32) apply_edit_mode = fn(mode) {
	if (mode == 0) { edit_view(0) } else { edit_view(selected_material) }
};

i32(i32, i32) edit_control = fn(mode, state) {
	if (mode != 0 && mode != 1) { 0 } else {
		i32 bit = 1 << mode;
		if (state == 0) {
			held_edits = held_edits & ~bit;
			if (repeat_edit_mode == mode) {
				repeat_edit_mode = if (held_edits == 0) { -1 } else { 1 - mode };
				repeat_edit_wait = 0.24;
			};
			0
		} else {
			if ((held_edits & bit) != 0) { 0 } else {
				if (state == 1) {
					held_edits = held_edits | bit;
					repeat_edit_mode = mode;
					repeat_edit_wait = 0.24;
					apply_edit_mode(mode)
				} else {
					if (state == 2) { apply_edit_mode(mode) } else { 0 }
				}
			}
		}
	}
};

unit(f32) advance_edits = fn(dt) {
	if (repeat_edit_mode >= 0 && dt > 0.0) {
		repeat_edit_wait = repeat_edit_wait - dt;
		if (repeat_edit_wait <= 0.0) {
			apply_edit_mode(repeat_edit_mode);
			repeat_edit_wait = repeat_edit_wait + 0.115;
		};
	};
};

unit(i32) select_material = fn(material) {
	if (beacon_state == 0 && material >= 1 && material <= 6) { selected_material = material; };
};

unit(i32) cycle_material = fn(delta) {
	if (beacon_state == 0 && delta > 0) {
		selected_material = if (selected_material == 6) { 1 } else { selected_material + 1 };
	};
	if (beacon_state == 0 && delta < 0) {
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
