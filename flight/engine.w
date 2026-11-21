%%start
host = extern wasm "flight" {
	unsafe unit(*?u8, i32) world;
	unsafe unit(*?u8, i32) aircraft;
	unsafe unit(*?u8, i32) frame;
	unsafe unit(*?u8, i32) record;
};

f32[6] empty_vertex = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
f32[6][16] mesh_chunk_0 = [empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex];
f32[6][16][16] mesh_chunk_1 = [mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0];
f32[6][16][16][16] mesh_chunk_2 = [mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1];
f32[6][16][16][16][8] scenery = [mesh_chunk_2, mesh_chunk_2, mesh_chunk_2, mesh_chunk_2, mesh_chunk_2, mesh_chunk_2, mesh_chunk_2, mesh_chunk_2];
f32[6][16][16][8] moving_mesh = [mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1];
u8[16] empty_bytes = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
u8[16][16] byte_chunk_0 = [empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes, empty_bytes];
u8[16][16][16] byte_chunk_1 = [byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0, byte_chunk_0];
u16[16] empty_controls = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
u16[16][16] control_chunk_0 = [empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls, empty_controls];
u16[16][16][16] control_chunk_1 = [control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0, control_chunk_0];
u16[16][16][16][2] flight_log = [control_chunk_1, control_chunk_1];
u8[16][16][16][4] best_log = [byte_chunk_1, byte_chunk_1, byte_chunk_1, byte_chunk_1];
u8[16][16][16][4] incoming_log = [byte_chunk_1, byte_chunk_1, byte_chunk_1, byte_chunk_1];
f32[8] initial_pose = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
f32[8][3] poses = [initial_pose, initial_pose, initial_pose];
f32[6] empty_presentation = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
f32[6][2] previous_pose = [empty_presentation, empty_presentation];
f32[6][2] presented_pose = [empty_presentation, empty_presentation];
f32[32] display = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
f32[7] empty_mail = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
f32[7][3] mail = [empty_mail, empty_mail, empty_mail];

i32 course = 0;
i32 vertex_count = 0;
bool world_ready = false;
bool drawing_world = false;
i32[3] phase = [0, 0, 0];
i32[3] result = [0, 0, 0];
i32[3] route = [0, 0, 0];
i32[3] stage_tick = [0, 0, 0];
i32[3] event_code = [0, 0, 0];
bool pending_drop = false;
i32 best_ticks = 0;
i32 incoming_count = 0;

bool incoming_bad = false;
f32 accumulator = 0.0;
f32 viewport = 1.0;
f32 model_x = 0.0;
f32 model_y = 0.0;
f32 model_z = 0.0;
f32 model_hs = 0.0;
f32 model_hc = 1.0;
f32 model_ps = 0.0;
f32 model_pc = 1.0;
f32 model_rs = 0.0;
f32 model_rc = 1.0;
bool model_ghost = false;
bool model_local = false;

u64(i32) ix = fn(value) { core.int_extend<u64>(value) };
f32(f32) abs_f = fn(value) { if (value < 0.0) { -value } else { value } };
f32(f32, f32, f32) clamp = fn(v, lo, hi) { if (v < lo) { lo } else { if (v > hi) { hi } else { v } } };
f32(f32) wrap = fn(a) { if (a > 3.14159265) { a - 6.28318530 } else { if (a < -3.14159265) { a + 6.28318530 } else { a } } };
f32(f32) sin_small = fn(a) {
	f32 u = if (a > 1.57079633) { 3.14159265 - a } else { if (a < -1.57079633) { -3.14159265 - a } else { a } };
	f32 d = u * u;
	u * (1.0 - d * (0.166666667 - d * (0.008333333 - d * 0.000198413)))
};
f32(f32) cos_small = fn(a) { sin_small(wrap(a + 1.57079633)) };
f32(f32, f32, f32) blend = fn(a, b, r) { a + (b - a) * r };
f32(i32) float_i = fn(a) { core.sint_to_float<f32>(a) };



unit(f32, f32, f32, f32, f32, f32) put = fn(x, y, z, r, g, b) {
	i32 i = vertex_count;
	vertex_count = i + 1;
	u64 high = ix(i / 4096);
	u64 layer = ix(i / 256 % 16);
	u64 row = ix(i / 16 % 16);
	u64 cell = ix(i % 16);
	f32 ux = if (model_local) { x * model_rc - y * model_rs } else { x };
	f32 uy = if (model_local) { x * model_rs + y * model_rc } else { y };
	f32 vy = if (model_local) { uy * model_pc + z * model_ps } else { uy };
	f32 vz = if (model_local) { z * model_pc - uy * model_ps } else { z };
	f32 px = if (model_local) { model_x + ux * model_hc + vz * model_hs } else { ux };
	f32 py = if (model_local) { model_y + vy } else { vy };
	f32 pz = if (model_local) { model_z - ux * model_hs + vz * model_hc } else { vz };
	f32 pr = if (model_ghost) { r * 0.19 + 0.28 } else { r };
	f32 pg = if (model_ghost) { g * 0.19 + 0.72 } else { g };
	f32 pb = if (model_ghost) { b * 0.19 + 0.78 } else { b };
	if (drawing_world) {
		scenery[high][layer][row][cell][0] = px;
		scenery[high][layer][row][cell][1] = py;
		scenery[high][layer][row][cell][2] = pz;
		scenery[high][layer][row][cell][3] = pr;
		scenery[high][layer][row][cell][4] = pg;
		scenery[high][layer][row][cell][5] = pb;
	} else {
		moving_mesh[layer][row][cell][0] = px;
		moving_mesh[layer][row][cell][1] = py;
		moving_mesh[layer][row][cell][2] = pz;
		moving_mesh[layer][row][cell][3] = pr;
		moving_mesh[layer][row][cell][4] = pg;
		moving_mesh[layer][row][cell][5] = pb;
	};
};

unit(f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) tri = fn(ax, ay, az, bx, by, bz, cx, cy, cz, r, g, b) {
	put(ax, ay, az, r, g, b);
	put(bx, by, bz, r, g, b);
	put(cx, cy, cz, r, g, b);
};

unit(f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32, f32) quad = fn(ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz, r, g, b) {
	tri(ax, ay, az, bx, by, bz, cx, cy, cz, r, g, b);
	tri(ax, ay, az, cx, cy, cz, dx, dy, dz, r, g, b);
};

unit(f32, f32, f32, f32, f32, f32, f32, f32, f32) box = fn(x, y, z, w, h, l, r, g, b) {
	f32 x1 = x+w;
	f32 y1 = y+h;
	f32 z1 = z+l;
	quad(x,y,z, x1,y,z, x1,y1,z, x,y1,z, r*0.85,g*0.85,b*0.85);
	quad(x1,y,z1, x,y,z1, x,y1,z1, x1,y1,z1, r,g,b);
	quad(x,y,z1, x,y,z, x,y1,z, x,y1,z1, r*0.77,g*0.77,b*0.77);
	quad(x1,y,z, x1,y,z1, x1,y1,z1, x1,y1,z, r*0.93,g*0.93,b*0.93);
	quad(x,y1,z, x1,y1,z, x1,y1,z1, x,y1,z1, r*1.12,g*1.12,b*1.12);
};

unit(f32, f32, f32, f32, f32, f32, f32, f32) diamond = fn(x, y, z, wide, tall, r, g, b) {
	tri(x-wide,y,z, x,y+tall,z, x,y,z+wide,r,g,b);
	tri(x,y,z+wide, x,y+tall,z, x+wide,y,z,r*0.89,g*0.89,b*0.89);
	tri(x+wide,y,z, x,y+tall,z, x,y,z-wide,r*0.77,g*0.77,b*0.77);
	tri(x,y,z-wide, x,y+tall,z, x-wide,y,z,r*0.95,g*0.95,b*0.95);
};

unit(f32, f32, f32) tree = fn(x, z, size) {
	box(x-0.7,0.0,z-0.7,1.4,4.0,1.4,0.39,0.26,0.15);
	diamond(x,3.5,z,size,size*2.0,0.19,0.47,0.29);
	diamond(x,2.7,z,size*0.9,size*1.0,0.24,0.54,0.33);
};

unit(f32,f32,f32,f32,f32,f32) barn_face = fn(x,z,width,base,height,shade) {
	f32 half = width*0.5;
	quad(x-half,base,z,x+half,base,z,x+half,base+height,z,x-half,base+height,z,shade,shade*0.68,shade*0.47);
};

unit(f32,f32) barn_doors = fn(x,z) {
	barn_face(x,z,9.4,0.04,8.2,0.74);
	barn_face(x,z+0.035,8.8,0.14,7.9,0.33);
	barn_face(x,z+0.065,0.23,0.13,8.1,0.81);
	quad(x-4.3,0.18,z+0.08,x-3.9,0.18,z+0.08,x+4.3,7.6,z+0.08,x+3.9,7.6,z+0.08,0.92,0.79,0.60);
	quad(x+4.3,0.18,z+0.08,x+3.9,0.18,z+0.08,x-4.3,7.6,z+0.08,x-3.9,7.6,z+0.08,0.92,0.79,0.60);
};

