%%start
layout = namespace flight "maps/layout.w";

layout.Runway home = { .x = -15.0; .z = -74.0; .width = 29.0; .length = 67.0; };
layout.Runway supply = { .x = -15.0; .z = 68.0; .width = 29.0; .length = 109.0; };
layout.Runway finish = { .x = -15.0; .z = 331.0; .width = 25.0; .length = 74.0; };

layout.Course() course_layout = fn {
	layout.Course selected = { .home = home; .supply = supply; .finish = finish; };
	selected
};
%%end
