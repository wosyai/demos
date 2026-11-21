%%start
host = extern wasm "ferry" {
    unsafe unit(*?u8, i32) world;
    unsafe unit(*?u8, i32) moving;
    unsafe unit(*?u8, i32) frame;
};

f32[6] empty_vertex = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
f32[6][16] mesh_chunk_0 = [empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex, empty_vertex];
f32[6][16][16] mesh_chunk_1 = [mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0, mesh_chunk_0];
f32[6][16][16][16] mesh_chunk_2 = [mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1];
f32[6][16][16][16][3] scenery = [mesh_chunk_2, mesh_chunk_2, mesh_chunk_2];
f32[6][16][16][19] moving_mesh = [mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1, mesh_chunk_1];

f32[30] display = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
i32 vertex_count = 0;
bool drawing_world = false;
bool world_ready = false;
bool model_local = false;
f32 model_x = 0.0;
f32 model_y = 0.0;
f32 model_z = 0.0;
f32 model_hs = 0.0;
f32 model_hc = 1.0;
f32 model_rs = 0.0;
f32 model_rc = 1.0;
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
	f32 px = if (model_local) { model_x + ux*model_hc + z*model_hs } else { x };
	f32 py = if (model_local) { model_y + uy } else { y };
	f32 pz = if (model_local) { model_z - ux*model_hs + z*model_hc } else { z };
	f32 pr = clamp(r,0.0,1.0);
	f32 pg = clamp(g,0.0,1.0);
	f32 pb = clamp(b,0.0,1.0);
	if (drawing_world) {
		scenery[high][layer][row][cell][0] = px;
		scenery[high][layer][row][cell][1] = py;
		scenery[high][layer][row][cell][2] = pz;
		scenery[high][layer][row][cell][3] = pr;
		scenery[high][layer][row][cell][4] = pg;
		scenery[high][layer][row][cell][5] = pb;
	} else {
		u64 moving_layer = ix(i / 256);
		moving_mesh[moving_layer][row][cell][0] = px;
		moving_mesh[moving_layer][row][cell][1] = py;
		moving_mesh[moving_layer][row][cell][2] = pz;
		moving_mesh[moving_layer][row][cell][3] = pr;
		moving_mesh[moving_layer][row][cell][4] = pg;
		moving_mesh[moving_layer][row][cell][5] = pb;
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

f32(f32) sq = fn(v) { v*v };
f32(f32,f32) length = fn(x,z) {
    f32 hi = if (abs_f(x)>abs_f(z)) { abs_f(x) } else { abs_f(z) };
    f32 lo = if (abs_f(x)>abs_f(z)) { abs_f(z) } else { abs_f(x) };
    if (hi <= 0.00001) { 0.0 } else {
        f32 ratio = lo/hi;
        f32 value = 1.0+ratio*ratio;
        f32 first = 1.0+0.5*ratio*ratio;
        hi*0.5*(first+value/first)
    }
};
f32(f32,f32) min_f = fn(a,b) { if (a<b) { a } else { b } };
f32(f32,f32) max_f = fn(a,b) { if (a>b) { a } else { b } };

f32[5][15] buildings = [
    [-31.0, -10.0, 11.0, 13.0, 9.2],
    [-11.1, -8.0, 5.1, 12.6, 5.0],
    [7.8, -10.0, 16.0, 13.5, 10.8],
    [-31.0, 7.0, 11.0, 17.5, 12.0],
    [-11.5, 6.5, 5.5, 16.5, 7.8],
    [11.0, 9.0, 14.2, 18.5, 7.2],
    [-31.0, 33.0, 11.0, 19.8, 13.6],
    [-12.0, 33.8, 6.0, 16.8, 9.5],
    [14.4, 33.0, 12.0, 17.5, 6.2],
    [5.8, 29.7, 4.2, 18.0, 5.8],
    [6.0, 54.4, 4.4, 10.8, 6.5],
    [17.0, 55.2, 12.0, 12.5, 8.3],
    [-30.0, 62.8, 15.8, 8.4, 7.1],
    [-12.0, 62.8, 6.1, 8.4, 5.6],
    [19.8, 71.0, 8.3, 4.4, 3.4]
];
f32[2][12] trees = [
    [5.4,22.0],[-5.1,19.0],[13.5,24.7],[5.0,54.0],[-5.2,45.0],[-18.7,18.0],
    [-13.0,54.4],[-24.0,56.8],[15.2,61.9],[22.8,7.0],[4.8,69.0],[25.1,60.2]
];
f32[2][4] mailbox_home = [[3.9,18.0],[-4.4,38.0],[12.4,50.4],[-13.6,57.4]];
f32[4] empty_prop = [0.0,0.0,0.0,0.0];
f32[4][4] mailbox = [empty_prop,empty_prop,empty_prop,empty_prop];
f32[7] empty_ped = [0.0,0.0,0.0,0.0,0.0,0.0,0.0];
f32[7][6] peds = [empty_ped,empty_ped,empty_ped,empty_ped,empty_ped,empty_ped];
f32[4][6] sidewalks = [
    [5.1,14.0,6.3,24.0],[-5.1,10.7,-5.1,29.5],[12.0,33.5,12.5,59.0],
    [5.2,46.0,4.8,67.4],[-13.5,33.0,-13.5,54.0],[7.0,73.2,15.2,73.2]
];
f32[2][4] traffic_home = [[2.0,25.0],[-2.0,55.0],[2.0,61.0],[-2.0,35.0]];
f32[4][4] traffic = [empty_prop,empty_prop,empty_prop,empty_prop];
f32 car_x = 0.0;
f32 car_z = -5.0;
f32 car_yaw = 0.0;
f32 vx = 0.0;
f32 vz = 0.0;
f32 brake_mark = 0.0;
f32 car_roll = 0.0;
f32 foot_x = 2.1;
f32 foot_z = -4.6;
f32 foot_speed = 0.0;
f32 foot_yaw = 0.0;
f32 camera_x = 2.1;
f32 camera_z = -12.0;
f32 camera_y = 4.1;
f32 camera_yaw = 0.0;
f32 old_x = 0.0;
f32 old_z = -5.0;
f32 old_yaw = 0.0;
f32 old_foot_x = 2.1;
f32 old_foot_z = -4.6;
f32 old_foot_yaw = 0.0;
f32 old_camera_x = 2.1;
f32 old_camera_y = 4.1;
f32 old_camera_z = -12.0;
f32 old_camera_yaw = 0.0;
f32 camera_pitch = -0.25;
f32 accumulator = 0.0;
f32 viewport = 1.0;
f32 seconds_left = 90.0;
f32 collision_wait = 0.0;
i32 collision_kind = 0;
i32 collision_seq = 0;
i32 stage = 0;
bool in_car = false;
bool pending_action = false;
f32 tape_x = 8.2;
f32 tape_z = 10.1;
f32 dock_x = 11.0;
f32 dock_z = 83.0;
f32 ferry_z = 88.0;
f32 dt_step = 0.016666667;

unit(f32,f32,f32,f32,f32,f32,f32,f32) ground = fn(x,z,w,d,h,r,g,b) {
    quad(x,h,z,x+w,h,z,x+w,h,z+d,x,h,z+d,r,g,b);
};

unit(i32,i32,f32,f32,f32,f32,f32,f32,f32) facade = fn(i,j,x,z,w,d,h,cr,cg) {
    if (i < 5 && j < 3) {
        f32 fy = 1.45+float_i(j)*(h-1.65)/3.0;
        f32 ww = (w-1.3)/5.0;
        f32 fx = x+0.65+float_i(i)*ww;
        f32 hh = (h-1.55)*0.17;
        f32 fwd=z-0.015; f32 rear=z+d+0.016;
        quad(fx,fy,fwd,fx+ww*0.69,fy,fwd,fx+ww*0.69,fy+hh,fwd,fx,fy+hh,fwd,0.15,0.23,0.32);
        quad(fx,fy-0.11,fwd,fx+ww*0.72,fy-0.11,fwd,fx+ww*0.72,fy-0.025,fwd,fx,fy-0.025,fwd,cr*0.75,cg*0.75,0.51);
        quad(fx,fy,rear,fx+ww*0.68,fy,rear,fx+ww*0.68,fy+hh,rear,fx,fy+hh,rear,0.23,0.33,0.42);
        if (i==0 || i==2 || i==4) {
            f32 l=x-0.018; f32 e=x+w+0.018; f32 along=z+0.5+float_i(i)*d/5.0;
            f32 end=along+d*0.115;
            quad(l,fy,along,l,fy,end,l,fy+hh,end,l,fy+hh,along,0.21,0.29,0.44);
            quad(e,fy,along,e,fy,end,e,fy+hh,end,e,fy+hh,along,0.19,0.27,0.39);
        };
        if (i==4) { facade(0,j+1,x,z,w,d,h,cr,cg); }
        else { facade(i+1,j,x,z,w,d,h,cr,cg); };
    };
};

unit(i32) draw_buildings = fn(i) {
    if (i<15) {
        u64 n=ix(i);
        f32 x=buildings[n][0]; f32 z=buildings[n][1]; f32 w=buildings[n][2]; f32 d=buildings[n][3]; f32 h=buildings[n][4];
        f32 r=if (i%3==0) { 0.85 } else { if (i%3==1) { 0.56 } else { 0.91 } };
        f32 g=if (i%3==0) { 0.56 } else { if (i%3==1) { 0.78 } else { 0.71 } };
        f32 b=if (i%3==0) { 0.62 } else { 0.60 };
        box(x,0.0,z,w,h,d,r,g,b);
        box(x-0.2,h*0.71,z-0.19,w+0.4,0.17,d+0.38,0.91,0.87,0.73);
        box(x-0.25,h-0.22,z-0.23,w+0.5,0.24,d+0.46,0.93,0.88,0.77);
        box(x+0.65,h,z+0.65,w-1.3,0.50,d-1.3,r*0.76,g*0.76,b*0.76);
        box(x+1.0,h+0.50,z+1.0,w-2.0,0.31,d-2.0,0.80,0.77,0.71);
        facade(0,0,x,z,w,d,h,r,g);
        draw_buildings(i+1);
    };
};

unit(i32) draw_palms = fn(i) {
    if (i<12) {
        f32 x=trees[ix(i)][0]; f32 z=trees[ix(i)][1];
        f32 ht=4.0+0.34*float_i(i%4);
        box(x-0.20,0.0,z-0.20,0.40,ht,0.40,0.47,0.30,0.21);
        diamond(x,ht-0.22,z,1.61,0.82,0.12,0.57,0.30);
        quad(x-2.1,ht-0.41,z,x-0.4,ht+0.20,z-0.50,x+2.1,ht-0.40,z,x+0.40,ht+0.21,z+0.50,0.17,0.63,0.34);
        quad(x,ht-0.35,z-2.1,x+0.56,ht+0.22,z-0.4,x,ht-0.39,z+2.0,x-0.56,ht+0.22,z+0.4,0.18,0.62,0.32);
        draw_palms(i+1);
    };
};

unit(i32) paint_road = fn(i) {
    if (i<18) {
        f32 z=-14.0+5.0*float_i(i);
        ground(-0.065,z,0.13,2.1,0.022,0.88,0.74,0.38);
        ground(-4.09,z,0.10,4.0,0.021,0.82,0.78,0.67);
        ground(3.99,z,0.10,4.0,0.021,0.82,0.78,0.67);
        if (i%3==1) {
            box(-5.7,0.0,z,0.14,3.9,0.14,0.18,0.30,0.32);
            box(-5.7,3.85,z,1.20,0.14,0.12,0.20,0.33,0.36);
            box(-4.65,3.76,z-0.10,0.38,0.10,0.28,0.97,0.76,0.47);
        };
        paint_road(i+1);
    };
};

unit(i32) crosswalk = fn(i) {
    if (i<9) {
        f32 x=-3.85+0.89*float_i(i);
        ground(x,29.1,0.47,2.15,0.024,0.91,0.83,0.70);
        ground(x,57.5,0.47,2.15,0.024,0.91,0.83,0.70);
        crosswalk(i+1);
    };
};

unit() render_world = fn {
    vertex_count=0;
    model_local=false;
    drawing_world=true;
    ground(-65.0,-45.0,134.0,120.0,-0.035,0.68,0.65,0.64);
    ground(-94.0,75.0,189.0,92.0,-0.035,0.19,0.43,0.62);
    ground(-4.45,-20.0,8.9,94.4,0.018,0.26,0.29,0.37);
    ground(-18.8,-12.0,5.8,85.4,0.018,0.31,0.33,0.43);
    ground(-18.8,27.6,26.2,5.9,0.017,0.29,0.31,0.39);
    ground(-18.8,57.0,23.3,5.1,0.017,0.31,0.33,0.39);
    ground(10.3,6.4,4.3,68.3,0.016,0.78,0.65,0.53);
    ground(-34.0,71.3,69.0,3.65,0.022,0.54,0.47,0.50);
    ground(7.0,74.92,8.0,11.4,0.023,0.52,0.37,0.39);
    ground(-3.0,76.0,9.6,1.15,-0.02,0.31,0.58,0.72);
    ground(15.6,79.0,21.0,1.1,-0.02,0.31,0.58,0.72);
    ground(-34.0,83.2,24.0,0.8,-0.02,0.30,0.59,0.73);
    ground(-33.0,90.2,38.0,0.65,-0.02,0.28,0.53,0.69);
    draw_buildings(0);
    draw_palms(0);
    paint_road(0);
    crosswalk(0);
    box(7.01,0.1,61.3,0.34,0.95,0.34,0.97,0.65,0.34);
    box(9.0,0.1,61.3,0.34,0.95,0.34,0.97,0.65,0.34);
    box(11.0,0.1,61.3,0.34,0.95,0.34,0.97,0.65,0.34);
    box(13.0,0.1,61.3,0.34,0.95,0.34,0.97,0.65,0.34);
    box(6.8,0.0,75.8,0.16,0.65,9.7,0.82,0.75,0.63);
    box(15.0,0.0,75.8,0.16,0.65,9.7,0.82,0.75,0.63);
    box(9.25,1.6,8.35,12.0,0.22,2.18,0.90,0.37,0.49);
    box(11.2,3.5,8.77,10.0,0.27,0.16,0.98,0.44,0.65);
    box(11.2,3.1,8.77,10.0,0.14,0.16,0.23,0.86,0.81);
    box(12.4,4.0,8.77,0.3,2.6,0.16,0.90,0.43,0.62);
    box(20.9,4.0,8.77,0.3,2.6,0.16,0.90,0.43,0.62);
    box(12.4,6.55,8.77,8.8,0.26,0.16,0.90,0.43,0.62);
    box(12.7,4.25,8.85,8.2,2.20,0.12,0.15,0.20,0.31);
    quad(13.6,4.75,8.66,16.0,6.02,8.66,17.7,5.55,8.66,19.9,4.75,8.66,0.96,0.63,0.38);
    unsafe { host.world(core.pointer_cast<*?u8>(&?scenery[0][0][0][0][0]),vertex_count*6); };
    world_ready=true;
};
bool(f32,f32,f32,i32) wall_hit = fn(x,z,r,i) {
    if (i>=15) { false } else {
        u64 n=ix(i);
        f32 bx=buildings[n][0]; f32 bz=buildings[n][1];
        f32 px=clamp(x,bx,bx+buildings[n][2]);
        f32 pz=clamp(z,bz,bz+buildings[n][3]);
        if (sq(x-px)+sq(z-pz)<r*r) { true } else { wall_hit(x,z,r,i+1) }
    }
};

bool(f32,f32,f32,i32) palm_hit = fn(x,z,r,i) {
    if (i>=12) { false } else {
        u64 n=ix(i);
        if (sq(x-trees[n][0])+sq(z-trees[n][1])<sq(r+0.32)) { true } else { palm_hit(x,z,r,i+1) }
    }
};

bool(f32,f32,f32) bollard_hit = fn(x,z,r) {
    if (abs_f(z-61.47)<r+0.22 && x>6.7-r && x<13.7+r) {
        sq(z-61.47)+sq(x-7.18)<sq(r+0.22) ||
        sq(z-61.47)+sq(x-9.17)<sq(r+0.22) ||
        sq(z-61.47)+sq(x-11.17)<sq(r+0.22) ||
        sq(z-61.47)+sq(x-13.17)<sq(r+0.22)
    } else { false }
};

i32(f32,f32,f32,bool) static_hit = fn(x,z,r,vehicle) {
    if (x < -33.2+r || x>30.0-r || z < -15.0+r || z>86.0-r || (z>74.9-r && (vehicle || x<7.1+r || x>14.9-r)) ||
        wall_hit(x,z,r,0) || bollard_hit(x,z,r)) { 5 } else {
        if (palm_hit(x,z,r,0)) { 2 } else { 0 }
    }
};

i32(f32,f32,f32,f32) car_hit = fn(x,z,s,c) {
    i32 nose=static_hit(x+1.0*s,z+1.0*c,0.91,true);
    if (nose!=0) { nose } else {
        i32 tail=static_hit(x-0.95*s,z-0.95*c,0.91,true);
        if (tail!=0) { tail } else { static_hit(x,z,0.91,true) }
    }
};

f32(f32,f32,f32,f32,f32,f32) body_distance_sq = fn(x,z,px,pz,s,c) {
    f32 dx=px-x; f32 dz=pz-z;
    f32 t=clamp(dx*s+dz*c,-1.05,1.05);
    sq(dx-t*s)+sq(dz-t*c)
};

unit(i32) ring = fn(kind) {
    if (collision_wait<=0.0 || kind!=collision_kind) {
        collision_kind=kind;
        collision_seq=collision_seq+1;
        collision_wait=0.22;
    };
};

unit(i32,f32,f32,f32) strike_mailboxes = fn(i,s,c,speed) {
    if (i<4) {
        u64 n=ix(i);
        if (mailbox[n][2] == 0.0 && body_distance_sq(car_x,car_z,mailbox[n][0],mailbox[n][1],s,c)<1.54) {
            if (speed>1.15) {
                mailbox[n][2]=0.001;
                mailbox[n][3]=min_f(speed*0.19,5.9);
                f32 drift=if (mailbox[n][0]>=car_x) { 0.23 } else { -0.23 };
                mailbox[n][0]=mailbox[n][0]+drift;
                vx=vx*0.91; vz=vz*0.91;
                ring(1);
            } else {
                vx=vx*0.75; vz=vz*0.75;
            };
        };
        strike_mailboxes(i+1,s,c,speed);
    };
};

unit(i32) animate_mail = fn(i) {
    if (i<4) {
        u64 n=ix(i);
        if (mailbox[n][2]>0.0) {
            mailbox[n][2]=min_f(1.51,mailbox[n][2]+dt_step*mailbox[n][3]);
            mailbox[n][3]=max_f(0.95,mailbox[n][3]*0.97);
            f32 direction=if (mailbox_home[n][0]>0.0) { 1.0 } else { -1.0 };
            mailbox[n][0]=mailbox[n][0]+direction*dt_step*max_f(0.0,mailbox[n][3]-1.03);
        };
        animate_mail(i+1);
    };
};

unit(i32,f32,f32,f32) strike_peds = fn(i,s,c,speed) {
    if (i<6) {
        u64 n=ix(i);
        if (peds[n][3]<=0.0 && body_distance_sq(car_x,car_z,peds[n][0],peds[n][1],s,c)<1.58 && speed>0.7) {
            peds[n][3]=1.65;
            peds[n][4]=0.15*vx;
            peds[n][5]=0.15*vz;
            if (speed>2.0) { vx=vx*0.78; vz=vz*0.78; }
            else { vx=vx*0.52; vz=vz*0.52; };
            ring(3);
        };
        strike_peds(i+1,s,c,speed);
    };
};

unit(i32) move_peds = fn(i) {
    if (i<6) {
        u64 n=ix(i);
        f32 dx=0.0;
        f32 dz=0.0;
        if (peds[n][3]>0.0) {
            peds[n][3]=max_f(0.0,peds[n][3]-dt_step);
            dx=peds[n][4]*dt_step; dz=peds[n][5]*dt_step;
            peds[n][4]=peds[n][4]*0.88; peds[n][5]=peds[n][5]*0.88;
        } else {
            i32 to=if (peds[n][2]>0.0) { 2 } else { 0 };
            f32 gx=sidewalks[n][ix(to)]-peds[n][0];
            f32 gz=sidewalks[n][ix(to+1)]-peds[n][1];
            f32 gap=length(gx,gz);
            if (gap < 0.48) { peds[n][2]=0.0-peds[n][2]; }
            else { dx=gx/gap*dt_step*1.45; dz=gz/gap*dt_step*1.45; };
            f32 ax=peds[n][0]-car_x; f32 az=peds[n][1]-car_z;
            f32 clearance=length(ax,az);
            f32 pace=length(vx,vz);
            if (in_car && clearance<6.9 && clearance>0.20 && pace>1.6 && ax*vx+az*vz>0.0) {
                f32 cross=ax*vz-az*vx;
                f32 side=if (cross>=0.0) { 1.0 } else { -1.0 };
                dx=dx+side*vz/pace*dt_step*2.6;
                dz=dz-side*vx/pace*dt_step*2.6;
            };
        };
        if (static_hit(peds[n][0]+dx,peds[n][1],0.28,false)==0) { peds[n][0]=peds[n][0]+dx; };
        if (static_hit(peds[n][0],peds[n][1]+dz,0.28,false)==0) { peds[n][1]=peds[n][1]+dz; };
        peds[n][6]=peds[n][6]+length(dx,dz)*3.15;
        if (peds[n][6]>6.2831853) { peds[n][6]=peds[n][6]-6.2831853; };
        move_peds(i+1);
    };
};

bool(f32,f32,i32) crossing = fn(z,dir,i) {
    if (i>=6) { false } else {
        u64 n=ix(i);
        f32 ahead=(peds[n][1]-z)*dir;
        if (ahead>0.9 && ahead<5.8 && abs_f(peds[n][0])<3.8) { true } else { crossing(z,dir,i+1) }
    }
};

bool(f32,f32,f32,i32,i32) queue_ahead = fn(x,z,dir,i,skip) {
    if (i>=4) { false } else {
        u64 n=ix(i);
        f32 ahead=(traffic[n][1]-z)*dir;
        if (i!=skip && ahead>0.0 && ahead<6.4 && abs_f(traffic[n][0]-x)<1.32) { true }
        else { queue_ahead(x,z,dir,i+1,skip) }
    }
};

unit(i32) move_traffic = fn(i) {
    if (i<4) {
        u64 n=ix(i);
        f32 x=traffic[n][0]; f32 z=traffic[n][1]; f32 direction=traffic[n][2];
        f32 pd=(car_z-z)*direction;
        f32 fd=(foot_z-z)*direction;
        bool blocked = (abs_f(car_x-x)<2.25 && pd>0.0 && pd<6.5) ||
            (!in_car && abs_f(foot_x-x)<1.45 && fd>0.0 && fd<5.7) || crossing(z,direction,0) ||
            queue_ahead(x,z,direction,0,i);
        f32 target=if (blocked) { 0.0 } else { 7.0+float_i(i%2) };
        traffic[n][3]=traffic[n][3]+clamp(target-traffic[n][3],-dt_step*9.0,dt_step*3.9);
        f32 next=z+direction*traffic[n][3]*dt_step;
        if (next>72.0 || next < -13.0) {
            f32 lane=if (direction>0.0) { -2.0 } else { 2.0 };
            if ((abs_f(car_z-next)>6.0 || abs_f(car_x-lane)>2.0) &&
                !queue_ahead(lane,next,0.0-direction,0,i)) {
                traffic[n][0]=lane;
                traffic[n][2]=0.0-direction;
                traffic[n][3]=2.5;
            } else {
                traffic[n][3]=0.0;
            };
        } else {
            traffic[n][1]=next;
        };
        move_traffic(i+1);
    };
};

i32(f32,f32,f32,f32,i32) traffic_hit = fn(x,z,s,c,i) {
    if (i>=4) { -1 } else {
        u64 n=ix(i);
        f32 tx=traffic[n][0]; f32 tz=traffic[n][1];
        if (body_distance_sq(x,z,tx,tz-0.88,s,c)<3.16 || body_distance_sq(x,z,tx,tz+0.88,s,c)<3.16) { i }
        else { traffic_hit(x,z,s,c,i+1) }
    }
};

unit(f32,f32,f32,f32,i32) move_vehicle = fn(steer,drive,s,c,brake) {
    f32 ahead=vx*s+vz*c;
    f32 sideways=vx*c-vz*s;
    f32 power=if (drive>=0.0) { drive*8.7 } else {
        if (ahead>0.5) { drive*13.5 } else { drive*4.8 }
    };
    f32 drag=if (brake!=0) { 4.25 } else { 0.35+0.026*abs_f(ahead) };
    f32 next_speed=clamp(ahead+(power-ahead*drag)*dt_step,-7.2,21.0);
    f32 yaw_speed=if (brake!=0) { 2.2 } else { 1.41 };
    f32 reverse=if (next_speed<0.0) { -1.0 } else { 1.0 };
    f32 change=steer*clamp(abs_f(next_speed)*0.19,0.0,1.0)*yaw_speed*reverse*dt_step;
    f32 yaw=wrap(car_yaw+change);
    f32 ns=sin_small(yaw); f32 nc=cos_small(yaw);
    f32 grip=if (brake!=0) { 3.0 } else { 8.45 };
    f32 slip=(sideways-next_speed*change)*(1.0-dt_step*grip);
    vx=ns*next_speed+nc*slip;
    vz=nc*next_speed-ns*slip;
    if (abs_f(drive)<0.0001 && abs_f(next_speed)<0.035 && abs_f(slip)<0.035) { vx=0.0; vz=0.0; };
    f32 dx=vx*dt_step; f32 dz=vz*dt_step;
    f32 nx=car_x+dx; f32 nz=car_z+dz;
    i32 hit=car_hit(nx,nz,ns,nc);
    i32 other=if (hit==0) { traffic_hit(nx,nz,ns,nc,0) } else { -1 };
    f32 impact=length(vx,vz);
    if (hit==0 && other<0) {
        car_x=nx; car_z=nz; car_yaw=yaw;
    } else {
        if (other>=0) {
            traffic[ix(other)][3]=traffic[ix(other)][3]*0.32;
            vx=vx*(-0.20); vz=vz*(-0.20);
            if (impact>0.9) { ring(4); };
        } else {
            bool pass_x=car_hit(nx,car_z,s,c)==0 && traffic_hit(nx,car_z,s,c,0)<0;
            bool pass_z=car_hit(car_x,nz,s,c)==0 && traffic_hit(car_x,nz,s,c,0)<0;
            if (pass_x && (!pass_z || abs_f(dx)>=abs_f(dz))) {
                car_x=nx; vx=vx*0.64; vz=vz*(-0.17);
            } else {
                if (pass_z) { car_z=nz; vx=vx*(-0.17); vz=vz*0.64; }
                else { vx=vx*(-0.16); vz=vz*(-0.16); };
            };
            if (impact>0.92) { ring(hit); };
        };
    };
    f32 hs=sin_small(car_yaw); f32 hc=cos_small(car_yaw);
    strike_mailboxes(0,hs,hc,impact);
    strike_peds(0,hs,hc,impact);
    car_roll=blend(car_roll,clamp((vx*hc-vz*hs)*0.039,-0.18,0.18),0.20);
    brake_mark=if (brake>0 || drive< -0.45) { 1.0 } else { 0.0 };
};

bool(f32,f32,i32) foot_traffic_hit = fn(x,z,i) {
    if (i>=4) { false } else {
        u64 n=ix(i);
        if (body_distance_sq(traffic[n][0],traffic[n][1],x,z,0.0,traffic[n][2])<1.46) { true }
        else { foot_traffic_hit(x,z,i+1) }
    }
};

bool(f32,f32) on_foot_clear = fn(x,z) {
    static_hit(x,z,0.31,false)==0 &&
    body_distance_sq(car_x,car_z,x,z,sin_small(car_yaw),cos_small(car_yaw))>1.38 &&
    !foot_traffic_hit(x,z,0)
};

unit(f32,f32,i32) walk = fn(strafe,drive,fast) {
    f32 axes=length(strafe,drive);
    f32 pace=if (fast!=0) { 6.1 } else { 3.85 };
    foot_speed=clamp(axes,0.0,1.0)*pace;
    if (axes>0.02) {
        f32 x=foot_x+dt_step*foot_speed*strafe/axes;
        f32 z=foot_z+dt_step*foot_speed*drive/axes;
        if (on_foot_clear(x,foot_z)) { foot_x=x; };
        if (on_foot_clear(foot_x,z)) { foot_z=z; };
        if (abs_f(strafe)>abs_f(drive)) { foot_yaw=if (strafe>0.0) { 1.57079633 } else { -1.57079633 }; }
        else { foot_yaw=if (drive>0.0) { 0.0 } else { 3.14159265 }; };
    };
};

f32() player_x = fn { if (in_car) { car_x } else { foot_x } };
f32() player_z = fn { if (in_car) { car_z } else { foot_z } };
i32() cue = fn {
    if (stage==2 || stage==3) { 0 } else {
        if (!in_car && stage==0 && sq(foot_x-tape_x)+sq(foot_z-tape_z)<5.29) { 3 }
        else {
            if (!in_car && stage==1 && sq(foot_x-dock_x)+sq(foot_z-dock_z)<5.29) { 4 }
            else {
                if (in_car) { if (length(vx,vz)<2.9) { 2 } else { 0 } }
                else {
                    if (sq(foot_x-car_x)+sq(foot_z-car_z)<10.24) { 1 } else { 0 }
                }
            }
        }
    }
};
unit() interact = fn {
    i32 what=cue();
    if (what==1) { in_car=true; }
    else {
        if (what==2) {
            f32 c=cos_small(car_yaw); f32 s=sin_small(car_yaw);
            f32 ax=car_x+c*1.6; f32 az=car_z-s*1.6;
            f32 bx=car_x-c*1.6; f32 bz=car_z+s*1.6;
            if (on_foot_clear(ax,az)) { foot_x=ax; foot_z=az; in_car=false; }
            else {
                if (on_foot_clear(bx,bz)) { foot_x=bx; foot_z=bz; in_car=false; };
            };
            if (!in_car) { vx=0.0; vz=0.0; foot_speed=0.0; foot_yaw=car_yaw; };
        } else {
            if (what==3) { stage=1; }
            else { if (what==4) { stage=2; }; };
        };
    };
};

f32(f32,f32,f32,f32,f32,i32) clear_boom = fn(x,z,dx,dz,limit,i) {
    if (i>=15 || limit<=0.75) { limit } else {
        u64 n=ix(i);
        f32 bx=buildings[n][0]-0.30; f32 ex=bx+buildings[n][2]+0.60;
        f32 bz=buildings[n][1]-0.30; f32 ez=bz+buildings[n][3]+0.60;
        bool axis_x=abs_f(dx)<0.0001;
        bool axis_z=abs_f(dz)<0.0001;
        if ((axis_x && (x<bx || x>ex)) || (axis_z && (z<bz || z>ez))) {
            clear_boom(x,z,dx,dz,limit,i+1)
        } else {
            f32 near_x=if (axis_x) { -21.0 } else { min_f((bx-x)/dx,(ex-x)/dx) };
            f32 far_x=if (axis_x) { 21.0 } else { max_f((bx-x)/dx,(ex-x)/dx) };
            f32 near_z=if (axis_z) { -21.0 } else { min_f((bz-z)/dz,(ez-z)/dz) };
            f32 far_z=if (axis_z) { 21.0 } else { max_f((bz-z)/dz,(ez-z)/dz) };
            f32 near=max_f(0.0,max_f(near_x,near_z));
            f32 far=min_f(limit,min_f(far_x,far_z));
            f32 clear=if (near<=far) { max_f(0.72,near-0.20) } else { limit };
            clear_boom(x,z,dx,dz,clear,i+1)
        }
    }
};

unit() camera_step = fn {
    f32 aim=if (in_car) { car_yaw } else { 0.0 };
    camera_yaw=wrap(camera_yaw+wrap(aim-camera_yaw)*0.15);
    f32 hx=sin_small(camera_yaw); f32 hz=cos_small(camera_yaw);
    f32 sx=player_x(); f32 sz=player_z();
    f32 goal=if (in_car) { 8.4 } else { 7.0 };
    f32 dist=clear_boom(sx,sz,-hx,-hz,goal,0);
    camera_x=sx-dist*hx;
    camera_z=sz-dist*hz;
    camera_y=blend(camera_y,if (dist<3.8) { 2.35 } else { if (in_car) { 4.2 } else { 3.9 } },0.38);
    camera_pitch=blend(camera_pitch,if (dist<3.8) { -0.48 } else { if (in_car) { -0.29 } else { -0.25 } },0.22);
};

unit() snapshot = fn {
    old_x=car_x; old_z=car_z; old_yaw=car_yaw;
    old_foot_x=foot_x; old_foot_z=foot_z; old_foot_yaw=foot_yaw;
    old_camera_x=camera_x; old_camera_y=camera_y; old_camera_z=camera_z; old_camera_yaw=camera_yaw;
};

unit(f32,f32,i32) step = fn(steer,drive,flags) {
    snapshot();
    i32 begin=stage;
    collision_wait=max_f(0.0,collision_wait-dt_step);
    if (pending_action) { pending_action=false; interact(); };
    if (stage!=2) {
        if (in_car) { move_vehicle(steer,drive,sin_small(car_yaw),cos_small(car_yaw),flags & 1); }
        else { walk(steer,drive,flags & 1); };
        move_traffic(0);
        move_peds(0);
        animate_mail(0);
    };
    if (stage==1 && begin==1) {
        seconds_left=max_f(0.0,seconds_left-dt_step);
        if (seconds_left<=0.0) { stage=3; };
    };
    if (stage==3) { ferry_z=min_f(114.0,ferry_z+dt_step*3.8); };
    camera_step();
};

unit(f32,f32,i32,i32) advance = fn(steer,drive,controls,limit) {
    if (limit>0 && accumulator>=dt_step) {
        accumulator=accumulator-dt_step;
        step(steer,drive,controls);
        advance(steer,drive,controls,limit-1);
    };
};
unit(f32,f32,f32,f32,f32) set_model = fn(x,y,z,yaw,roll) {
    model_local=true;
    model_x=x; model_y=y; model_z=z;
    model_hs=sin_small(yaw); model_hc=cos_small(yaw);
    model_rs=sin_small(roll); model_rc=cos_small(roll);
};

unit(f32,f32) tire = fn(x,z) {
    box(x-0.15,0.031,z-0.33,0.30,0.62,0.66,0.14,0.15,0.21);
    f32 e=if (x<0.0) { x-0.157 } else { x+0.157 };
    quad(e,0.18,z-0.15,e,0.18,z+0.15,e,0.45,z+0.15,e,0.45,z-0.15,0.45,0.49,0.56);
};
unit(f32,f32,f32,f32,f32,f32,f32) light = fn(x,y,z,w,h,r,g) {
    quad(x,y,z,x+w,y,z,x+w,y+h,z,x,y+h,z,r,g,0.19);
};

unit(f32,f32,f32,bool) body = fn(r,g,b,brake) {
    tire(-0.91,-1.19); tire(0.91,-1.19); tire(-0.91,1.19); tire(0.91,1.19);
    box(-0.92,0.32,-1.93,1.84,0.47,3.86,r,g,b);
    box(-0.88,0.79,-1.91,1.76,0.16,1.02,r*1.06,g*1.06,b*1.04);
    box(-0.85,0.79,0.59,1.70,0.16,1.31,r*1.10,g*1.10,b*1.08);
    box(-0.79,0.77,-0.90,1.58,0.56,1.60,0.18,0.32,0.42);
    box(-0.70,1.30,-0.72,1.40,0.16,1.18,r,g,b);
    light(-0.93,0.45,-1.94,1.86,0.09,0.69,0.72);
    light(-0.93,0.45,1.94,1.86,0.09,0.69,0.72);
    light(-0.79,0.61,1.94,0.41,0.17,1.0,0.96);
    light(0.38,0.61,1.94,0.41,0.17,1.0,0.96);
    f32 glow=if (brake) { 0.27 } else { 0.04 };
    light(-0.81,0.61,-1.94,0.36,0.17,0.97,glow);
    light(0.45,0.61,-1.94,0.36,0.17,0.97,glow);
};

unit(i32) draw_traffic = fn(i) {
    if (i<4) {
        u64 n=ix(i);
        f32 yaw=if (traffic[n][2]>0.0) { 0.0 } else { 3.14159265 };
        set_model(traffic[n][0],0.01,traffic[n][1],yaw,0.0);
        if (i%2==0) { body(0.24,0.65,0.66,traffic[n][3]<4.0); }
        else { body(0.71,0.54,0.29,traffic[n][3]<4.0); };
        draw_traffic(i+1);
    };
};

unit(f32,f32,f32,f32) person = fn(r,g,b,gait) {
    f32 wave=sin_small(wrap(gait));
    box(-0.235,0.61,-0.16,0.47,0.54,0.32,r,g,b);
    box(-0.17,1.17,-0.145,0.34,0.36,0.29,0.84,0.61,0.46);
    box(-0.18,1.47,-0.153,0.36,0.08,0.31,0.24,0.17,0.22);
    box(-0.24,0.075,-0.11+wave*0.10,0.18,0.55,0.23,0.29,0.25,0.35);
    box(0.06,0.075,-0.11-wave*0.10,0.18,0.55,0.23,0.29,0.25,0.35);
    box(-0.342,0.56,-0.12-wave*0.10,0.109,0.48,0.18,r*0.84,g*0.84,b*0.84);
    box(0.233,0.56,-0.12+wave*0.10,0.109,0.48,0.18,r*0.84,g*0.84,b*0.84);
};

unit(i32) draw_peds = fn(i) {
    if (i<6) {
        u64 n=ix(i);
        f32 yaw=if (peds[n][2]>0.0) { 0.0 } else { 3.14159265 };
        f32 stun=peds[n][3];
        f32 roll=if (stun>0.0) {
            1.48*min_f(clamp((1.65-stun)*7.1,0.0,1.0),clamp(stun*2.6,0.0,1.0))
        } else { 0.0 };
        set_model(peds[n][0],abs_f(sin_small(roll))*0.27,peds[n][1],yaw,roll);
        f32 r=if (i%3==0) { 0.93 } else { 0.31+0.16*float_i(i%3) };
        person(r,0.61,0.49+0.05*float_i(i),peds[n][6]);
        draw_peds(i+1);
    };
};

unit(i32) draw_mail = fn(i) {
    if (i<4) {
        u64 n=ix(i);
        f32 tilt=mailbox[n][2];
        f32 roll=if (mailbox_home[n][0]>0.0) { 0.0-tilt } else { tilt };
        set_model(mailbox[n][0],0.055+sin_small(tilt)*0.21,mailbox[n][1],0.0,roll);
        box(-0.052,0.0,-0.052,0.104,0.83,0.104,0.52,0.36,0.27);
        box(-0.23,0.74,-0.19,0.46,0.26,0.38,0.32,0.58,0.75);
        box(-0.196,0.98,-0.16,0.392,0.07,0.32,0.44,0.70,0.81);
        box(-0.093,0.91,-0.202,0.19,0.035,0.034,0.14,0.23,0.34);
        box(0.22,0.91,0.05,0.045,0.14,0.16,0.91,0.33,0.39);
        draw_mail(i+1);
    };
};

unit() boat = fn {
    set_model(11.0,0.0,ferry_z,0.0,0.0);
    box(-3.8,0.00,-2.47,7.6,0.84,10.88,0.28,0.47,0.58);
    box(-3.75,0.79,-2.4,7.5,0.42,10.7,0.95,0.76,0.51);
    box(-3.8,1.21,-2.4,0.14,0.61,10.7,0.93,0.83,0.64);
    box(3.66,1.21,-2.4,0.14,0.61,10.7,0.93,0.83,0.64);
    box(-2.6,1.20,1.75,5.2,2.2,4.5,0.94,0.84,0.69);
    box(-2.69,3.33,1.65,5.38,0.22,4.7,0.38,0.63,0.67);
    box(-2.22,2.23,1.66,4.44,0.75,0.13,0.30,0.56,0.66);
    box(-2.66,2.23,2.04,0.13,0.75,3.80,0.32,0.57,0.64);
    box(2.53,2.23,2.04,0.13,0.75,3.80,0.32,0.57,0.64);
    box(-0.085,3.55,4.12,0.17,1.94,0.17,0.65,0.54,0.48);
    box(-1.13,4.19,4.12,1.12,0.64,0.11,0.94,0.45,0.43);
    box(-1.45,0.11,-3.70,2.9,0.19,1.31,0.72,0.53,0.42);
};

unit(f32,f32,f32,f32,f32) objective = fn(x,z,r,g,b) {
    f32 t=0.27;
    if (stage==0) {
        box(x-0.36,0.04,z-0.27,0.72,0.52,0.54,0.83,0.61,0.41);
        box(x-0.23,0.56,z-0.129,0.46,0.083,0.258,0.31,0.23,0.37);
        box(x-0.19,0.644,z-0.085,0.38,0.025,0.17,0.88,0.42,0.54);
        t=0.41;
    };
    diamond(x,1.67,z,t,0.78,r,g,b);
    tri(x-t,1.67,z,x,1.22,z,x,1.67,z+t,r*0.77,g*0.77,b*0.77);
    tri(x+t,1.67,z,x,1.22,z,x,1.67,z-t,r*0.77,g*0.77,b*0.77);
};

unit(f32) render_moving = fn(alpha) {
    vertex_count=0; drawing_world=false;
    f32 vis_yaw=wrap(old_yaw+alpha*wrap(car_yaw-old_yaw));
    set_model(blend(old_x,car_x,alpha),0.01,blend(old_z,car_z,alpha),vis_yaw,car_roll);
    body(0.86,0.26,0.45,brake_mark>0.0);
    if (!in_car) {
        f32 view_foot=wrap(old_foot_yaw+alpha*wrap(foot_yaw-old_foot_yaw));
        set_model(blend(old_foot_x,foot_x,alpha),0.01,blend(old_foot_z,foot_z,alpha),view_foot,0.0);
        f32 gait=(foot_x+foot_z)*2.7;
        person(0.36,0.83,0.76,wrap(gait-6.2831853*float_i(core.float_to_sint_trunc<i32>(gait/6.2831853))));
    };
    draw_traffic(0);
    draw_mail(0);
    draw_peds(0);
    boat();
    model_local=false;
    if (stage==0) { objective(tape_x,tape_z,1.0,0.63,0.35); };
    if (stage==1) { objective(dock_x,dock_z,0.47,0.99,0.78); };
    unsafe { host.moving(core.pointer_cast<*?u8>(&?moving_mesh[0][0][0][0]),vertex_count*6); };
};

unit(f32) render_frame = fn(alpha) {
    f32 view_yaw=wrap(old_camera_yaw+alpha*wrap(camera_yaw-old_camera_yaw));
    f32 hx=sin_small(view_yaw); f32 hz=cos_small(view_yaw);
    f32 ps=sin_small(camera_pitch); f32 pc=cos_small(camera_pitch);
    f32 fx=hx*pc; f32 fy=ps; f32 fz=hz*pc;
    f32 ux=-hx*ps; f32 uy=pc; f32 uz=-hz*ps;
    f32 ex=blend(old_camera_x,camera_x,alpha);
    f32 ey=blend(old_camera_y,camera_y,alpha);
    f32 ez=blend(old_camera_z,camera_z,alpha);
    f32 sy=if (viewport<0.85) { 1.16 } else { 1.48 };
    f32 sx=sy/viewport;
    f32 nf=1.002001;
    display[0]=hz*sx; display[1]=ux*sy; display[2]=fx*nf; display[3]=fx;
    display[4]=0.0; display[5]=uy*sy; display[6]=fy*nf; display[7]=fy;
    display[8]=-hx*sx; display[9]=uz*sy; display[10]=fz*nf; display[11]=fz;
    display[12]=-(hz*ex-hx*ez)*sx;
    display[13]=-(ux*ex+uy*ey+uz*ez)*sy;
    f32 offset=-(fx*ex+fy*ey+fz*ez);
    display[14]=offset*nf-0.3003;
    display[15]=offset;
    f32 px=player_x(); f32 pz=player_z();
    f32 tx=if (stage==0) { tape_x } else { if (stage==1) { dock_x } else { px } };
    f32 tz=if (stage==0) { tape_z } else { if (stage==1) { dock_z } else { pz } };
    f32 dx=tx-px; f32 dz=tz-pz;
    f32 heading=if (in_car) { car_yaw } else { 0.0 };
    f32 hs=sin_small(heading); f32 hc=cos_small(heading);
    f32 side=dx*hc-dz*hs;
    f32 ahead=dx*hs+dz*hc;
    display[16]=if (in_car) { 1.0 } else { 0.0 };
    display[17]=float_i(stage);
    display[18]=seconds_left;
    display[19]=3.6*(if (in_car) { length(vx,vz) } else { foot_speed });
    display[20]=float_i(cue());
    display[21]=float_i(collision_kind);
    display[22]=float_i(collision_seq);
    display[23]=length(dx,dz);
    display[24]=tx; display[25]=tz; display[26]=px; display[27]=pz;
    display[28]=heading;
    display[29]=if (stage>1 || length(dx,dz)<0.25) { 0.0 } else {
        if (ahead<=0.0) { if (side<0.0) { -1.0 } else { 1.0 } }
        else { clamp(side*1.3/ahead,-1.0,1.0) }
    };
    unsafe { host.frame(core.pointer_cast<*?u8>(&?display[0]),30); };
};

unit(i32) reset_props = fn(i) {
    if (i<6) {
        u64 n=ix(i);
        peds[n][0]=sidewalks[n][0]; peds[n][1]=sidewalks[n][1]; peds[n][2]=1.0;
        peds[n][3]=0.0; peds[n][4]=0.0; peds[n][5]=0.0; peds[n][6]=0.0;
        if (i<4) {
            mailbox[n][0]=mailbox_home[n][0]; mailbox[n][1]=mailbox_home[n][1];
            mailbox[n][2]=0.0; mailbox[n][3]=0.0;
            traffic[n][0]=traffic_home[n][0]; traffic[n][1]=traffic_home[n][1];
            traffic[n][2]=if (i%2==0) { 1.0 } else { -1.0 };
            traffic[n][3]=if (i==0) { 5.0 } else { 2.7 };
        };
        reset_props(i+1);
    };
};

unit() cancel_action = fn { pending_action=false; };

unit(i32) reset = fn(mode) {
    if (!world_ready) { render_world(); };
    stage=if (mode==1) { 4 } else { 0 };
    in_car=false; pending_action=false; seconds_left=90.0; accumulator=0.0;
    collision_wait=0.0; collision_kind=0; collision_seq=0;
    car_x=0.0; car_z=-5.0; car_yaw=0.0; vx=0.0; vz=0.0; brake_mark=0.0; car_roll=0.0;
    foot_x=2.1; foot_z=-4.6; foot_speed=0.0; foot_yaw=0.0;
    camera_x=2.1; camera_z=-11.6; camera_y=3.9; camera_yaw=0.0; camera_pitch=-0.25;
    ferry_z=88.0;
    reset_props(0); snapshot();
    render_moving(1.0); render_frame(1.0);
};

unit(f32,f32,f32,i32,f32) tick = fn(dt,steer,drive,controls,aspect) {
    if (aspect>=0.25 && aspect<=4.0) { viewport=aspect; };
    if ((controls & 2)!=0 && stage!=2 && stage!=3) {
        pending_action=true;
    };
    f32 safe_dt=if (dt>=0.0 && dt<=1.0) { min_f(dt,0.10) } else { 0.0 };
    accumulator=accumulator+safe_dt;
    f32 steering=if (steer>=-1.0 && steer<=1.0) { steer } else { 0.0 };
    f32 throttle=if (drive>=-1.0 && drive<=1.0) { drive } else { 0.0 };
    if (safe_dt>0.0) { advance(steering,throttle,controls,6); };
    f32 alpha=clamp(accumulator/dt_step,0.0,1.0);
    render_moving(alpha);
    render_frame(alpha);
};
%%end
