%%start
struct copy Runway {
	f32 x;
	f32 z;
	f32 width;
	f32 length;
}

struct copy Course {
	Runway home;
	Runway supply;
	Runway finish;
}
%%end
