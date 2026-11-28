%%start
math = namespace orbital "presentation.w";
bridge = extern wasm "orbital" { unsafe unit(*?u8,i32) avatar_rig; };
struct copy Vec { f64 x; f64 y; f64 z; }
struct copy Axes { Vec forward; Vec up; Vec right; }
struct copy Arm { Vec elbow; Vec wrist; f64 error; }
struct copy Grip { bool active; Vec center; f64 radius; f64 theta; Vec wrist; Vec inward; f64 progress; }
Vec(f64,f64,f64) v=fn(x,y,z){Vec value={.x=x;.y=y;.z=z;};value};
Vec(Vec,Vec) add=fn(a,b){v(a.x+b.x,a.y+b.y,a.z+b.z)};
Vec(Vec,Vec) sub=fn(a,b){v(a.x-b.x,a.y-b.y,a.z-b.z)};
Vec(Vec,f64) mul=fn(a,k){v(a.x*k,a.y*k,a.z*k)};
f64(Vec,Vec) dot=fn(a,b){a.x*b.x+a.y*b.y+a.z*b.z};
Vec(Vec,Vec) cross=fn(a,b){v(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)};
f64(Vec) length=fn(a){math.norm(a.x,a.y,a.z)};
Vec(Vec) normalized=fn(a){f64 n=length(a);mul(a,if(n==0.0){1.0}else{1.0/n})};
Vec(Vec,Vec,f64) mix=fn(a,b,t){add(a,mul(sub(b,a),t))};
f64(f64) smooth=fn(x){f64 t=math.clamp(x,0.0,1.0);t*t*(3.0-2.0*t)};
Axes(f64,f64) facing=fn(yaw,pitch){
    f64 sy=math.sin(yaw);f64 cy=math.cos(yaw);f64 sp=math.sin(pitch);f64 cp=math.cos(pitch);
    Axes value={.forward=v(sy*cp,sp,-cy*cp);.up=v(-sy*sp,cp,cy*sp);.right=v(cy,0.0,sy);};value
};
Vec(f64,f64,f64,f64) apollo_eye_delta=fn(byaw,bpitch,hyaw,hpitch){
    Axes torso=facing(byaw,bpitch);Axes gaze=facing(hyaw,hpitch);
    Vec hinge=add(mul(torso.forward,0.115),mul(torso.up,-0.097));
    Vec rest=add(mul(torso.forward,0.090),mul(torso.up,0.100));
    Vec bend=cross(torso.forward,gaze.forward);
    Vec first=cross(bend,rest);
    f64 denom=1.0+dot(torso.forward,gaze.forward);
    Vec optical_result=if(denom<0.000001){hinge}else{add(hinge,add(rest,add(first,mul(cross(bend,first),1.0/denom))))};optical_result
};
Vec(Vec,f64,f64,f64) radial=fn(center,x,r,theta){add(center,v(x,r*math.cos(theta),r*math.sin(theta)))};
Grip(Vec,Vec,f64,f64,bool,bool) grip=fn(eye,anchor,weight,stage,valid,apollo_first_rail){
    bool active=valid&&weight>=0.004;
    if(active){
        Vec rest=sub(eye,v(0.23,0.40,0.80));
        Vec center=add(rest,mul(sub(anchor,rest),1.0/weight));
        f64 radius=if(stage>=5.0){0.082}else{0.087};f64 theta=if(stage>=5.0){0.61}else{0.365};
        Vec shaft_inward=v(0.0,math.sin(theta),-math.cos(theta));
        f64 glove_standoff=if(apollo_first_rail){0.051}else{0.020};
        Vec knuckle=radial(center,0.023,radius+glove_standoff,theta);
        f64 palm_depth=if(apollo_first_rail){0.045}else{0.066};
        Vec ordinary_wrist=sub(knuckle,mul(shaft_inward,palm_depth));
        Vec fitted_wrist=if(stage>=5.0){
            Vec radial_wrist=sub(ordinary_wrist,center);
            Vec outside=normalized(v(0.0,radial_wrist.y,radial_wrist.z));
            add(ordinary_wrist,mul(outside,0.020))
        }else{ordinary_wrist};
        Vec fitted_inward=if(stage>=5.0){
            f64 hat_roll_sin=math.sin(0.18);f64 hat_roll_cos=math.cos(0.18);
            v(0.0,shaft_inward.y*hat_roll_cos-shaft_inward.z*hat_roll_sin,
                shaft_inward.y*hat_roll_sin+shaft_inward.z*hat_roll_cos)
        }else{shaft_inward};
        Grip value={.active=true;.center=center;.radius=radius;.theta=theta;.wrist=fitted_wrist;.inward=fitted_inward;.progress=smooth((weight-0.69)/0.31);};value
    }else{
        Grip value={.active=false;.center=v(0.0,0.0,0.0);.radius=0.0;.theta=0.0;.wrist=v(0.0,0.0,0.0);.inward=v(0.0,0.0,0.0);.progress=0.0;};value
    }
};
bool(Vec,Vec,f64,f64) hatch_in_reach=fn(eye,shaft,heading,elevation){
    Axes body=facing(heading,elevation);
    Vec shoulder=add(eye,add(mul(body.forward,0.085),add(mul(body.up,-0.167),mul(body.right,-0.255))));
    Grip hold=grip(eye,shaft,1.0,5.0,true,false);
    Vec delta=sub(hold.wrist,shoulder);
    dot(delta,delta)<=0.250
};
Vec(Vec,Grip,f64,bool) approach=fn(rest,contact,weight,releasing){
    if(!contact.active){rest}else{
        Vec last=sub(contact.wrist,contact.center);Vec start=sub(rest,contact.center);
        f64 a=math.atan2(start.z,start.y);f64 b=math.atan2(last.z,last.y);
        f64 r=math.norm(0.0,last.y,last.z);f64 h=r+0.084;
        if(weight>=0.69){radial(contact.center,last.x,r+(h-r)*(1.0-contact.progress),b)}
        else{
            f64 q=smooth(weight/0.69);f64 angle=a+math.wrap(b-a)*q;
            f64 r0=math.norm(0.0,start.y,start.z);
            f64 rr=r0+(h-r0)*q+0.095*math.sin(3.141592653589793*q)+(if(releasing){0.096}else{0.060})*smooth(weight/0.040)*(1.0-q);
            radial(contact.center,start.x+(last.x-start.x)*q,rr,angle)
        }
    }
};
struct copy Control { Vec stem; Vec handle; Vec right; Vec up; Vec depth; Vec offset; }
Vec(Vec,Vec,Vec,Vec) transform_basis=fn(right,up,depth,p){add(add(mul(right,p.x),mul(up,p.y)),mul(depth,p.z))};
Control(f64,f64,f64) control=fn(side,horizontal,vertical){
    f64 x=math.clamp(horizontal,-1.0,1.0);f64 y=math.clamp(vertical,-1.0,1.0);
    Vec axis=v(y,-x,0.0);f64 amount=length(axis);
    f64 angle=math.clamp(amount,0.0,1.0)*0.17;
    Vec q=mul(normalized(axis),math.sin(angle));f64 w=math.cos(angle);
    Vec right=v(1.0-2.0*q.y*q.y,2.0*q.x*q.y,-2.0*q.y*w);
    Vec up=v(2.0*q.x*q.y,1.0-2.0*q.x*q.x,2.0*q.x*w);
    Vec depth=v(2.0*q.y*w,-2.0*q.x*w,1.0-2.0*(q.x*q.x+q.y*q.y));
    Vec stem=v(side*0.285*0.90,-0.255+0.040,-0.425-0.095);
    Vec tip=v(side*0.285*0.90,-0.307+0.040,-0.50-0.095);
    Vec offset=sub(stem,transform_basis(right,up,depth,stem));
    Control value={.stem=stem;.handle=add(transform_basis(right,up,depth,tip),offset);.right=right;.up=up;.depth=depth;.offset=offset;};value
};
Arm(Vec,Vec,f64,f64,Vec) elbow=fn(shoulder,wrist,upper,fore,pole){
    Vec d=sub(wrist,shoulder);f64 requested=length(d);
    Vec dir=if(requested>0.00001){normalized(d)}else{v(0.0,0.0,-1.0)};
    f64 reach=math.clamp(requested,math.abs(upper-fore)+0.0005,upper+fore-0.0005);
    Vec normal=sub(pole,mul(dir,dot(pole,dir)));
    if(length(normal)<0.00001){
        Vec backup=if(math.abs(dir.y)<0.9){v(0.0,-1.0,0.0)}else{v(1.0,0.0,0.0)};
        normal=sub(backup,mul(dir,dot(backup,dir)));
    };
    f64 run=(upper*upper-fore*fore+reach*reach)/(2.0*reach);
    f64 rise=math.root_scaled(math.clamp(upper*upper-run*run,0.0,1.0e30),1.0);
    Arm value={.elbow=add(shoulder,add(mul(dir,run),mul(normalized(normal),rise)));.wrist=add(shoulder,mul(dir,reach));.error=math.abs(requested-reach);};value
};
f64[37] packet=[0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
unit(i32) send=fn(n){unsafe {bridge.avatar_rig(core.pointer_cast<*?u8>(&?packet[0]),n);};};
unit(u64,Vec) write_vec=fn(i,value){
    packet[i]=value.x;packet[i+1]=value.y;packet[i+2]=value.z;
};
unit(f64,f64,f64,f64,f64,f64,f64,f64,i32) publish_grip=fn(ex,ey,ez,ax,ay,az,weight,stage,valid){
    Grip contact=grip(v(ex,ey,ez),v(ax,ay,az),weight,stage,valid==1||valid==2,valid==2);
    packet[0]=if(contact.active){1.0}else{0.0};
    if(contact.active){
        write_vec(1,contact.center);packet[4]=contact.radius;packet[5]=contact.theta;
        write_vec(6,contact.wrist);write_vec(9,contact.inward);packet[12]=contact.progress;
        write_vec(13,cross(contact.inward,v(-1.0,0.0,0.0)));
    };
    send(16);
};
unit(f64,f64,f64,f64,f64,f64,f64,f64,f64,f64,f64,f64,i32) publish_approach=fn(rx,ry,rz,cx,cy,cz,wx,wy,wz,progress,weight,radius,releasing){
    Grip contact={.active=true;.center=v(cx,cy,cz);.radius=radius;.theta=0.0;.wrist=v(wx,wy,wz);.inward=v(0.0,0.0,0.0);.progress=progress;};
    write_vec(0,approach(v(rx,ry,rz),contact,weight,releasing==1));
    send(3);
};
unit(f64,f64,f64,f64) publish_facing=fn(body_yaw,body_pitch,head_yaw,head_pitch){
    Axes body=facing(body_yaw,body_pitch);Axes head=facing(head_yaw,head_pitch);
    write_vec(0,body.forward);write_vec(3,body.up);write_vec(6,body.right);
    write_vec(9,head.forward);write_vec(12,head.up);write_vec(15,head.right);
    send(18);
};
unit(u64,Control) write_control=fn(i,value){
    write_vec(i,value.stem);write_vec(i+3,value.handle);write_vec(i+6,value.right);
    write_vec(i+9,value.up);write_vec(i+12,value.depth);write_vec(i+15,value.offset);
};
f64[44] mmu_grasps=[
    -0.2887152623,-0.1758412891,-0.4841333545,-0.123451306,0.213545757,0.5308221924,0.8107933058,-0.5254493068,-0.3753374861,-0.0137239872,0.1343875776,0.2280236504,0.1021752705,0.416207134,0.4879735912,-0.527525945,0.3480901661,0.3336974065,-0.0168848743,-0.0127141235,-0.0072551153,0.2662460463,
    0.2863297166,-0.1589574046,-0.5100514334,-0.3117934128,-0.3365824157,-0.5727058045,0.6793417451,0.438570613,0.244220647,-0.2174077643,-0.2310878627,-0.1520094235,-0.1797134684,-0.4067223951,-0.3891582468,-0.0781442849,-0.0000153505,0.0,0.1307552871,0.0,0.0,-0.0284366747
];
unit() publish_mmu_grasps=fn{unsafe {bridge.avatar_rig(core.pointer_cast<*?u8>(&?mmu_grasps[0]),44);};};
unit(f64,f64,f64,f64,f64) publish_mmu=fn(lx,ly,rx,ry,mmu_reach){
    write_control(0,control(-1.0,lx,ly));write_control(18,control(1.0,rx,ry));
    f64 g=math.clamp(mmu_reach/0.22,0.0,1.0);
    packet[36]=1.0-g*g*(3.0-2.0*g);send(37);
};
unit(f64,f64,f64,f64,f64,f64,f64,f64,f64,f64,f64) publish_elbow=fn(sx,sy,sz,wx,wy,wz,upper,fore,px,py,pz){
    Arm arm=elbow(v(sx,sy,sz),v(wx,wy,wz),upper,fore,v(px,py,pz));
    write_vec(0,arm.elbow);write_vec(3,arm.wrist);packet[6]=arm.error;send(7);
};
unit(f64,f64,f64,f64,f64,f64,f64,f64,f64,f64) publish_training_wrist=fn(rx,ry,rz,ax,ay,az,ux,uy,uz,reach){
    f64 lift=0.075*smooth(reach/0.012)*(1.0-smooth((reach-0.15)/0.24));
    Vec rest=v(rx,ry,rz);Vec endpoint=v(ax,ay,az);
    write_vec(0,add(add(rest,mul(sub(endpoint,rest),reach)),mul(v(ux,uy,uz),lift)));
    send(3);
};
unit(f64,f64,i32,i32,i32,i32) publish_grasp_style=fn(reach,span_error,registered,left,phase,rail){
    f64 palm=math.clamp(reach/0.69,0.0,1.0);
    f64 curl=0.72+0.28*reach;
    f64 side=if(left==1){-1.0}else{1.0};
    packet[0]=if(reach>0.0){math.clamp((span_error+0.010)*1.48,0.0,0.18)}else{0.0};
    packet[1]=math.clamp(reach*2.1,0.0,1.0);
    packet[2]=if(registered==1){palm*palm*(3.0-2.0*palm)}else{reach};
    packet[3]=(0.18*side)*curl;
    packet[4]=(0.20*side)*curl;
    packet[5]=(0.12*side)*curl;
    packet[6]=(0.43*side)*curl;
    packet[7]=(0.38*side)*curl;
    bool first_hold=registered==1 && left==1 && phase==2 && rail==0;
    packet[8]=if(first_hold){-0.80}else{0.0};
    packet[9]=if(first_hold){0.16}else{0.0};
    packet[10]=if(first_hold){-0.04}else{0.0};
    packet[11]=if(first_hold){-0.40}else{0.0};
    packet[12]=if(first_hold){0.02}else{0.0};
    packet[13]=if(first_hold){-0.64}else{0.0};
    packet[14]=if(first_hold){-0.16}else{0.0};
    packet[15]=0.0;
    packet[16]=if(first_hold){-0.42}else{0.0};
    send(17);
};
%%end