unit(f32, f32) barn = fn(x, z) {
	box(x-15.0,0.0,z-12.0,30.0,11.0,24.0,0.64,0.27,0.19);
	quad(x-16.0,11.0,z-13.0,x,18.0,z-13.0,x,18.0,z+13.0,x-16.0,11.0,z+13.0,0.36,0.20,0.20);
	quad(x,18.0,z-13.0,x+16.0,11.0,z-13.0,x+16.0,11.0,z+13.0,x,18.0,z+13.0,0.29,0.16,0.18);
	tri(x-15.0,11.0,z-12.0,x+15.0,11.0,z-12.0,x,18.0,z-12.0,0.72,0.36,0.24);
	tri(x-15.0,11.0,z+12.0,x+15.0,11.0,z+12.0,x,18.0,z+12.0,0.72,0.36,0.24);
	barn_doors(x,z+12.07);
	f32 rear = z-12.07;
	barn_face(x,rear,10.2,0.1,7.8,0.74);
	barn_face(x,rear-0.04,9.5,0.13,7.48,0.34);
	quad(x-4.6,0.19,rear-0.08,x-4.18,0.19,rear-0.08,x+4.6,7.3,rear-0.08,x+4.18,7.3,rear-0.08,0.90,0.79,0.61);
	quad(x+4.6,0.19,rear-0.08,x+4.18,0.19,rear-0.08,x-4.6,7.3,rear-0.08,x-4.18,7.3,rear-0.08,0.90,0.79,0.61);
	barn_face(x,z+12.03,3.0,12.9,2.7,0.32);
	barn_face(x,rear,3.0,12.9,2.7,0.32);
	quad(x-15.06,7.5,z-10.0,x-15.06,7.5,z+10.0,x-15.06,8.1,z+10.0,x-15.06,8.1,z-10.0,0.84,0.57,0.40);
	quad(x+15.06,7.5,z-10.0,x+15.06,7.5,z+10.0,x+15.06,8.1,z+10.0,x+15.06,8.1,z-10.0,0.84,0.57,0.40);
};

unit(f32,f32,f32,f32,f32,f32,f32,f32) ground_patch = fn(x,z,w,l,y,r,g,b) {
	quad(x,y,z,x+w,y,z,x+w,y,z+l,x,y,z+l,r,g,b);
};

unit(f32,f32,i32,i32) furrows = fn(x,z,j,k) {
	if (k < 15) {
		f32 offset = 5.0 + float_i(k)*8.2;
		f32 crop = float_i((j*3+k*7)%5)*0.013;
		if (j % 3 == 0) {
			ground_patch(x+4.0,z+offset,126.0,3.8,0.033,0.46+crop,0.34+crop,0.18);
			ground_patch(x+4.0,z+offset+2.6,126.0,0.95,0.037,0.65+crop,0.51+crop,0.24);
		} else {
			ground_patch(x+offset,z+4.0,4.1,134.0,0.033,0.29+crop,0.41+crop,0.19);
			ground_patch(x+offset+1.2,z+4.0,1.0,134.0,0.037,0.47+crop,0.58+crop,0.24);
		};
		furrows(x,z,j,k+1);
	};
};

unit(f32,f32,i32) fence = fn(x,z,i) {
	f32 dx = x+float_i(i)*7.5;
	box(dx,0.0,z,0.38,2.55,0.40,0.53,0.40,0.24);
	if (i < 8) {
		box(dx,1.03,z+0.10,7.8,0.16,0.16,0.64,0.47,0.26);
		box(dx,1.90,z+0.10,7.8,0.16,0.16,0.61,0.46,0.27);
		fence(x,z,i+1);
	};
};

unit(f32,f32,i32) hay_roll = fn(x,z,i) {
	if (i < 8) {
		f32 a = wrap(float_i(i)*0.785398163);
		f32 b = wrap(a+0.785398163);
		f32 ax = x + 2.1*cos_small(a);
		f32 az = z + 2.1*sin_small(a);
		f32 bx = x + 2.1*cos_small(b);
		f32 bz = z + 2.1*sin_small(b);
		f32 light = float_i(i%3)*0.042;
		tri(x,2.39,z,ax,2.39,az,bx,2.39,bz,0.89+light,0.69+light,0.30);
		quad(ax,0.03,az,bx,0.03,bz,bx,2.39,bz,ax,2.39,az,0.74+light,0.53+light,0.21);
		hay_roll(x,z,i+1);
	};
};

unit(i32) fields = fn(j) {
	if (j < 24) {
		f32 x = float_i(j % 6)*145.0-430.0;
		f32 z = float_i(j / 6)*155.0-230.0;
		f32 tone = float_i(j*7%13)*0.009;
		quad(x,0.01,z,x+136.0,0.01,z,x+136.0,0.01,z+144.0,x,0.01,z+144.0,0.35+tone,0.52+tone,0.27+tone*0.45);
		if (j % 4 != 2) { furrows(x,z,j,0); };
		tree(x+2.0,z,3.6);
		tree(x+9.0,z+4.0,3.0);
		fields(j+1);
	};
};

f32() tower_x = fn { 228.0 };
f32() tower_z = fn { 359.0 };

bool(f32,f32) city_lot = fn(x,z) {
	!(x == 216.0 && z == 90.0) && abs_f(z-(x*0.49+155.0)) > 58.0 && (abs_f(x-tower_x()) > 66.0 || abs_f(z-tower_z()) > 72.0) &&
	(x > -82.0 || z < -6.0 || z > 232.0) && (abs_f(x)>44.0 || z>175.0 || z< -65.0)
};

unit(f32,f32,i32,f32,f32,f32,f32,f32,f32,f32) facade_quad = fn(x,z,face,u,y,w,h,r,g,b) {
	if (face < 2) {
		f32 side = if (face == 0) { z-0.045 } else { z+27.045 };
		quad(x+u,y,side,x+u+w,y,side,x+u+w,y+h,side,x+u,y+h,side,r,g,b);
	} else {
		f32 side = if (face == 2) { x-0.045 } else { x+28.045 };
		quad(side,y,z+u,side,y,z+u+w,side,y+h,z+u+w,side,y+h,z+u,r,g,b);
	};
};

unit(f32,f32,i32,f32,i32,i32) window_row = fn(x,z,face,y,col,style) {
	if (col < 3) {
		f32 u = 4.6+float_i(col)*7.5;
		f32 navy = float_i((col+face+style)%3)*0.055;
		facade_quad(x,z,face,u,y,3.4,2.6,0.24+navy,0.34+navy,0.40+navy);
		window_row(x,z,face,y,col+1,style);
	};
};

unit(f32,f32,f32,i32,i32,i32) window_storeys = fn(x,z,height,face,floor,style) {
	f32 y = 2.7 + float_i(floor)*4.3;
	if (floor < 4 && y+2.8 < height) {
		window_row(x,z,face,y,0,style);
		facade_quad(x,z,face,4.35,y-0.32,19.0,0.32,0.94,0.80,0.63);
		window_storeys(x,z,height,face,floor+1,style);
	};
};

unit(f32,f32,f32,i32,i32) street_walls = fn(x,z,h,face,style) {
	if (face < 4) {
		window_storeys(x,z,h,face,0,style);
		facade_quad(x,z,face,0.85,0.9,0.57,h-1.15,0.90,0.77,0.60);
		facade_quad(x,z,face,25.95,0.9,0.57,h-1.15,0.90,0.77,0.60);
		facade_quad(x,z,face,1.6,h-0.65,24.0,0.48,0.86,0.71,0.56);
		facade_quad(x,z,face,1.6,0.7,24.0,0.40,0.63,0.54,0.49);
		street_walls(x,z,h,face+1,style);
	};
};

unit(f32,f32,f32,i32) roof = fn(x,z,h,style) {
	f32 r = if (style % 4 == 0) { 0.59 } else { 0.40 };
	f32 g = if (style % 4 == 0) { 0.43 } else { 0.44 };
	box(x-1.0,h,z-1.0,30.0,0.52,29.0,0.79,0.70,0.53);
	quad(x-1.0,h+0.52,z-1.0,x+29.0,h+0.52,z-1.0,x+24.0,h+2.78,z+5.0,x+4.0,h+2.78,z+5.0,r,g,0.55);
	quad(x-1.0,h+0.52,z+28.0,x+29.0,h+0.52,z+28.0,x+24.0,h+2.78,z+22.0,x+4.0,h+2.78,z+22.0,r*0.83,g*0.83,0.46);
	quad(x-1.0,h+0.52,z+28.0,x-1.0,h+0.52,z-1.0,x+4.0,h+2.78,z+5.0,x+4.0,h+2.78,z+22.0,r*0.91,g*0.91,0.49);
	quad(x+29.0,h+0.52,z-1.0,x+29.0,h+0.52,z+28.0,x+24.0,h+2.78,z+22.0,x+24.0,h+2.78,z+5.0,r*0.94,g*0.94,0.50);
	quad(x+4.0,h+2.78,z+5.0,x+24.0,h+2.78,z+5.0,x+24.0,h+2.78,z+22.0,x+4.0,h+2.78,z+22.0,r*1.13,g*1.13,0.62);
};

