%%start
layout = namespace flight "maps/layout.w";

layout.Runway home = { .x = -111.0; .z = -199.0; .width = 36.0; .length = 67.0; };
layout.Runway supply = { .x = -111.0; .z = -71.0; .width = 36.0; .length = 109.0; };
layout.Runway finish = { .x = 125.0; .z = 290.0; .width = 41.0; .length = 124.0; };

layout.Course() course_layout = fn {
	layout.Course selected = { .home = home; .supply = supply; .finish = finish; };
	selected
};
%%end
