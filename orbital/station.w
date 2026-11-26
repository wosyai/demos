%%start
wing_art = namespace orbital "station-material.w";
struct copy Part { i32 section; i32 axis; i32 finish; f32 x; f32 y; f32 z; f32 l; f32 u; f32 v; f32 taper; }
Part empty={.section=0;.axis=0;.finish=0;.x=0.0;.y=0.0;.z=0.0;.l=0.0;.u=0.0;.v=0.0;.taper=1.0;};
Part[16] row=[empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty,empty];
Part[16][16] parts=[row,row,row,row,row,row,row,row,row,row,row,row,row,row,row,row];
i32 total=0;
unit(i32,i32,i32,f32,f32,f32,f32,f32,f32,f32) put=fn(section,axis,finish,x,y,z,l,u,v,taper){
    u64 i=core.int_extend<u64>(total/16);u64 j=core.int_extend<u64>(total%16);
    parts[i][j].section=section;
    parts[i][j].axis=axis;
    parts[i][j].finish=finish;
    parts[i][j].x=x;
    parts[i][j].y=y;
    parts[i][j].z=z;
    parts[i][j].l=l;
    parts[i][j].u=u;
    parts[i][j].v=v;
    parts[i][j].taper=taper;
    total=total+1;
};
Part(i32) at=fn(i){parts[core.int_extend<u64>(i/16)][core.int_extend<u64>(i%16)]};
unit(f32,f32,f32,f32,f32,f32,i32) plank=fn(x,y,z,w,h,d,finish){put(0,0,finish,x+w*0.5,y+h*0.5,z,d,w*0.5,h*0.5,1.0);};
unit(i32,i32,f32,f32,f32,f32,f32,f32) tube=fn(ax,finish,x,y,z,l,r,taper){put(if(r>0.66){2}else{1},ax,finish,x,y,z,l,r,r,taper);};
struct copy CatwalkBox { f32 x; f32 y; f32 z; f32 u; f32 v; f32 w; }
f32(i32) catwalk_z=fn(row_id){-2.1-0.58*core.sint_to_float<f32>(row_id)};
CatwalkBox(i32,i32) catwalk_box=fn(row_id,member){
    f32 z0=catwalk_z(row_id);
    CatwalkBox b=if(member==0){
        CatwalkBox lower={.x=-1.57;.y=-1.10;.z=z0;.u=0.92;.v=0.044;.w=0.051;};lower
    }else{if(member==1){
        CatwalkBox upright={.x=-1.53;.y=1.25;.z=z0;.u=0.092;.v=0.46;.w=0.08;};upright
    }else{
        CatwalkBox top={.x=-1.38;.y=1.71;.z=z0;.u=0.426;.v=0.050;.w=0.055;};top
    }};
    b
};
i32 catwalk_count=9;
Part(i32) catwalk_collision=fn(id){
    CatwalkBox b=catwalk_box(id/3,id%3);
    Part pl={.section=0;.axis=0;.finish=0;.x=b.x+b.u*0.5;.y=b.y+b.v*0.5;.z=b.z;
        .l=b.w;.u=b.u*0.5;.v=b.v*0.5;.taper=1.0;};pl
};
struct copy RailShaft { f32 min_x; f32 max_x; i32 sides; }
f32(i32) rail_depth=fn(leg){if(leg==0){-1.59}else{if(leg==1){-3.43}else{-4.88}}};
f32 rail_y=-0.57;
f32 rail_radius=0.087;
RailShaft(i32) rail_shaft=fn(id){
    RailShaft r=if(id<2){RailShaft continuous={.min_x=-1.55;.max_x=1.13;.sides=48;};continuous}
    else{if(id==2){RailShaft left={.min_x=-1.55;.max_x=-0.55;.sides=36;};left}
    else{RailShaft right={.min_x=0.30;.max_x=0.95;.sides=24;};right}};
    r
};
i32(i32) rail_leg=fn(id){if(id<2){id}else{2}};
CatwalkBox(f32,f32,f32) rail_base_plate=fn(x,z,length){
    f32 base=-0.64-length;
    CatwalkBox foot={.x=x-0.115;.y=base-0.041;.z=z-0.095;.u=0.23;.v=0.065;.w=0.20;};foot
};
CatwalkBox(i32) rail_foot_box=fn(id){
    i32 leg=id/2;f32 z0=rail_depth(leg);bool left=id%2==0;
    if(leg<2){
        if(left){rail_base_plate(-1.30,z0,0.238)}else{rail_base_plate(0.755,z0,0.44)}
    }else{
        CatwalkBox bracket=if(left){
            CatwalkBox low={.x=-1.41;.y=-0.88;.z=z0-0.03;.u=0.22;.v=0.25;.w=0.061;};low
        }else{
            CatwalkBox high={.x=0.70;.y=-1.10;.z=z0-0.03;.u=0.17;.v=0.48;.w=0.061;};high
        };
        bracket
    }
};
Part(i32) rail_foot_collision=fn(id){
    CatwalkBox b=rail_foot_box(id);
    Part pl={.section=0;.axis=0;.finish=0;.x=b.x+b.u*0.5;.y=b.y+b.v*0.5;.z=b.z;
        .l=b.w;.u=b.u*0.5;.v=b.v*0.5;.taper=1.0;};pl
};
unit(i32) spine_band=fn(i){if(i<8){
    f32 z= -11.8+core.sint_to_float<f32>(i)*2.36;
    tube(0,1,-4.69,0.0,z,0.14,1.98,1.0);
    tube(0,4,-4.69,0.0,z+0.14,0.060,1.96,1.0);
    spine_band(i+1);
};};
unit(i32) lattice=fn(i){if(i<20){
    f32 x= -17.0+core.sint_to_float<f32>(i)*1.18;
    plank(x,2.0,-9.88,0.07,1.18,0.34,1);
    i32 tilt=if(i%2==0){3}else{4};
    f32 y=if(i%2==0){2.0}else{3.18};
    put(0,tilt,3,x,y,-9.70,1.669,0.045,0.15,1.0);
    lattice(i+1);
};};
i32[6] solar_parts=[0,0,0,0,0,0];
i32 solar_count=0;
i32(i32) solar_member=fn(i){solar_parts[core.int_extend<u64>(i/5)]+i%5};
unit(f32,f32) wing=fn(x,z){
    solar_parts[core.int_extend<u64>(solar_count)]=total;solar_count=solar_count+1;
    plank(x,2.66,z,wing_art.wing_width(),0.088,wing_art.wing_depth(),5);
    plank(x,2.63,z+0.02,0.074,0.16,5.66,3);
    plank(x+4.88,2.63,z+0.02,0.074,0.16,5.66,3);
    plank(x,2.64,z,4.95,0.13,0.095,1);
    plank(x,2.64,z+5.62,4.95,0.13,0.095,1);
};
unit(i32) radiator=fn(i){if(i<5){
    f32 z= -5.4+core.sint_to_float<f32>(i)*1.12;
    plank(-10.32,1.14,z,3.43,0.12,0.96,6);radiator(i+1);
};};
unit(i32) portholes=fn(i){if(i<4){
    f32 z= -1.2+core.sint_to_float<f32>(i)*1.55;
    tube(1,1,-6.63,0.24,z,0.16,0.41,1.0);tube(1,8,-6.69,0.24,z,0.055,0.31,1.0);
    portholes(i+1);
};};
unit(f32,f32) nozzle=fn(x,y){
    tube(0,1,x,y,-24.69,0.09,0.38,1.0);
    tube(0,9,x,y,-24.60,0.64,0.35,0.49);
    tube(0,3,x,y,-23.96,0.26,0.18,1.0);
    tube(0,9,x,y,-24.71,0.03,0.324,1.0);
};
unit(i32) plumbing=fn(i){if(i<4){
    f32 z= -12.0+core.sint_to_float<f32>(i)*3.2;
    plank(-5.40,1.79,z,1.23,0.25,0.16,1);
    plank(-3.28,1.84,z+0.45,1.38,0.19,1.17,4);
    plank(-3.27,2.03,z+0.48,1.35,0.03,1.11,6);
    plumbing(i+1);
};};
unit() build=fn{
 if(total==0){
    tube(0,1,-4.69,0.0,-16.1,0.92,0.88,1.75);
    tube(0,2,-4.69,0.0,-15.18,2.4,1.54,1.24);
    tube(0,0,-4.69,0.0,-12.78,17.5,1.91,1.0);spine_band(0);
    tube(0,2,-4.69,0.0,4.72,1.05,1.91,0.76);
    tube(0,1,-4.69,0.0,5.77,0.24,1.47,1.0);
    tube(0,0,-4.69,0.0,6.01,1.62,1.36,0.85);
    tube(0,8,-4.69,0.0,7.63,0.67,1.16,0.63);
    tube(0,1,-4.69,0.0,8.30,0.13,0.74,1.0);
    tube(0,9,-4.69,0.0,8.43,0.065,0.58,1.0);
    tube(0,1,-4.69,0.0,8.495,0.092,0.40,1.0);
    tube(0,8,-4.69,0.0,8.587,0.012,0.33,1.0);
    plank(-5.63,-0.085,7.78,0.25,0.17,0.57,1);plank(-4.00,-0.085,7.78,0.25,0.17,0.57,1);
    plank(-4.77,-0.94,7.78,0.16,0.26,0.57,1);plank(-4.77,0.68,7.78,0.16,0.26,0.57,1);
    plank(-5.53,-0.035,8.35,0.10,0.07,0.03,10);plank(-3.92,-0.035,8.35,0.10,0.07,0.03,10);
    plumbing(0);
    tube(0,1,-4.85,2.01,-12.0,10.90,0.105,1.0);
    tube(0,3,-4.48,2.04,-12.0,10.90,0.073,1.0);
    nozzle(-4.19,0.50);nozzle(-5.19,0.50);nozzle(-4.19,-0.50);nozzle(-5.19,-0.50);
    plank(-5.65,-1.92,-22.4,0.38,0.57,1.47,1);
    plank(-4.02,-1.92,-22.4,0.38,0.57,1.47,1);
    tube(2,9,-5.46,-2.02,-21.71,0.11,0.20,1.0);tube(2,9,-3.83,-2.02,-21.71,0.11,0.20,1.0);
    tube(0,9,-4.69,0.0,-23.9,0.45,1.14,1.06);
    tube(0,3,-4.69,0.0,-23.45,0.66,1.22,1.18);
    tube(0,2,-4.69,0.0,-22.79,3.45,1.45,1.0);
    tube(0,1,-4.69,0.0,-19.34,0.25,1.48,1.0);
    tube(0,0,-4.69,0.0,-19.09,1.82,1.45,0.52);
    tube(0,1,-4.69,0.0,-17.27,1.18,0.73,1.0);
    tube(0,3,-4.69,0.0,-16.80,0.19,0.87,1.0);
    tube(1,0,-11.40,-0.30,-5.80,4.99,1.38,1.0);
    tube(1,1,-11.65,-0.30,-5.80,0.25,1.43,1.0);
    tube(1,8,-12.42,-0.30,-5.80,0.77,0.78,1.68);
    tube(1,1,-12.53,-0.30,-5.80,0.11,0.82,1.0);
    tube(1,8,-12.57,-0.30,-5.80,0.04,0.68,1.0);
    tube(1,1,-9.70,-0.30,-5.80,0.13,1.42,1.0);
    tube(1,3,-7.20,-0.30,-5.80,0.16,1.40,1.0);
    plank(-10.0,-0.16,-4.54,0.19,1.36,0.24,1);
    plank(-10.12,1.02,-5.56,0.16,0.17,5.83,1);radiator(0);portholes(0);
    plank(-17.0,1.94,-9.92,23.72,0.13,0.43,1);plank(-17.0,3.13,-9.92,23.72,0.13,0.43,1);
    lattice(0);
    tube(2,1,-4.69,0.98,-9.7,1.64,0.47,1.0);
    plank(-16.8,2.52,-10.03,23.1,0.27,0.62,3);
    wing(wing_art.wing_x(0),wing_art.wing_z(0));wing(wing_art.wing_x(1),wing_art.wing_z(0));wing(wing_art.wing_x(2),wing_art.wing_z(0));
    wing(wing_art.wing_x(0),wing_art.wing_z(1));wing(wing_art.wing_x(1),wing_art.wing_z(1));wing(wing_art.wing_x(2),wing_art.wing_z(1));
    tube(2,1,-4.69,1.62,2.5,2.14,0.13,1.0);
    tube(2,3,-4.69,3.76,2.5,0.33,0.30,1.0);
    tube(2,0,-4.69,4.09,2.5,0.68,0.30,4.40);
    tube(2,1,-4.69,4.77,2.5,0.09,1.34,1.0);
    tube(2,1,-4.69,4.86,2.5,0.62,0.043,1.0);tube(2,3,-4.69,5.48,2.5,0.12,0.15,1.0);
 };
};

f32(i32,f32,f32) xx=fn(a,u,w){if(a==1){w}else{if(a==3){0.70710678*(w-u)}else{if(a==4){0.70710678*(w+u)}else{u}}}};
f32(i32,f32,f32,f32) yy=fn(a,u,v,w){if(a==2){w}else{if(a==3){0.70710678*(w+u)}else{if(a==4){0.70710678*(u-w)}else{v}}}};
f32(i32,f32,f32,f32) zz=fn(a,u,v,w){if(a==1){-u}else{if(a==2||a==3||a==4){-v}else{w}}};
%%end