unit(i32) city = fn(i) {
	if (i < 96) {
		f32 x = float_i(i%12)*56.0-344.0;
		f32 z = float_i(i/12)*59.0-205.0;
		f32 h = float_i(8+i*11%18);
		if (city_lot(x,z)) {
			f32 tint = float_i(i%4)*0.037;
			box(x,0.0,z,28.0,h,27.0,0.80+tint*0.45,0.64+tint,0.49+tint*0.5);
			street_walls(x,z,h,0,i);
			roof(x,z,h,i);
		};
		city(i+1);
	};
};

unit(f32,f32,f32,f32,f32,f32,f32,f32) iron_leg = fn(sx,sz,y0,y1,base,crown,wide,thin) {
	f32 ax = tower_x() + sx*base;
	f32 az = tower_z() + sz*base;
	f32 bx = tower_x() + sx*crown;
	f32 bz = tower_z() + sz*crown;
	quad(ax-wide,y0,az-wide, ax+wide,y0,az-wide, bx+thin,y1,bz-thin, bx-thin,y1,bz-thin, 0.47,0.36,0.31);
	quad(ax+wide,y0,az+wide, ax-wide,y0,az+wide, bx-thin,y1,bz+thin, bx+thin,y1,bz+thin, 0.58,0.44,0.34);
	quad(ax-wide,y0,az+wide, ax-wide,y0,az-wide, bx-thin,y1,bz-thin, bx-thin,y1,bz+thin, 0.42,0.33,0.31);
	quad(ax+wide,y0,az-wide, ax+wide,y0,az+wide, bx+thin,y1,bz+thin, bx+thin,y1,bz-thin, 0.62,0.48,0.37);
};

unit(i32,f32,f32,f32,f32,f32,f32) iron_face_vertex = fn(face,u,y,d,r,g,b) {
	f32 x = if (face == 0) { u } else { if (face == 1) { -u } else { if (face == 2) { d } else { -d } } };
	f32 z = if (face == 0) { d } else { if (face == 1) { -d } else { if (face == 2) { -u } else { u } } };
	f32 tint = if (face == 0 || face == 2) { 1.0 } else { 0.84 };
	put(tower_x()+x,y,tower_z()+z,r*tint,g*tint,b*tint);
};

unit(i32,f32,f32,f32,f32,f32,f32,f32,f32,f32) iron_band = fn(face,a,y0,d0,b,y1,d1,w,r,g) {
	iron_face_vertex(face,a-w,y0,d0,r,g,0.31);
	iron_face_vertex(face,a+w,y0,d0,r,g,0.31);
	iron_face_vertex(face,b+w,y1,d1,r,g,0.31);
	iron_face_vertex(face,a-w,y0,d0,r,g,0.31);
	iron_face_vertex(face,b+w,y1,d1,r,g,0.31);
	iron_face_vertex(face,b-w,y1,d1,r,g,0.31);
};

unit(i32,f32,f32,f32,f32,f32) iron_tie = fn(face,e,y,d,width,tint) {
	iron_face_vertex(face,-e,y,d,tint,tint*0.79,0.27);
	iron_face_vertex(face,e,y,d,tint,tint*0.79,0.27);
	iron_face_vertex(face,e,y+width,d,tint,tint*0.79,0.27);
	iron_face_vertex(face,-e,y,d,tint,tint*0.79,0.27);
	iron_face_vertex(face,e,y+width,d,tint,tint*0.79,0.27);
	iron_face_vertex(face,-e,y+width,d,tint,tint*0.79,0.27);
};

unit(i32,i32) iron_arch = fn(face,i) {
	if (i < 12) {
		f32 t0 = float_i(i)/6.0-1.0;
		f32 t1 = float_i(i+1)/6.0-1.0;
		f32 a = t0*17.6;
		f32 b = t1*17.6;
		f32 y0 = 4.4 + 14.6*(1.0-t0*t0);
		f32 y1 = 4.4 + 14.6*(1.0-t1*t1);
		f32 d0 = 20.0-y0*0.29;
		f32 d1 = 20.0-y1*0.29;
		iron_face_vertex(face,a,y0,d0,0.58,0.43,0.32);
		iron_face_vertex(face,b,y1,d1,0.58,0.43,0.32);
		iron_face_vertex(face,b,y1+2.05,d1-0.47,0.64,0.48,0.35);
		iron_face_vertex(face,a,y0,d0,0.58,0.43,0.32);
		iron_face_vertex(face,b,y1+2.05,d1-0.47,0.64,0.48,0.35);
		iron_face_vertex(face,a,y0+2.05,d0-0.47,0.64,0.48,0.35);
		iron_arch(face,i+1);
	};
};

unit(i32,f32,f32,f32,f32,f32) iron_lattice = fn(face,y0,y1,e0,e1,width) {
	iron_band(face,-e0,y0,e0,e1,y1,e1,width,0.64,0.49);
	iron_band(face,e0,y0,e0+0.13,-e1,y1,e1+0.13,width,0.52,0.42);
	iron_tie(face,(e0+e1)*0.5,(y0+y1)*0.5,(e0+e1)*0.5+0.29,width,0.53);
};

unit(i32) tower_faces = fn(face) {
	if (face < 4) {
		iron_arch(face,0);
		iron_lattice(face,25.4,42.3,11.8,6.5,0.42);
		iron_lattice(face,45.1,52.0,5.9,4.35,0.29);
		iron_lattice(face,52.0,57.0,4.35,3.2,0.24);
		iron_lattice(face,57.0,63.8,3.2,2.42,0.19);
		iron_lattice(face,63.8,70.0,2.42,1.8,0.15);
		tower_faces(face+1);
	};
};

unit(f32,f32) tower_corner = fn(sx,sz) {
	box(tower_x()+sx*18.0-4.0,0.0,tower_z()+sz*18.0-4.0,8.0,2.35,8.0,0.52,0.43,0.35);
	iron_leg(sx,sz,2.35,11.0,18.0,15.6,2.9,2.43);
	iron_leg(sx,sz,11.0,23.4,15.6,12.5,2.43,1.87);
	iron_leg(sx,sz,25.2,43.0,11.9,6.3,1.66,1.18);
	iron_leg(sx,sz,44.8,57.0,5.95,3.2,1.03,0.66);
	iron_leg(sx,sz,57.0,70.5,3.2,1.77,0.66,0.43);
};

unit(f32,f32,f32) tower_deck = fn(y,half,h) {
	box(tower_x()-half,y,tower_z()-half,half*2.0,h,half*2.0,0.43,0.34,0.30);
	f32 ring = half+0.28;
	box(tower_x()-ring,y+h,tower_z()-ring,ring*2.0,0.44,ring*2.0,0.66,0.52,0.36);
	box(tower_x()-ring,y+h+0.44,tower_z()-ring,ring*2.0,0.8,0.22,0.52,0.42,0.32);
	box(tower_x()-ring,y+h+0.44,tower_z()+ring-0.22,ring*2.0,0.8,0.22,0.52,0.42,0.32);
	box(tower_x()-ring,y+h+0.44,tower_z()-ring+0.22,0.22,0.8,ring*2.0-0.44,0.52,0.42,0.32);
	box(tower_x()+ring-0.22,y+h+0.44,tower_z()-ring+0.22,0.22,0.8,ring*2.0-0.44,0.52,0.42,0.32);
};

unit() tower = fn {
	ground_patch(tower_x()-23.0,tower_z()-23.0,46.0,46.0,0.08,0.78,0.73,0.60);
	tower_corner(1.0,1.0);
	tower_corner(-1.0,1.0);
	tower_corner(1.0,-1.0);
	tower_corner(-1.0,-1.0);
	tower_faces(0);
	tower_deck(23.35,15.1,1.53);
	tower_deck(42.45,8.07,2.0);
	tower_deck(69.65,3.0,1.17);
	box(tower_x()-1.48,71.27,tower_z()-1.48,2.96,4.5,2.96,0.56,0.44,0.33);
	diamond(tower_x(),75.78,tower_z(),2.38,2.4,0.46,0.40,0.30);
	box(tower_x()-0.37,77.0,tower_z()-0.37,0.74,6.46,0.74,0.46,0.39,0.33);
	diamond(tower_x(),83.45,tower_z(),0.44,0.55,0.68,0.53,0.36);
};

f32() strip_x = fn { if (course == 0) { -15.0 } else { 125.0 } };
f32() strip_z = fn { if (course == 0) { 167.0 } else { 290.0 } };
f32() strip_w = fn { if (course == 0) { 25.0 } else { 41.0 } };
f32() strip_l = fn { if (course == 0) { 60.0 } else { 124.0 } };
f32() drop_x = fn { 109.0 };
f32() drop_z = fn { 218.0 };

