%%start
art = namespace orbital "avatar-kinematics.w";
station = namespace orbital "station.w";
math = namespace orbital "presentation.w";
struct copy Probe { art.Vec local; art.Vec half; }
struct copy Interval { bool possible; f64 enter; f64 leave; f64 sign; }
struct copy Sweep { bool possible; f64 enter; f64 leave; art.Vec normal; }
struct copy Hit { bool active; f64 time; art.Vec normal; }
Probe(f64,f64,f64,f64,f64,f64) probe=fn(f,u,r,hf,hu,hr){
    Probe item={.local=art.v(f,u,r);.half=art.v(hf,hu,hr);};item
};
Probe(i32) register=fn(id){
    if(id==0){probe(0.140,0.026,0.0,0.188,0.242,0.207)}
    else{if(id==1){probe(0.015,-0.316,0.0,0.334,0.423,0.294)}
    else{if(id==2){probe(0.099,-0.643,0.0,0.259,0.101,0.239)}
    else{if(id==3){probe(0.107,-1.061,-0.167,0.181,0.462,0.155)}
    else{if(id==4){probe(0.107,-1.061,0.132,0.181,0.462,0.142)}
    else{if(id==5){probe(0.143,-1.480,-0.218,0.207,0.145,0.151)}
    else{if(id==6){probe(0.143,-1.480,0.127,0.207,0.145,0.130)}
    else{if(id==7){probe(0.304,-0.253,-0.280,0.365,0.218,0.162)}
    else{if(id==8){probe(0.304,-0.253,0.280,0.365,0.218,0.162)}
    else{probe(-0.095,0.322,0.0,0.075,0.122,0.230)}}}}}}}}}
};
art.Vec(art.Axes,art.Vec) rotate=fn(axes,p){
    art.add(art.mul(axes.forward,p.x),art.add(art.mul(axes.up,p.y),art.mul(axes.right,p.z)))
};
f64(f64,f64,f64,art.Vec) extent=fn(f,u,r,h){
    math.abs(f)*h.x+math.abs(u)*h.y+math.abs(r)*h.z
};
Interval(f64,f64,f64,f64,f64) slab=fn(o,v,floor_limit,ceiling_limit,dt){
    if(math.abs(v)<0.0000001){
        Interval quiet={.possible=o>=floor_limit&&o<=ceiling_limit;.enter=-100000.0;.leave=dt;.sign=0.0;};quiet
    }else{
        f64 p=(floor_limit-o)/v;f64 q=(ceiling_limit-o)/v;bool f=v>0.0;
        Interval moving={.possible=true;.enter=if(f){p}else{q};.leave=if(f){q}else{p};.sign=if(f){-1.0}else{1.0};};moving
    }
};
f64(f64,f64) lo=fn(a,b){if(a<b){a}else{b}};
f64(f64,f64) hi=fn(a,b){if(a>b){a}else{b}};
Hit(f64) none=fn(dt){
    Hit miss={.active=false;.time=dt;.normal=art.v(0.0,0.0,0.0);};miss
};
f64(f32) f64v=fn(x){core.float_extend<f64>(x)};
art.Vec(i32) unit_axis=fn(id){
    if(id==0){art.v(1.0,0.0,0.0)}else{if(id==1){art.v(0.0,1.0,0.0)}else{art.v(0.0,0.0,1.0)}}
};
art.Vec(art.Axes,i32) body_axis=fn(body,id){
    if(id==0){body.forward}else{if(id==1){body.up}else{body.right}}
};
f64(art.Vec,art.Vec) support_radius=fn(axis,half){
    math.abs(axis.x)*half.x+math.abs(axis.y)*half.y+math.abs(axis.z)*half.z
};
Sweep(i32,art.Axes,art.Vec,art.Vec,art.Vec,art.Vec,f64,f64,Sweep) intervals=fn(i,body,offset,velocity,actor,stage,dt,padding,best){
    if(i==15||!best.possible){best}else{
        art.Vec raw_axis=if(i<3){unit_axis(i)}else{if(i<6){body_axis(body,i-3)}else{
            art.cross(unit_axis((i-6)/3),body_axis(body,(i-6)%3))
        }};
        if(art.dot(raw_axis,raw_axis)<0.000000000001){
            intervals(i+1,body,offset,velocity,actor,stage,dt,padding,best)
        }else{
            art.Vec sep_axis=art.normalized(raw_axis);
            art.Vec in_body=art.v(art.dot(sep_axis,body.forward),art.dot(sep_axis,body.up),art.dot(sep_axis,body.right));
            f64 reach=support_radius(sep_axis,stage)+support_radius(in_body,actor)+padding;
            Interval span=slab(art.dot(offset,sep_axis),art.dot(velocity,sep_axis),-reach,reach,dt);
            f64 latest=hi(best.enter,span.enter);f64 earliest=lo(best.leave,span.leave);
            Sweep next={.possible=span.possible&&latest<=earliest&&latest<=dt&&earliest>=0.0;
                .enter=latest;.leave=earliest;.normal=if(span.enter>best.enter){art.mul(sep_axis,span.sign)}else{best.normal};};
            intervals(i+1,body,offset,velocity,actor,stage,dt,padding,next)
        }
    }
};
Hit(i32,art.Axes,art.Vec,art.Vec,art.Vec,art.Vec,f64) solid=fn(idx,body,from,velocity,half,actor,dt){
    station.Part p=station.at(idx);
    f64 x=f64v(p.x);f64 y=f64v(p.y);f64 z=f64v(p.z);
    f64 w=f64v(p.u);f64 h=f64v(p.v);f64 length0=f64v(p.l);
    Interval a=slab(from.x,velocity.x,x-w-half.x,x+w+half.x,dt);
    Interval b=slab(from.y,velocity.y,y-h-half.y,y+h+half.y,dt);
    Interval c=slab(from.z,velocity.z,z-half.z,z+length0+half.z,dt);
    f64 enter=hi(a.enter,hi(b.enter,c.enter));f64 leave=lo(a.leave,lo(b.leave,c.leave));
    if(a.possible&&b.possible&&c.possible&&enter<=dt&&leave>=0.0&&enter<=leave){
        art.Vec center=art.v(x,y,z+length0*0.5);
        Sweep start={.possible=true;.enter=-100000.0;.leave=dt;.normal=art.v(0.0,0.0,0.0);};
        Sweep exact=intervals(0,body,art.sub(from,center),velocity,actor,art.v(w,h,length0*0.5),dt,0.003,start);
        if(exact.possible&&exact.enter>=-0.00002&&art.dot(exact.normal,velocity)<0.0){
            Hit actual={.active=true;.time=hi(0.0,exact.enter);.normal=exact.normal;};actual
        }else{none(dt)}
    }else{none(dt)}
};
Hit(i32,art.Axes,art.Vec,art.Vec,art.Vec,art.Vec,f64,Hit) parts=fn(i,body,from,v,half,actor,dt,best){
    if(i==station.solar_count*5){best}else{
        Hit found=solid(station.solar_member(i),body,from,v,half,actor,dt);
        Hit earlier=if(found.active&&(!best.active||found.time<best.time)){found}else{best};
        parts(i+1,body,from,v,half,actor,dt,earlier)
    }
};
Hit(i32,art.Axes,art.Vec,art.Vec,f64,Hit) swept=fn(id,axes,origin,v,dt,best){
    if(id==10){best}else{
        Probe p=register(id);art.Vec from=art.add(origin,rotate(axes,p.local));
        art.Vec half=art.v(extent(axes.forward.x,axes.up.x,axes.right.x,p.half)+0.003,
            extent(axes.forward.y,axes.up.y,axes.right.y,p.half)+0.003,
            extent(axes.forward.z,axes.up.z,axes.right.z,p.half)+0.003);
        Hit found=parts(0,axes,from,v,half,p.half,dt,best);
        swept(id+1,axes,origin,v,dt,found)
    }
};
bool(art.Vec,art.Vec) outside=fn(origin,endpoint){
    hi(origin.y,endpoint.y)<0.78||lo(origin.y,endpoint.y)>4.90||hi(origin.x,endpoint.x)< -22.0
        ||lo(origin.x,endpoint.x)>10.0||hi(origin.z,endpoint.z)< -22.0||lo(origin.z,endpoint.z)>0.0
};
Hit(f32,f32,f32,f32,f32,f32,f32,f32,f32) solar=fn(x,y,z,vx,vy,vz,yaw,pitch,step){
    f64 dt=f64v(step);art.Vec from=art.v(f64v(x),f64v(y),f64v(z));art.Vec v=art.v(f64v(vx),f64v(vy),f64v(vz));
    art.Vec endpoint=art.add(from,art.mul(v,dt));
    if(outside(from,endpoint)||station.solar_count==0){none(dt)}
    else{swept(0,art.facing(f64v(yaw),f64v(pitch)),from,v,dt,none(dt))}
};
bool(i32,art.Axes,art.Vec,art.Vec,f64) orientation_parts=fn(i,body,from,actor,padding){
    if(i==station.solar_count*5){true}else{
        station.Part p=station.at(station.solar_member(i));
        f64 ha=f64v(p.l)*0.5;
        art.Vec center=art.v(f64v(p.x),f64v(p.y),f64v(p.z)+ha);
        art.Vec half=art.v(f64v(p.u),f64v(p.v),ha);
        art.Vec offset=art.sub(from,center);
        bool broad=math.abs(offset.x)<=half.x+extent(body.forward.x,body.up.x,body.right.x,actor)+padding
            &&math.abs(offset.y)<=half.y+extent(body.forward.y,body.up.y,body.right.y,actor)+padding
            &&math.abs(offset.z)<=half.z+extent(body.forward.z,body.up.z,body.right.z,actor)+padding;
        Sweep start={.possible=true;.enter=-100000.0;.leave=0.0;.normal=art.v(0.0,0.0,0.0);};
        bool overlaps=if(broad){
            Sweep test=intervals(0,body,offset,art.v(0.0,0.0,0.0),actor,half,0.0,padding,start);test.possible
        }else{false};
        !overlaps&&orientation_parts(i+1,body,from,actor,padding)
    }
};
bool(i32,art.Axes,art.Vec,f64) orientation_probes=fn(i,body,origin,angle){
    if(i==10){true}else{
        Probe p=register(i);
        f64 bound=(art.length(p.local)+art.length(p.half))*angle;
        orientation_parts(0,body,art.add(origin,rotate(body,p.local)),p.half,bound)
            &&orientation_probes(i+1,body,origin,angle)
    }
};
bool(art.Vec,f64,f64,f64,f64,i32) rotation_clear=fn(origin,byaw,bpitch,dyaw,dpitch,depth){
    f64 mid_yaw=byaw+dyaw*0.5;f64 mid_pitch=bpitch+dpitch*0.5;
    f64 bound=(math.abs(dyaw)+math.abs(dpitch))*0.5;
    if(orientation_probes(0,art.facing(mid_yaw,mid_pitch),origin,bound)){true}
    else{depth>0&&rotation_clear(origin,byaw,bpitch,dyaw*0.5,dpitch*0.5,depth-1)
        &&rotation_clear(origin,mid_yaw,mid_pitch,dyaw*0.5,dpitch*0.5,depth-1)}
};
bool(f32,f32,f32,f32,f32,f32,f32) turn_clear=fn(x,y,z,yaw,pitch,dyaw,dpitch){
    art.Vec origin=art.v(f64v(x),f64v(y),f64v(z));
    if((dyaw==0.0&&dpitch==0.0)||outside(origin,origin)||station.solar_count==0){true}
    else{rotation_clear(origin,f64v(yaw),f64v(pitch),f64v(dyaw),f64v(dpitch),4)}
};
%%end
