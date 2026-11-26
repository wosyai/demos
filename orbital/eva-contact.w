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
Hit(station.Part,art.Axes,art.Vec,art.Vec,art.Vec,art.Vec,f64) solid=fn(p,body,from,velocity,half,actor,dt){
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
i32(i32) count=fn(family){
    if(family==1){station.solar_count*5}else{
        if(family==2){if(station.radiator_first>=0){station.radiator_count}else{0}}else{station.catwalk_count}
    }
};
station.Part(i32,i32) member_part=fn(family,i){
    if(family==1){station.at(station.solar_member(i))}else{
        if(family==2){station.radiator_collision(i)}else{station.catwalk_collision(i)}
    }
};
Hit(i32,i32,art.Axes,art.Vec,art.Vec,art.Vec,art.Vec,f64,Hit) parts=fn(family,i,body,from,v,half,actor,dt,best){
    if(i==count(family)){best}else{
        Hit found=solid(member_part(family,i),body,from,v,half,actor,dt);
        Hit earlier=if(found.active&&(!best.active||found.time<best.time)){found}else{best};
        parts(family,i+1,body,from,v,half,actor,dt,earlier)
    }
};
Hit(i32,i32,art.Axes,art.Vec,art.Vec,f64,Hit) swept=fn(family,id,axes,origin,v,dt,best){
    if(id==10){best}else{
        Probe p=register(id);art.Vec from=art.add(origin,rotate(axes,p.local));
        art.Vec half=art.v(extent(axes.forward.x,axes.up.x,axes.right.x,p.half)+0.003,
            extent(axes.forward.y,axes.up.y,axes.right.y,p.half)+0.003,
            extent(axes.forward.z,axes.up.z,axes.right.z,p.half)+0.003);
        Hit found=parts(family,0,axes,from,v,half,p.half,dt,best);
        swept(family,id+1,axes,origin,v,dt,found)
    }
};
f64(f64,f64,f64) polygon_radius=fn(y,z,arc){
    f64 radial=math.norm(y,z,0.0);
    f64 direction=math.atan2(y,z);
    if(direction<0.0){direction=direction+6.283185307179586;};
    f64 vertex=core.sint_to_float<f64>(core.float_to_sint_trunc<i32>(direction/arc+0.5))*arc;
    radial*math.cos(direction-vertex)
};
art.Vec(f64) radial_axis=fn(angle){art.v(0.0,math.sin(angle),math.cos(angle))};
art.Vec(i32,i32,art.Axes,f64) rail_axis=fn(i,sectors,body,arc){
    if(i==0){unit_axis(0)}
    else{if(i<4){body_axis(body,i-1)}
    else{if(i<7){art.cross(unit_axis(0),body_axis(body,i-4))}
    else{
        i32 edge=i-7;
        if(edge<sectors){radial_axis((core.sint_to_float<f64>(edge)+0.5)*arc)}
        else{
            i32 pair=edge-sectors;
            f64 angle=(core.sint_to_float<f64>(pair/3)+0.5)*arc+1.5707963267948966;
            art.cross(radial_axis(angle),body_axis(body,pair%3))
        }
    }}}
};
Sweep(i32,i32,art.Axes,art.Vec,art.Vec,art.Vec,f64,f64,f64,f64,Sweep) rail_intervals=fn(i,sectors,body,offset,velocity,actor,half_run,rad,arc,dt,best){
    if(i==7+4*sectors||!best.possible){best}else{
        art.Vec raw=rail_axis(i,sectors,body,arc);
        if(art.dot(raw,raw)<0.000000000001){
            rail_intervals(i+1,sectors,body,offset,velocity,actor,half_run,rad,arc,dt,best)
        }else{
            art.Vec axis0=art.normalized(raw);
            art.Vec in_body=art.v(art.dot(axis0,body.forward),art.dot(axis0,body.up),art.dot(axis0,body.right));
            f64 span0=math.abs(axis0.x)*half_run+rad*polygon_radius(axis0.y,axis0.z,arc)+support_radius(in_body,actor)+0.003;
            Interval span=slab(art.dot(offset,axis0),art.dot(velocity,axis0),-span0,span0,dt);
            f64 last=hi(best.enter,span.enter);f64 first=lo(best.leave,span.leave);
            Sweep next={.possible=span.possible&&last<=first&&last<=dt&&first>=0.0;
                .enter=last;.leave=first;.normal=if(span.enter>best.enter){art.mul(axis0,span.sign)}else{best.normal};};
            rail_intervals(i+1,sectors,body,offset,velocity,actor,half_run,rad,arc,dt,next)
        }
    }
};
Hit(i32,art.Axes,art.Vec,art.Vec,art.Vec,art.Vec,f64) shaft_hit=fn(id,body,origin,velocity,half,actor,dt){
    station.RailShaft shaft=station.rail_shaft(id);
    f64 lo_x=f64v(shaft.min_x);f64 hi_x=f64v(shaft.max_x);
    f64 yy=f64v(station.rail_y);f64 zz=f64v(station.rail_depth(station.rail_leg(id)));
    f64 rad=f64v(station.rail_radius);
    Interval a=slab(origin.x,velocity.x,lo_x-half.x,hi_x+half.x,dt);
    Interval b=slab(origin.y,velocity.y,yy-rad-half.y,yy+rad+half.y,dt);
    Interval c=slab(origin.z,velocity.z,zz-rad-half.z,zz+rad+half.z,dt);
    f64 enter=hi(a.enter,hi(b.enter,c.enter));f64 leave=lo(a.leave,lo(b.leave,c.leave));
    if(a.possible&&b.possible&&c.possible&&enter<=dt&&leave>=0.0&&enter<=leave){
        art.Vec center=art.v((lo_x+hi_x)*0.5,yy,zz);
        Sweep start={.possible=true;.enter=-100000.0;.leave=dt;.normal=art.v(0.0,0.0,0.0);};
        f64 arc=6.283185307179586/core.sint_to_float<f64>(shaft.sides);
        Sweep exact=rail_intervals(0,shaft.sides/2,body,art.sub(origin,center),velocity,actor,(hi_x-lo_x)*0.5,rad,arc,dt,start);
        if(exact.possible&&exact.enter>=-0.00002&&art.dot(exact.normal,velocity)<0.0){
            Hit found={.active=true;.time=hi(0.0,exact.enter);.normal=exact.normal;};found
        }else{none(dt)}
    }else{none(dt)}
};
Hit(i32,i32,i32,art.Axes,art.Vec,art.Vec,art.Vec,art.Vec,f64,Hit) rail_parts=fn(i,probe_id,releasing,body,from,v,half,actor,dt,best){
    if(i==10){best}else{
        bool hand_at_same_bar=probe_id==10&&i<2&&i==releasing;
        Hit found=if(i<4){if(hand_at_same_bar){none(dt)}else{shaft_hit(i,body,from,v,half,actor,dt)}}
            else{solid(station.rail_foot_collision(i-4),body,from,v,half,actor,dt)};
        Hit chosen=if(found.active&&(!best.active||found.time<best.time)){found}else{best};
        rail_parts(i+1,probe_id,releasing,body,from,v,half,actor,dt,chosen)
    }
};
Probe(i32) rail_probe=fn(id){
    if(id==7){probe(0.162,-0.253,-0.280,0.223,0.218,0.162)}
    else{if(id==10){probe(0.527,-0.253,-0.280,0.142,0.218,0.162)}
    else{register(id)}}
};
Hit(i32,i32,art.Axes,art.Vec,art.Vec,f64,Hit) swept_rails=fn(id,releasing,axes,origin,v,dt,best){
    if(id==11){best}else{
        Probe p=rail_probe(id);art.Vec from=art.add(origin,rotate(axes,p.local));
        art.Vec half=art.v(extent(axes.forward.x,axes.up.x,axes.right.x,p.half)+0.003,
            extent(axes.forward.y,axes.up.y,axes.right.y,p.half)+0.003,
            extent(axes.forward.z,axes.up.z,axes.right.z,p.half)+0.003);
        Hit found=rail_parts(0,id,releasing,axes,from,v,half,p.half,dt,best);
        swept_rails(id+1,releasing,axes,origin,v,dt,found)
    }
};
bool(art.Vec,art.Vec) outside_rails=fn(origin,endpoint){
    hi(origin.y,endpoint.y)< -3.20||lo(origin.y,endpoint.y)>1.60||hi(origin.x,endpoint.x)< -3.70
        ||lo(origin.x,endpoint.x)>3.25||hi(origin.z,endpoint.z)< -7.0||lo(origin.z,endpoint.z)>0.60
};
bool(art.Vec,art.Vec) outside_solar=fn(origin,endpoint){
    hi(origin.y,endpoint.y)<0.78||lo(origin.y,endpoint.y)>4.90||hi(origin.x,endpoint.x)< -22.0
        ||lo(origin.x,endpoint.x)>10.0||hi(origin.z,endpoint.z)< -22.0||lo(origin.z,endpoint.z)>0.0
};
bool(art.Vec,art.Vec) outside_catwalk=fn(origin,endpoint){
    hi(origin.y,endpoint.y)< -3.20||lo(origin.y,endpoint.y)>3.85||hi(origin.x,endpoint.x)< -3.70
        ||lo(origin.x,endpoint.x)>1.50||hi(origin.z,endpoint.z)< -5.45||lo(origin.z,endpoint.z)>0.0
};
bool(art.Vec,art.Vec) outside_radiator=fn(origin,endpoint){
    hi(origin.y,endpoint.y)< -0.86||lo(origin.y,endpoint.y)>3.26||hi(origin.x,endpoint.x)< -12.32
        ||lo(origin.x,endpoint.x)> -4.89||hi(origin.z,endpoint.z)< -7.40||lo(origin.z,endpoint.z)>2.04
};
struct copy Support { f64 low; f64 high; }
art.Vec(station.Part,i32) aft_vertex=fn(p,i){
    station.RingPoint q=station.aft_ring_at(i);
    art.v(f64v(q.u*p.u),f64v(q.v*p.v),0.0)
};
Support(station.Part,art.Vec,i32,Support) aft_support=fn(p,a,i,range){
    if(i==16){range}else{
        f64 q=art.dot(aft_vertex(p,i),a);
        Support next={.low=lo(q,range.low);.high=hi(q,range.high);};
        aft_support(p,a,i+1,next)
    }
};
art.Vec(station.Part,i32) aft_edge=fn(p,i){
    if(i==16){art.v(0.0,0.0,1.0)}else{art.sub(aft_vertex(p,i+1),aft_vertex(p,i))}
};
Sweep(station.Part,art.Axes,art.Vec,art.Vec,art.Vec,f64,f64,i32,Sweep) aft_axes=fn(p,body,o,v,half,dt,pad,i,best){
    if(i==71||!best.possible){best}else{
        art.Vec raw=if(i<3){body_axis(body,i)}else{if(i==3){art.v(0.0,0.0,1.0)}else{if(i<20){
            art.Vec edge=aft_edge(p,i-4);art.v(edge.y,0.0-edge.x,0.0)
        }else{art.cross(body_axis(body,(i-20)/17),aft_edge(p,(i-20)%17))}}};
        if(art.dot(raw,raw)<0.000000000001){aft_axes(p,body,o,v,half,dt,pad,i+1,best)}
        else{
            art.Vec axis=art.normalized(raw);
            Support initial={.low=100.0;.high=-100.0;};
            Support ring=aft_support(p,axis,0,initial);
            art.Vec local=art.v(art.dot(axis,body.forward),art.dot(axis,body.up),art.dot(axis,body.right));
            f64 width=support_radius(local,half)+math.abs(axis.z)*f64v(p.l)*0.5+pad;
            Interval span=slab(art.dot(o,axis),art.dot(v,axis),ring.low-width,ring.high+width,dt);
            f64 latest=hi(best.enter,span.enter);f64 earliest=lo(best.leave,span.leave);
            Sweep next={.possible=span.possible&&latest<=earliest&&latest<=dt&&earliest>=0.0;
                .enter=latest;.leave=earliest;.normal=if(span.enter>best.enter){art.mul(axis,span.sign)}else{best.normal};};
            aft_axes(p,body,o,v,half,dt,pad,i+1,next)
        }
    }
};
Sweep(station.Part,art.Axes,art.Vec,art.Vec,art.Vec,f64,f64) aft_probe=fn(p,body,from,v,half,dt,pad){
    f64 rz=f64v(p.l)*0.5;
    art.Vec o=art.sub(from,art.v(f64v(p.x),f64v(p.y),f64v(p.z)+rz));
    f64 x=f64v(p.u)*1.02+extent(body.forward.x,body.up.x,body.right.x,half)+pad;
    f64 y=f64v(p.v)*1.02+extent(body.forward.y,body.up.y,body.right.y,half)+pad;
    f64 z=rz+extent(body.forward.z,body.up.z,body.right.z,half)+pad;
    Interval ix=slab(o.x,v.x,0.0-x,x,dt);Interval iy=slab(o.y,v.y,0.0-y,y,dt);Interval iz=slab(o.z,v.z,0.0-z,z,dt);
    f64 enter=hi(ix.enter,hi(iy.enter,iz.enter));f64 leave=lo(ix.leave,lo(iy.leave,iz.leave));
    Sweep start={.possible=ix.possible&&iy.possible&&iz.possible&&enter<=dt&&leave>=0.0&&enter<=leave;
        .enter=-100000.0;.leave=dt;.normal=art.v(0.0,0.0,0.0);};
    aft_axes(p,body,o,v,half,dt,pad,0,start)
};
bool(station.Part,art.Vec,art.Vec) outside_aft=fn(p,a,b){
    f64 x=f64v(p.x);f64 y=f64v(p.y);f64 z=f64v(p.z);
    f64 u=f64v(p.u)*1.02+2.0;f64 v=f64v(p.v)*1.02+2.0;
    hi(a.x,b.x)<x-u||lo(a.x,b.x)>x+u||hi(a.y,b.y)<y-v||lo(a.y,b.y)>y+v
        ||hi(a.z,b.z)<z-2.0||lo(a.z,b.z)>z+f64v(p.l)+2.0
};
Hit(station.Part,i32,art.Axes,art.Vec,art.Vec,f64,Hit) sweep_aft=fn(p,i,body,origin,v,dt,best){
    if(i==10){best}else{
        Probe q=register(i);
        Sweep test=aft_probe(p,body,art.add(origin,rotate(body,q.local)),v,q.half,best.time,0.003);
        bool hit=test.possible&&test.enter>=-0.00002&&art.dot(test.normal,v)<0.0;
        Hit found={.active=true;.time=hi(0.0,test.enter);.normal=test.normal;};
        sweep_aft(p,i+1,body,origin,v,dt,if(hit&&(!best.active||found.time<best.time)){found}else{best})
    }
};
bool(station.Part,i32,art.Axes,art.Vec,f64) aft_pose_clear=fn(p,i,body,origin,angle){
    if(i==10){true}else{
        Probe q=register(i);
        f64 bound=(art.length(q.local)+art.length(q.half))*angle;
        Sweep test=aft_probe(p,body,art.add(origin,rotate(body,q.local)),art.v(0.0,0.0,0.0),q.half,0.0,bound);
        !test.possible&&aft_pose_clear(p,i+1,body,origin,angle)
    }
};
bool(station.Part,art.Vec,f64,f64,f64,f64,i32) aft_turn=fn(p,origin,yaw,pitch,dy,dp,depth){
    f64 my=yaw+dy*0.5;f64 mp=pitch+dp*0.5;
    if(aft_pose_clear(p,0,art.facing(my,mp),origin,(math.abs(dy)+math.abs(dp))*0.5)){true}
    else{depth>0&&aft_turn(p,origin,yaw,pitch,dy*0.5,dp*0.5,depth-1)
        &&aft_turn(p,origin,my,mp,dy*0.5,dp*0.5,depth-1)}
};
Hit(f32,f32,f32,f32,f32,f32,f32,f32,f32,i32) station_sweep=fn(x,y,z,vx,vy,vz,yaw,pitch,step,releasing){
    f64 dt=f64v(step);art.Vec from=art.v(f64v(x),f64v(y),f64v(z));art.Vec v=art.v(f64v(vx),f64v(vy),f64v(vz));
    art.Vec endpoint=art.add(from,art.mul(v,dt));
    bool solar_in=count(1)>0&&!outside_solar(from,endpoint);
    bool local_in=!outside_catwalk(from,endpoint);
    bool rail_in=!outside_rails(from,endpoint);
    bool radiator_in=count(2)>0&&!outside_radiator(from,endpoint);
    station.Part aft=if(station.aft_body_id<0){station.empty}else{station.aft_body()};
    bool aft_in=station.aft_body_id>=0&&!outside_aft(aft,from,endpoint);
    if(!solar_in&&!local_in&&!rail_in&&!radiator_in&&!aft_in){none(dt)}
    else{
        art.Axes body=art.facing(f64v(yaw),f64v(pitch));
        Hit wing_hit=if(solar_in){swept(1,0,body,from,v,dt,none(dt))}else{none(dt)};
        Hit box_hit=if(local_in){swept(0,0,body,from,v,dt,wing_hit)}else{wing_hit};
        Hit trays=if(radiator_in){swept(2,0,body,from,v,dt,box_hit)}else{box_hit};
        Hit rails=if(rail_in){swept_rails(0,releasing,body,from,v,dt,trays)}else{trays};
        if(aft_in){sweep_aft(aft,0,body,from,v,dt,rails)}else{rails}
    }
};
bool(i32,i32,art.Axes,art.Vec,art.Vec,f64) orientation_parts=fn(family,i,body,from,actor,padding){
    if(i==count(family)){true}else{
        station.Part p=member_part(family,i);
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
        !overlaps&&orientation_parts(family,i+1,body,from,actor,padding)
    }
};
bool(i32,i32,art.Axes,art.Vec,f64) orientation_probes=fn(family,i,body,origin,angle){
    if(i==10){true}else{
        Probe p=register(i);
        f64 bound=(art.length(p.local)+art.length(p.half))*angle;
        orientation_parts(family,0,body,art.add(origin,rotate(body,p.local)),p.half,bound)
            &&orientation_probes(family,i+1,body,origin,angle)
    }
};
bool(i32,art.Vec,f64,f64,f64,f64,i32) rotation_clear=fn(family,origin,byaw,bpitch,dyaw,dpitch,depth){
    f64 mid_yaw=byaw+dyaw*0.5;f64 mid_pitch=bpitch+dpitch*0.5;
    f64 bound=(math.abs(dyaw)+math.abs(dpitch))*0.5;
    if(orientation_probes(family,0,art.facing(mid_yaw,mid_pitch),origin,bound)){true}
    else{depth>0&&rotation_clear(family,origin,byaw,bpitch,dyaw*0.5,dpitch*0.5,depth-1)
        &&rotation_clear(family,origin,mid_yaw,mid_pitch,dyaw*0.5,dpitch*0.5,depth-1)}
};
bool(f32,f32,f32,f32,f32,f32,f32) turn_clear=fn(x,y,z,yaw,pitch,dyaw,dpitch){
    art.Vec origin=art.v(f64v(x),f64v(y),f64v(z));
    if(dyaw==0.0&&dpitch==0.0){true}else{
        bool wing_safe=if(count(1)==0||outside_solar(origin,origin)){true}
            else{rotation_clear(1,origin,f64v(yaw),f64v(pitch),f64v(dyaw),f64v(dpitch),4)};
        bool trays_safe=if(count(2)==0||outside_radiator(origin,origin)){true}
            else{rotation_clear(2,origin,f64v(yaw),f64v(pitch),f64v(dyaw),f64v(dpitch),4)};
        station.Part aft=if(station.aft_body_id<0){station.empty}else{station.aft_body()};
        bool aft_safe=if(station.aft_body_id<0||outside_aft(aft,origin,origin)){true}
            else{aft_turn(aft,origin,f64v(yaw),f64v(pitch),f64v(dyaw),f64v(dpitch),4)};
        wing_safe&&trays_safe&&aft_safe&&(if(outside_catwalk(origin,origin)){true}
            else{rotation_clear(0,origin,f64v(yaw),f64v(pitch),f64v(dyaw),f64v(dpitch),4)})
    }
};
%%end