unit(i32) runway_marks = fn(n) {
	if (n < 10) {
		f32 z = strip_z() + strip_l()*0.055 + float_i(n) * strip_l()/10.0;
		box(strip_x()-0.9,0.25,z,1.8,0.03,strip_l()*0.042,0.95,0.89,0.69);
		box(strip_x()-strip_w()/2.0-0.3,0.20,z,0.6,0.13,strip_l()*0.034,0.92,0.74,0.31);
		box(strip_x()+strip_w()/2.0-0.3,0.20,z,0.6,0.13,strip_l()*0.034,0.92,0.74,0.31);
		runway_marks(n+1);
	};
};

unit() runway = fn {
	f32 x = strip_x();
	f32 z = strip_z();
	f32 w = strip_w();
	f32 l = strip_l();
	box(x-w/2.0,0.14,z,w,0.12,l,0.42,0.40,0.34);
	box(x-w/2.0+1.0,0.28,z+7.0,w-2.0,0.10,2.0,0.93,0.83,0.61);
	box(x-w/2.0+1.0,0.28,z+l-10.0,w-2.0,0.10,2.0,0.93,0.83,0.61);
	runway_marks(0);
};

unit() mail_landmarks = fn {
	f32 x = drop_x();
	f32 z = drop_z();
	ground_patch(x-10.0,z-10.0,20.0,20.0,0.18,0.22,0.40,0.44);
	ground_patch(x-5.0,z-0.6,10.0,1.2,0.21,0.96,0.70,0.29);
	ground_patch(x-0.6,z-5.0,1.2,10.0,0.22,0.96,0.70,0.29);
	box(x-6.0,0.21,z-6.0,0.35,4.0,0.35,0.83,0.76,0.60);
	box(x+5.65,0.21,z-6.0,0.35,4.0,0.35,0.83,0.76,0.60);
	box(x-6.0,4.30,z-6.0,2.1,0.95,0.14,0.97,0.62,0.24);
	box(x+4.0,4.30,z-6.0,2.0,0.95,0.14,0.97,0.62,0.24);
	ground_patch(4.0,142.0,8.0,3.4,0.13,0.23,0.91,0.95);
	ground_patch(20.0,154.0,8.0,3.4,0.13,0.23,0.91,0.95);
	ground_patch(37.0,166.0,8.0,3.4,0.13,0.23,0.91,0.95);
	ground_patch(14.0,131.0,8.0,3.4,0.13,0.98,0.76,0.36);
	ground_patch(36.0,146.0,8.0,3.4,0.13,0.98,0.76,0.36);
	ground_patch(61.0,157.0,8.0,3.4,0.13,0.98,0.76,0.36);
	ground_patch(80.0,173.0,8.0,3.4,0.13,0.98,0.76,0.36);
};

unit(f32,f32,i32) bank_details = fn(x,z,i) {
	if (i < 27) {
		f32 cx = x+float_i(i)*24.0;
		f32 cz = z+float_i(i)*11.76;
		ground_patch(cx,cz,1.0,2.8,0.077,0.57,0.52,0.43);
		if (i < 4 || i > 23) { tree(cx,cz+5.0,3.1); };
		bank_details(x,z,i+1);
	};
};

unit(f32,f32,f32,f32) promenade = fn(x0,z0,x1,z1) {
	quad(x0,0.063,z0,x1,0.063,z1,x1,0.063,z1+5.2,x0,0.063,z0+5.2,0.77,0.70,0.56);
	quad(x0,0.071,z0+1.2,x1,0.071,z1+1.2,x1,0.071,z1+1.75,x0,0.071,z0+1.75,0.89,0.82,0.67);
};

unit(f32,f32,f32,i32) bridge_stones = fn(x,z,w,i) {
	if (i < 6) {
		f32 start = z+3.0+float_i(i)*19.0;
		f32 end = start+12.4;
		quad(x-0.012,0.7,start,x-0.012,0.7,end,x-0.012,2.7,end-1.5,x-0.012,2.7,start+1.5,0.48,0.44,0.42);
		quad(x+w+0.012,0.7,start,x+w+0.012,0.7,end,x+w+0.012,2.7,end-1.5,x+w+0.012,2.7,start+1.5,0.48,0.44,0.42);
		bridge_stones(x,z,w,i+1);
	};
};

unit(f32,f32,f32) bridge = fn(x,z,w) {
	box(x,0.30,z,w,3.65,119.0,0.76,0.66,0.51);
	box(x,3.95,z,0.76,0.35,119.0,0.58,0.49,0.45);
	box(x+w-0.76,3.95,z,0.76,0.35,119.0,0.58,0.49,0.45);
	box(x+w*0.46,3.95,z,w*0.08,0.03,119.0,0.87,0.80,0.64);
	bridge_stones(x,z,w,0);
};

unit() render_land = fn {
	vertex_count = 0;
	drawing_world = true;
	model_local = false;
	model_ghost = false;
	if (course == 0) {
		quad(-480.0,0.0,-350.0,480.0,0.0,-350.0,480.0,0.0,570.0,-480.0,0.0,570.0,0.44,0.58,0.31);
		fields(0);
		barn(145.0,97.0);
		barn(-61.0,164.0);
		box(164.0,0.0,112.0,5.5,14.0,5.5,0.57,0.53,0.44);
		diamond(166.75,14.0,114.75,3.4,3.8,0.64,0.56,0.49);
		box(-100.0,0.05,132.0,270.0,0.10,6.0,0.63,0.53,0.34);
		box(54.0,0.05,-52.0,7.0,0.10,343.0,0.57,0.48,0.33);
		fence(70.0,127.0,0);
		fence(-245.0,44.0,0);
		hay_roll(-232.0,31.0,0);
		hay_roll(-223.0,29.0,0);
		hay_roll(-217.0,33.0,0);
		hay_roll(190.0,119.0,0);
	} else {
		quad(-450.0,0.0,-320.0,450.0,0.0,-320.0,450.0,0.0,450.0,-450.0,0.0,450.0,0.54,0.62,0.47);
		quad(-450.0,0.025,-117.0,450.0,0.025,324.0,450.0,0.025,427.0,-450.0,0.025,-14.0,0.29,0.52,0.67);
		quad(-450.0,0.055,-117.0,450.0,0.055,324.0,450.0,0.055,319.0,-450.0,0.055,-122.0,0.73,0.69,0.55);
		quad(-450.0,0.055,-14.0,450.0,0.055,427.0,450.0,0.055,432.0,-450.0,0.055,-9.0,0.73,0.69,0.55);
		promenade(-450.0,-125.0,450.0,316.0);
		promenade(-450.0,-8.0,450.0,433.0);
		bank_details(-400.0,-98.0,0);
		bank_details(-400.0,18.5,0);
		bridge(54.0,172.0,10.0);
		box(54.0,4.30,172.0,10.0,4.70,119.0,0.69,0.60,0.50);
		box(54.0,9.00,172.0,0.65,0.35,119.0,0.80,0.70,0.58);
		box(63.35,9.00,172.0,0.65,0.35,119.0,0.80,0.70,0.58);
		bridge(158.0,221.0,12.0);
		city(0);
		tower();
		mail_landmarks();
	};
	runway();
	i32 count = vertex_count * 6;
	unsafe { host.world(core.pointer_cast<*?u8>(&?scenery[0][0][0][0][0]), count); };
};

unit(f32,f32,i32) wing_post = fn(x,z,kind) {
	f32 h = if (kind == 0) { 1.40 } else { 1.6 };
	box(x-0.055,-0.35,z-0.055,0.11,h,0.11,0.46,0.31,0.16);
};

unit(f32,f32,f32,f32,f32,f32,f32,f32,f32) cloth_sides = fn(x,y,z,w,h,l,r,g,b) {
	f32 x1 = x+w;
	f32 y1 = y+h;
	f32 z1 = z+l;
	quad(x,y,z,x1,y,z,x1,y1,z,x,y1,z,r*0.85,g*0.85,b*0.85);
	quad(x1,y,z1,x,y,z1,x,y1,z1,x1,y1,z1,r,g,b);
	quad(x,y,z1,x,y,z,x,y1,z,x,y1,z1,r*0.77,g*0.77,b*0.77);
	quad(x1,y,z,x1,y,z1,x1,y1,z1,x1,y1,z,r*0.93,g*0.93,b*0.93);
};

unit(f32,f32,f32,f32,f32,f32,f32,f32) flag_rect = fn(x,y,z,w,l,r,g,b) {
	quad(x,y,z,x+w,y,z,x+w,y,z+l,x,y,z+l,r,g,b);
};

unit(f32,f32,f32,f32) flag_star = fn(x,y,z,size) {
	quad(x-size,y,z,x,y,z-size,x+size,y,z,x,y,z+size,0.97,0.97,0.9);
};

unit(f32,f32,f32,f32,i32) flag_globe = fn(x,y,z,radius,index) {
	if (index < 16) {
		f32 a = wrap(float_i(index) * 0.39269908);
		f32 b = wrap(float_i(index+1) * 0.39269908);
		tri(x,y,z,x+sin_small(a)*radius,y,z+cos_small(a)*radius,
			x+sin_small(b)*radius,y,z+cos_small(b)*radius,0.028,0.248,0.63);
		flag_globe(x,y,z,radius,index+1);
	};
};

unit(f32,f32,f32,f32,f32) brazilian_flag = fn(x,y,z,w,l) {
	flag_rect(x,y,z,w,l,0.035,0.59,0.25);
	f32 cx = x+w*0.5;
	f32 cz = z+l*0.5;
	f32 gold = y+0.025;
	quad(cx-w*0.44,gold,cz,cx,gold,cz-l*0.43,cx+w*0.44,gold,cz,cx,gold,cz+l*0.43,1.0,0.84,0.12);
	f32 blue = y+0.050;
	f32 radius = l*0.262;
	flag_globe(cx,blue,cz,radius,0);
	f32 band = y+0.075;
	quad(cx-radius*0.86,band,cz+radius*0.36,cx-radius*0.32,band,cz+radius*0.10,
		cx-radius*0.32,band,cz+radius*0.27,cx-radius*0.86,band,cz+radius*0.52,0.98,0.96,0.83);
	quad(cx-radius*0.32,band,cz+radius*0.10,cx+radius*0.31,band,cz-radius*0.17,
		cx+radius*0.31,band,cz+radius*0.00,cx-radius*0.32,band,cz+radius*0.27,0.98,0.96,0.83);
	quad(cx+radius*0.31,band,cz-radius*0.17,cx+radius*0.88,band,cz-radius*0.27,
		cx+radius*0.88,band,cz-radius*0.12,cx+radius*0.31,band,cz+radius*0.00,0.98,0.96,0.83);
	flag_star(cx-radius*0.47,band,cz-radius*0.36,radius*0.066);
	flag_star(cx+radius*0.05,band,cz-radius*0.51,radius*0.052);
	flag_star(cx+radius*0.44,band,cz+radius*0.32,radius*0.069);
	flag_star(cx+radius*0.02,band,cz+radius*0.58,radius*0.046);
};

unit(f32,f32,f32,f32,f32,i32) usa_stripes = fn(x,y,z,w,l,index) {
	if (index < 13) {
		f32 left = if (index < 7) { w*0.43 } else { 0.0 };
		f32 start = z+l*float_i(index)/13.0;
		f32 end = z+l*float_i(index+1)/13.0;
		bool red = index % 2 == 0;
		f32 color = if (red) { 0.18 } else { 0.95 };
		quad(x+left,y,start,x+w,y,start,x+w,y,end,x+left,y,end,0.94,color,color);
		usa_stripes(x,y,z,w,l,index+1);
	};
};

unit(f32,f32,f32,f32,f32,i32) usa_stars = fn(x,y,z,w,l,index) {
	if (index < 9) {
		f32 offset_x = w*(0.19+0.30*float_i(index%3)+0.04*float_i(index/3%2));
		f32 offset_z = l*(0.19+0.30*float_i(index/3));
		flag_star(x+offset_x,y,z+offset_z,l*0.057);
		usa_stars(x,y,z,w,l,index+1);
	};
};

unit() american_flag = fn {
	f32 x = 0.68;
	f32 y = 1.149;
	f32 z = -0.73;
	f32 w = 3.81;
	f32 l = 1.58;
	f32 canton_w = w*0.43;
	f32 canton_l = l*7.0/13.0;
	flag_rect(x,y,z,canton_w,canton_l,0.095,0.24,0.64);
	usa_stripes(x,y,z,w,l,0);
	usa_stars(x,y+0.024,z,canton_w,canton_l,0);
};

unit() paris_steering_surfaces = fn {
	cloth_sides(-4.74,1.01,-1.57,9.48,0.15,1.50,0.9,0.94,0.86);
	quad(-4.74,1.16,-1.57,4.74,1.16,-1.57,4.74,1.16,-1.30,-4.74,1.16,-1.30,0.27,0.46,0.37);
	quad(-4.74,1.16,-1.30,4.74,1.16,-1.30,4.74,1.16,-0.07,-4.74,1.16,-0.07,0.96,0.96,0.86);
	brazilian_flag(0.48,1.19,-1.245,3.96,1.11);
	cloth_sides(-1.40,0.99,2.34,2.80,0.16,1.64,0.54,0.70,0.43);
	brazilian_flag(-1.40,1.15,2.34,2.80,1.64);
};

unit(i32) plane_model = fn(kind) {
	if (kind == 0) {
		box(-4.85,-0.49,-0.85,9.70,0.19,1.80,0.91,0.76,0.48);
		box(-4.85,0.93,-0.85,9.70,0.19,1.80,0.98,0.83,0.58);
		american_flag();
		wing_post(-4.15,-0.58,kind); wing_post(4.15,-0.58,kind); wing_post(-4.15,0.53,kind); wing_post(4.15,0.53,kind);
		wing_post(-2.20,-0.58,kind); wing_post(2.20,-0.58,kind); wing_post(-2.20,0.53,kind); wing_post(2.20,0.53,kind);
		wing_post(-0.65,0.26,kind); wing_post(0.65,0.26,kind);
		box(-0.68,-0.84,-1.66,0.12,0.16,3.36,0.38,0.25,0.16);
		box(0.55,-0.84,-1.66,0.12,0.16,3.36,0.38,0.25,0.16);
		box(-1.50,-0.18,2.52,3.00,0.12,0.71,0.98,0.85,0.61);
		box(-1.50,0.49,2.52,3.00,0.12,0.71,0.96,0.80,0.53);
		box(-0.48,-0.37,-2.76,0.12,0.92,0.77,0.89,0.73,0.52);
		box(0.36,-0.37,-2.76,0.12,0.92,0.77,0.89,0.73,0.52);
		box(-0.42,-0.28,-0.32,0.84,0.46,0.96,0.32,0.24,0.19);
		diamond(0.0,0.13,0.40,0.24,0.32,0.42,0.32,0.24);
	} else {
		box(-4.74,-0.49,-1.57,9.48,0.14,1.50,0.80,0.83,0.75);
		box(-4.80,-0.40,-1.40,0.13,1.47,1.17,0.28,0.49,0.60);
		box(4.67,-0.40,-1.40,0.13,1.47,1.17,0.28,0.49,0.60);
		wing_post(-3.14,-1.38,kind); wing_post(3.14,-1.38,kind); wing_post(-3.14,-0.19,kind); wing_post(3.14,-0.19,kind);
		box(-0.55,-0.36,-2.53,1.10,0.19,5.67,0.42,0.29,0.25);
		box(-1.40,-0.34,2.34,2.80,0.14,1.64,0.76,0.82,0.79);
		paris_steering_surfaces();
		box(-1.43,-0.24,2.46,0.15,1.30,1.40,0.38,0.52,0.34);
		box(1.28,-0.24,2.46,0.15,1.30,1.40,0.38,0.52,0.34);
		box(-0.43,-0.16,0.28,0.86,0.68,0.64,0.61,0.40,0.30);
		diamond(0.0,0.46,0.61,0.24,0.40,0.39,0.28,0.19);
		box(-0.94,-0.94,-0.15,0.29,0.63,0.61,0.22,0.19,0.17);
		box(0.65,-0.94,-0.15,0.29,0.63,0.61,0.22,0.19,0.17);
	};
};

unit(u64,bool) draw_plane = fn(lane,ghost) {
	model_x = presented_pose[lane][0];
	model_y = presented_pose[lane][1];
	model_z = presented_pose[lane][2];
	model_hs = sin_small(presented_pose[lane][3]);
	model_hc = cos_small(presented_pose[lane][3]);
	model_ps = sin_small(presented_pose[lane][4]);
	model_pc = cos_small(presented_pose[lane][4]);
	model_rs = sin_small(-presented_pose[lane][5]);
	model_rc = cos_small(presented_pose[lane][5]);
	model_local = true;
	model_ghost = ghost;
	plane_model(course);
	model_local = false;
	model_ghost = false;
};

bool(i32, i32) held = fn(mask,bit) { (mask & bit) != 0 };
f32(i32,i32,i32) axis = fn(mask,a,b) {
	(if (held(mask,a)) { 1.0 } else { 0.0 }) - (if (held(mask,b)) { 1.0 } else { 0.0 })
};

i32() input_version = fn { 1 };

unit() cancel_drop = fn { pending_drop = false; };

i32(i32) quantized_axis = fn(raw) {
	i32 v = if (raw >= 128) { raw-256 } else { raw };
	i32 mag = if (v >= 0) { v } else { -v };
	i32 clipped = if (mag > 127) { 127 } else { mag };
	i32 q = (clipped*7+63)/127;
	if (v >= 0) { q } else { -q }
};

i32(i32,i32,i32,i32) effective_axis = fn(mask,raw,plus,minus) {
	if (held(mask,plus|minus)) {
		i32 a = if (held(mask,plus)) { 7 } else { 0 };
		i32 b = if (held(mask,minus)) { 7 } else { 0 };
		a-b
	} else { quantized_axis(raw) }
};

i32(i32) canonical_input = fn(mask) {
	if ((mask & 64) == 0) { mask & 191 } else {
		i32 bank = effective_axis(mask,(mask >> 8) & 255,2,1);
		i32 pitch = effective_axis(mask,(mask >> 16) & 255,4,8);
		64 | (mask & 176) | ((bank+7) << 8) | ((pitch+7) << 12)
	}
};

unit(u64) spawn = fn(lane) {
	poses[lane][0] = if (course == 0) { -15.0 } else { -61.0 };
	poses[lane][1] = if (course == 0) { 17.5 } else { 10.0 };
	poses[lane][2] = if (course == 0) { 0.0 } else { 100.0 };
	poses[lane][3] = if (course == 0) { 0.0 } else { 0.96 };
	poses[lane][4] = 0.0;
	poses[lane][5] = 0.0;
	poses[lane][6] = 23.0;
	poses[lane][7] = 0.0;
};

f32(i32) bank_control = fn(controls) {
	if (held(controls,64)) { float_i(((controls >> 8) & 15)-7)/7.0 } else { axis(controls,2,1) }
};

unit(u64,i32) fly = fn(lane,controls) {
	f32 banks = bank_control(controls);
	f32 climbs = if (held(controls,64)) { float_i(((controls >> 12) & 15)-7)/7.0 } else { axis(controls,4,8) };
	f32 power = axis(controls,16,32);
	f32 roll_old = poses[lane][5];
	f32 pitch_old = poses[lane][4];
	f32 speed_old = poses[lane][6];
	f32 pitch = blend(pitch_old,climbs*0.34,0.12);
	f32 roll = blend(roll_old,banks*0.90,0.16);
	f32 target_speed = 24.0 + power*9.0 - pitch*19.0 - abs_f(roll)*3.0;
	f32 speed = clamp(blend(speed_old,target_speed,0.037),11.5,45.0);
	f32 turn = roll * (0.0275 + (24.0-speed)*0.00028);
	f32 heading = wrap(poses[lane][3] + turn);
	f32 glide = if (speed < 15.5) { (15.5-speed)*0.82 } else { 0.0 };
	f32 lift = pitch*speed-glide-abs_f(roll)*1.1;
	f32 climb = blend(poses[lane][7],lift,0.16);
	f32 travel = speed / 30.0;
	poses[lane][0] = poses[lane][0] + travel*sin_small(heading);
	poses[lane][1] = poses[lane][1] + climb/30.0;
	poses[lane][2] = poses[lane][2] + travel*cos_small(heading);
	poses[lane][3] = heading;
	poses[lane][4] = pitch;
	poses[lane][5] = roll;
	poses[lane][6] = speed;
	poses[lane][7] = climb;
};

bool(f32,f32,f32,f32,f32,f32,f32,f32) within = fn(x,y,z,x0,z0,w,l,h) {
	x >= x0 && x <= x0+w && z >= z0 && z <= z0+l && y < h
};

bool(f32,f32,f32,f32,f32,f32,f32,f32,f32) tower_leg_hit = fn(x,z,y,y0,y1,d0,d1,w0,w1) {
	if (y >= y0 && y <= y1) {
		f32 t = (y-y0)/(y1-y0);
		f32 d = blend(d0,d1,t);
		f32 w = blend(w0,w1,t) + 0.10;
		abs_f(x-d) <= w && abs_f(z-d) <= w
	} else { false }
};

bool(f32,f32,f32) tower_arch_hit = fn(u,d,y) {
	if (u >= 17.6 || y < 4.3 || y > 21.15) { false } else {
		f32 t = u/17.6;
		f32 h = 4.4 + 14.6*(1.0-t*t);
		y >= h-0.13 && y <= h+2.17 && abs_f(d-(20.0-y*0.29)) <= 0.32
	}
};

bool(f32,f32,f32,f32,f32,f32,f32,f32) tower_lattice_hit = fn(u,v,y,lo,hi,e0,e1,w) {
	if (y < lo || y > hi) { false } else {
		f32 t = (y-lo)/(hi-lo);
		f32 span = blend(e0,e1,t);
		f32 cross = abs_f(blend(-e0,e1,t));
		(abs_f(v-span) <= 0.24 && abs_f(u-cross) <= w+0.10) ||
		(abs_f(u-span) <= 0.24 && abs_f(v-cross) <= w+0.10)
	}
};

bool(f32,f32,f32) tower_hit = fn(px,y,pz) {
	f32 x = abs_f(px-tower_x());
	f32 z = abs_f(pz-tower_z());
	if (x > 22.1 || z > 22.1 || y >= 84.0) { false } else {
		(y <= 2.35 && abs_f(x-18.0) <= 4.0 && abs_f(z-18.0) <= 4.0) ||
		tower_leg_hit(x,z,y,2.35,11.0,18.0,15.6,2.9,2.43) ||
		tower_leg_hit(x,z,y,11.0,23.4,15.6,12.5,2.43,1.87) ||
		tower_arch_hit(x,z,y) || tower_arch_hit(z,x,y) ||
		(y >= 23.35 && y <= 26.12 && x <= 15.38 && z <= 15.38) ||
		tower_leg_hit(x,z,y,25.2,43.0,11.9,6.3,1.66,1.18) ||
		tower_lattice_hit(x,z,y,25.4,42.3,11.8,6.5,0.42) ||
		(y >= 42.45 && y <= 45.69 && x <= 8.35 && z <= 8.35) ||
		tower_leg_hit(x,z,y,44.8,57.0,5.95,3.2,1.03,0.66) ||
		tower_lattice_hit(x,z,y,45.1,52.0,5.9,4.35,0.29) ||
		tower_lattice_hit(x,z,y,52.0,57.0,4.35,3.2,0.24) ||
		tower_leg_hit(x,z,y,57.0,70.5,3.2,1.77,0.66,0.43) ||
		tower_lattice_hit(x,z,y,57.0,63.8,3.2,2.42,0.19) ||
		tower_lattice_hit(x,z,y,63.8,70.0,2.42,1.80,0.15) ||
		(y >= 69.65 && y <= 72.06 && x <= 3.28 && z <= 3.28) ||
		(y > 72.06 && y <= 78.18 && x <= 2.38 && z <= 2.38) ||
		(y > 78.18 && x <= 0.44 && z <= 0.44)
	}
};

bool(f32,f32,f32) obstacle = fn(x,y,z) {
	if (course == 0) {
		within(x,y,z,129.0,84.0,32.0,26.0,17.0) || within(x,y,z,-77.0,151.0,32.0,26.0,17.0) ||
		within(x,y,z,163.0,111.0,7.0,7.0,17.0)
	} else {
		i32 col = core.float_to_sint_trunc<i32>((x+344.0)/56.0);
		i32 row = core.float_to_sint_trunc<i32>((z+205.0)/59.0);
		f32 bx = float_i(col)*56.0-344.0;
		f32 bz = float_i(row)*59.0-205.0;
		i32 lot = row*12+col;
		bool buildings = col>=0 && col<12 && row>=0 && row<8 && city_lot(bx,bz) && within(x,y,z,bx-1.0,bz-1.0,30.0,29.0,float_i(8+lot*11%18)+2.8);
		buildings || tower_hit(x,y,z) || within(x,y,z,54.0,172.0,10.0,119.0,9.35) || within(x,y,z,158.0,221.0,12.0,119.0,4.3)
	}
};

f32(f32,f32,i32) gravity_root = fn(d,t,n) {
	if (n > 0) { gravity_root(d,(t+d/t)*0.5,n-1) } else { t }
};

f32(f32) mail_time = fn(y) { gravity_root((y-0.85)/9.0,1.0,4) };

i32(u64) drop_status = fn(plane) {
	f32 x = poses[plane][0];
	f32 y = poses[plane][1];
	f32 z = poses[plane][2];
	f32 bearing = wrap(poses[plane][3]-0.80);
	if (y > 14.0) { 5 } else {
		if (y < 3.0) { 6 } else {
			if (abs_f(bearing) > 0.53 || abs_f(poses[plane][5]) > 0.32) { 7 } else {
				f32 speed = poses[plane][6];
				f32 lead = speed * mail_time(y);
				f32 dx = x + sin_small(poses[plane][3])*lead - drop_x();
				f32 dz = z + cos_small(poses[plane][3])*lead - drop_z();
				if (dx*dx+dz*dz <= 90.25) { 9 } else { 8 }
			}
		}
	}
};

unit(u64,u64) launch_mail = fn(plane,race) {
	f32 heading = poses[plane][3];
	f32 speed = poses[plane][6];
	mail[race][0] = poses[plane][0];
	mail[race][1] = poses[plane][1]-0.65;
	mail[race][2] = poses[plane][2];
	mail[race][3] = speed * sin_small(heading);
	mail[race][4] = speed * cos_small(heading);
	mail[race][5] = 0.0;
	mail[race][6] = mail_time(poses[plane][1]);
	phase[race] = 5;
};

unit(u64) lower_mail = fn(race) {
	f32 elapsed = mail[race][5];
	f32 total = mail[race][6];
	f32 next = clamp(elapsed+0.033333333,0.0,total);
	mail[race][0] = mail[race][0] + mail[race][3] * (next-elapsed);
	mail[race][2] = mail[race][2] + mail[race][4] * (next-elapsed);
	mail[race][1] = mail[race][1] - 9.0*(next*next-elapsed*elapsed);
	mail[race][5] = next;
	if (next >= total) {
		f32 dx = mail[race][0]-drop_x();
		f32 dz = mail[race][2]-drop_z();
		if (dx*dx+dz*dz <= 91.0) { phase[race] = 2; } else {
			phase[race] = 1;
			event_code[race] = 8;
		};
	};
};

bool(f32,f32) in_strip = fn(x,z) {
	abs_f(x-strip_x()) < strip_w()/2.0 && z >= strip_z() && z < strip_z()+strip_l()
};

i32(u64) landing_issue = fn(plane) {
	f32 limit = if (course == 0) { 24.0 } else { 27.0 };
	if (abs_f(poses[plane][5]) >= 0.28 || cos_small(poses[plane][3]) <= 0.90) { 1 } else {
		if (poses[plane][6] >= limit) { 2 } else {
			if (poses[plane][7] < -4.3 || abs_f(poses[plane][4]) > 0.25) { 3 } else { 0 }
		}
	}
};

unit(u64,u64,i32) roll_out = fn(plane,race,input) {
	f32 speed = poses[plane][6];
	f32 brake = if (held(input,32)) { 7.3 } else { if (held(input,16)) { 0.65 } else { 2.6 } };
	f32 heading = wrap(poses[plane][3] + bank_control(input)*clamp(speed,0.0,17.0)*0.00052);
	f32 x = poses[plane][0] + speed*sin_small(heading)/30.0;
	f32 z = poses[plane][2] + speed*cos_small(heading)/30.0;
	poses[plane][0] = x;
	poses[plane][2] = z;
	poses[plane][3] = heading;
	poses[plane][6] = clamp(speed-brake/30.0,0.0,45.0);
	if (z < strip_z() || z >= strip_z()+strip_l()) { result[race] = 9; } else {
		if (abs_f(x-strip_x()) >= strip_w()/2.0) { result[race] = 11; } else {
			if (poses[plane][6] < 0.25) { result[race] = 1; };
		};
	};
};

u16(i32) logged_control = fn(n) { flight_log[ix(n/4096)][ix(n/256%16)][ix(n/16%16)][ix(n%16)] };
u8(i32) record_byte = fn(n) { best_log[ix(n/4096)][ix(n/256%16)][ix(n/16%16)][ix(n%16)] };
u8(i32) packet_byte = fn(n) { incoming_log[ix(n/4096)][ix(n/256%16)][ix(n/16%16)][ix(n%16)] };

unit(i32,u8) set_best_byte = fn(i,value) {
	best_log[ix(i/4096)][ix(i/256%16)][ix(i/16%16)][ix(i%16)] = value;
};

unit(i32,i32) copy_packet = fn(i,last) {
	if (i < last) {
		set_best_byte(i,packet_byte(i));
		copy_packet(i+1,last);
	};
};

unit(i32,i32) write_record = fn(i,last) {
	if (i < last) {
		i32 value = core.int_extend<i32>(logged_control(i));
		i32 at = 6+i*2;
		set_best_byte(at,core.int_trunc<u8>(value & 255));
		set_best_byte(at+1,core.int_trunc<u8>(value >> 8));
		write_record(i+1,last);
	};
};

i32(i32) record_word = fn(step_index) {
	i32 i = 6+step_index*2;
	core.int_extend<i32>(record_byte(i)) + (core.int_extend<i32>(record_byte(i+1)) << 8)
};

i32(i32) packet_word = fn(step_index) {
	i32 i = 6+step_index*2;
	core.int_extend<i32>(packet_byte(i)) + (core.int_extend<i32>(packet_byte(i+1)) << 8)
};

bool(i32) valid_control = fn(word) {
	(word <= 191 && !held(word,64)) || (held(word,64) && (word & 15) == 0 &&
		((word >> 8) & 15) < 15 && ((word >> 12) & 15) < 15)
};

unit() store_record = fn {
	i32 record_ticks = stage_tick[0];
	if (best_ticks == 0 || record_ticks < best_ticks) {
		best_ticks = record_ticks;
		set_best_byte(0,87);
		set_best_byte(1,70);
		set_best_byte(2,3);
		set_best_byte(3,core.int_trunc<u8>(course));
		set_best_byte(4,core.int_trunc<u8>(record_ticks % 256));
		set_best_byte(5,core.int_trunc<u8>(record_ticks / 256));
		write_record(0,record_ticks);
		i32 size = record_ticks*2+6;
		unsafe { host.record(core.pointer_cast<*?u8>(&?best_log[0][0][0][0]),size); };
	};
};

unit() ghost_begin = fn {
	incoming_count = 0;
	incoming_bad = false;
};

unit(i32) ghost_byte = fn(b) {
	i32 i = incoming_count;
	if (i < 14406 && b >= 0 && b <= 255) {
		incoming_log[ix(i/4096)][ix(i/256%16)][ix(i/16%16)][ix(i%16)] = core.int_trunc<u8>(b);
		incoming_count = i+1;
	} else {
		incoming_bad = true;
	};
};

unit(u64,u64,i32) step_course = fn(plane,race,input) {
	stage_tick[race] = stage_tick[race]+1;
	if (phase[race] == 3) { roll_out(plane,race,input); } else {
		f32 x = poses[plane][0];
		fly(plane,input);
		f32 next_x = poses[plane][0];
		f32 y = poses[plane][1];
		f32 z = poses[plane][2];
		if (course == 1) {
			if (phase[race] == 0) {
				if (x < 27.0 && next_x >= 27.0 && abs_f(z-161.0) < 15.0 && y < 8.8) { route[race] = 1; };
				if (next_x > 66.0) {
					if (route[race] == 0 || z < 170.0 || z > 211.0) { route[race] = 2; };
					phase[race] = 1;
				};
			};
			if (phase[race] == 1 && held(input,128)) {
				i32 status = drop_status(plane);
				if (status == 9) { launch_mail(plane,race); event_code[race] = 0; } else { event_code[race] = status; };
			};
			if (phase[race] == 5) { lower_mail(race); };
		};
		if (y <= 1.0) {
			poses[plane][1] = 1.0;
			i32 issue = landing_issue(plane);
			if (course == 1 && phase[race] != 2) { result[race] = 7; } else {
				if (!in_strip(next_x,z)) { result[race] = 4; } else {
					if (issue != 0) { result[race] = if (issue == 3) { 10 } else { 4+issue }; } else {
						phase[race] = 3;
						poses[plane][4] = 0.0;
						poses[plane][5] = 0.0;
						poses[plane][7] = 0.0;
					};
				}
			}
		} else {
			if (y > 123.0 || abs_f(next_x) > 448.0 || z < -309.0 || z > 555.0) { result[race] = 3; } else {
				if (obstacle(next_x,y,z)) { result[race] = if (course == 1 && within(next_x,y,z,54.0,172.0,10.0,119.0,9.35)) { 8 } else { 2 }; };
			};
		};
	};
	if (stage_tick[race] >= 7200 && result[race] == 0) { result[race] = 3; };
};

unit(u64) reset_mission = fn(lane) {
	stage_tick[lane] = 0;
	phase[lane] = if (course == 0) { 2 } else { 0 };
	result[lane] = 0;
	route[lane] = 0;
	event_code[lane] = 0;
};

bool(i32,i32) validate_steps = fn(i,length) {
	i32 control = packet_word(i);
	if (valid_control(control)) {
		step_course(2,2,control);
		if (i+1 == length) { result[2] == 1 } else {
			if (result[2] == 0) { validate_steps(i+1,length) } else { false }
		}
	} else { false }
};

bool(i32) validate_replay = fn(length) {
	spawn(2);
	reset_mission(2);
	validate_steps(0,length)
};

unit(u64) retain_pose = fn(lane) {
	previous_pose[lane][0] = poses[lane][0];
	previous_pose[lane][1] = poses[lane][1];
	previous_pose[lane][2] = poses[lane][2];
	previous_pose[lane][3] = poses[lane][3];
	previous_pose[lane][4] = poses[lane][4];
	previous_pose[lane][5] = poses[lane][5];
};

unit(u64,f32) present_pose = fn(lane,alpha) {
	if (alpha >= 1.0) {
		presented_pose[lane][0] = poses[lane][0];
		presented_pose[lane][1] = poses[lane][1];
		presented_pose[lane][2] = poses[lane][2];
		presented_pose[lane][3] = poses[lane][3];
		presented_pose[lane][4] = poses[lane][4];
		presented_pose[lane][5] = poses[lane][5];
	} else {
		presented_pose[lane][0] = blend(previous_pose[lane][0],poses[lane][0],alpha);
		presented_pose[lane][1] = blend(previous_pose[lane][1],poses[lane][1],alpha);
		presented_pose[lane][2] = blend(previous_pose[lane][2],poses[lane][2],alpha);
		f32 prev_heading = previous_pose[lane][3];
		presented_pose[lane][3] = wrap(prev_heading+wrap(poses[lane][3]-prev_heading)*alpha);
		presented_pose[lane][4] = blend(previous_pose[lane][4],poses[lane][4],alpha);
		presented_pose[lane][5] = blend(previous_pose[lane][5],poses[lane][5],alpha);
	};
};

unit() ghost_end = fn {
	if (!incoming_bad && incoming_count >= 7 && packet_byte(0)==87 && packet_byte(1)==70 &&
	    packet_byte(3)==core.int_trunc<u8>(course)) {
		i32 version = core.int_extend<i32>(packet_byte(2));
		i32 length = core.int_extend<i32>(packet_byte(4)) + 256*core.int_extend<i32>(packet_byte(5));
		if (version == 3 && length >= 180 && length <= 7200 && length*2+6 == incoming_count &&
		    stage_tick[0] == 0 && (best_ticks == 0 || length < best_ticks) && validate_replay(length)) {
			best_ticks = length;
			copy_packet(0,incoming_count);
			spawn(1);
			reset_mission(1);
			retain_pose(1);
			present_pose(1,1.0);
		};
	};
};

unit(i32) step = fn(input) {
	i32 n = stage_tick[0];
	flight_log[ix(n/4096)][ix(n/256%16)][ix(n/16%16)][ix(n%16)] = core.int_trunc<u16>(input);
	if (n < best_ticks) {
		retain_pose(1);
		step_course(1,1,record_word(n));
	};
	retain_pose(0);
	step_course(0,0,input);
	if (result[0] == 1) { store_record(); };
};

unit(i32,i32) advance = fn(input,left) {
	if (left > 0 && accumulator >= 0.033333333 && result[0] == 0) {
		accumulator = accumulator - 0.033333333;
		i32 content = input | (if (pending_drop) { 128 } else { 0 });
		cancel_drop();
		step(content);
		advance(input,left-1);
	};
};

unit(f32) draw_aircraft = fn(alpha) {
	vertex_count = 0;
	drawing_world = false;
	if (phase[0] == 5) {
		box(mail[0][0]-0.30,mail[0][1],mail[0][2]-0.30,0.60,0.54,0.60,0.92,0.50,0.18);
	};

	if (best_ticks > 0 && stage_tick[0] > 0 && stage_tick[0] < best_ticks) {
		present_pose(1,alpha);
		f32 dx = presented_pose[1][0]-presented_pose[0][0];
		f32 dy = presented_pose[1][1]-presented_pose[0][1];
		f32 dz = presented_pose[1][2]-presented_pose[0][2];
		if (dx*dx+dy*dy+dz*dz > 121.0) { draw_plane(1,true); };
	};
	draw_plane(0,false);
	i32 count = vertex_count*6;
	unsafe { host.aircraft(core.pointer_cast<*?u8>(&?moving_mesh[0][0][0][0]),count); };
};

unit() frame = fn {
	f32 hx = sin_small(presented_pose[0][3]);
	f32 hz = cos_small(presented_pose[0][3]);
	f32 pitch = -0.20 + presented_pose[0][4]*0.62;
	f32 ps = sin_small(pitch);
	f32 pc = cos_small(pitch);
	f32 vx = hx*pc;
	f32 vy = ps;
	f32 vz = hz*pc;
	f32 ux = -hx*ps;
	f32 uy = pc;
	f32 uz = -hz*ps;
	f32 ex = presented_pose[0][0]-hx*17.5;
	f32 ey = presented_pose[0][1]+5.3;
	f32 ez = presented_pose[0][2]-hz*17.5;
	f32 scale_y = if (viewport < 0.86) { 1.30 } else { 1.61 };
	f32 scale_x = scale_y/viewport;
	f32 near_far = 1.0015052;
	display[0] = hz*scale_x;
	display[1] = ux*scale_y;
	display[2] = vx*near_far;
	display[3] = vx;
	display[4] = 0.0;
	display[5] = uy*scale_y;
	display[6] = vy*near_far;
	display[7] = vy;
	display[8] = -hx*scale_x;
	display[9] = uz*scale_y;
	display[10] = vz*near_far;
	display[11] = vz;
	display[12] = -(hz*ex-hx*ez)*scale_x;
	display[13] = -(ux*ex+uy*ey+uz*ez)*scale_y;
	f32 offset = -(vx*ex+vy*ey+vz*ez);
	display[14] = offset*near_far-1.401053;
	display[15] = offset;
	display[16] = float_i(course);
	display[17] = float_i(stage_tick[0])/30.0;
	display[18] = poses[0][6];
	display[19] = poses[0][1];
	display[20] = float_i(phase[0]);
	display[21] = if (course == 1 && phase[0] == 1) { float_i(drop_status(0)) } else { 0.0 };
	display[22] = float_i(result[0]);
	display[23] = float_i(best_ticks)/30.0;
	i32 remaining = if (stage_tick[0] < 7200) { 7200-stage_tick[0] } else { 0 };
	display[24] = float_i(if (result[0] == 1) { 250+remaining/9+(if (route[0] == 1) { 150 } else { 0 }) } else { 0 });
	display[25] = float_i(route[0]);
	display[26] = float_i(event_code[0]);
	i32 stage = phase[0];
	f32 x = poses[0][0];
	f32 z = poses[0][2];
	f32 target_x = if (stage == 0) { if (x < 27.0) { 38.0 } else { 67.0 } } else {
		if (stage == 1 || stage == 5) { drop_x() } else { strip_x() }
	};
	f32 target_z = if (stage == 0) { if (x < 27.0) { 169.0 } else { 189.0 } } else {
		if (stage == 1 || stage == 5) { drop_z() } else { strip_z()+9.0 }
	};
	f32 steer_x = target_x-x;
	f32 steer_z = target_z-z;
	f32 mx = abs_f(steer_x);
	f32 mz = abs_f(steer_z);
	display[27] = if (stage == 3) { strip_z()+strip_l()-z } else {
		if (mx > mz) { mx+0.41*mz } else { mz+0.41*mx }
	};
	f32 right = steer_x*hz-steer_z*hx;
	f32 ahead = steer_x*hx+steer_z*hz;
	display[28] = if (ahead <= 0.0) {
		if (right < 0.0) { -1.0 } else { 1.0 }
	} else { clamp(right*1.6/ahead,-1.0,1.0) };
	display[29] = if (stage == 2 && result[0] == 0) {
		i32 issue = landing_issue(0);
		if (mx > strip_w()*0.42 || issue == 1) { 1.0 } else {
			if (issue == 0) { 4.0 } else { float_i(issue) }
		}
	} else { 0.0 };
	display[30] = if (stage == 0 && x > 25.0 && x < 54.0 && z >= 154.0 && poses[0][1] < 11.5) { 1.0 } else { 0.0 };
	display[31] = if (stage == 2 && course == 1) { 1.0 } else { 0.0 };

	unsafe { host.frame(core.pointer_cast<*?u8>(&?display[0]),32); };
};

unit(i32) reset = fn(requested) {
	i32 next = if (requested == 1) { 1 } else { 0 };
	if (course != next) { best_ticks = 0; world_ready = false; };
	course = next;
	cancel_drop();
	reset_mission(0);
	reset_mission(1);
	accumulator = 0.0;

	spawn(0);
	spawn(1);
	retain_pose(0);
	retain_pose(1);
	present_pose(0,1.0);
	present_pose(1,1.0);
	if (!world_ready) { render_land(); world_ready = true; };
};

unit(f32,i32,f32) tick = fn(dt,input,aspect) {
	f32 accepted = if (dt >= 0.0 && dt < 0.20) { dt } else { 0.0 };
	viewport = if (aspect > 0.25 && aspect < 5.0) { aspect } else { 1.0 };
	accumulator = clamp(accumulator+accepted,0.0,0.17);
	if (held(input,128)) { pending_drop = true; };
	advance(canonical_input(input & -129),5);
	f32 alpha = if (result[0] == 0) { clamp(accumulator*30.0,0.0,1.0) } else { 1.0 };
	present_pose(0,alpha);
	draw_aircraft(alpha);
	frame();
};
%%end
