shader_type canvas_item;

// Water animation parameters
uniform float wave_speed : hint_range(0.1, 2.0) = 0.5;
uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.05;
uniform float wave_frequency : hint_range(1.0, 10.0) = 3.0;
uniform vec4 water_color : source_color = vec4(0.2, 0.4, 0.7, 0.7);
uniform vec4 wave_color : source_color = vec4(0.3, 0.5, 0.8, 0.7);

void fragment() {
	// Create wave pattern based on position and time
	float wave1 = sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
	float wave2 = cos(UV.y * wave_frequency * 0.7 + TIME * wave_speed * 0.8) * wave_amplitude;
	float wave3 = sin((UV.x + UV.y) * wave_frequency * 0.5 + TIME * wave_speed * 1.2) * wave_amplitude;

	// Combine waves
	float wave = (wave1 + wave2 + wave3) * 0.5 + 0.5;

	// Mix colors based on wave pattern
	vec4 final_color = mix(water_color, wave_color, wave);

	// Add slight shimmer effect
	float shimmer = sin(UV.x * 20.0 + TIME * 2.0) * cos(UV.y * 20.0 + TIME * 1.5) * 0.1;
	final_color.rgb += shimmer;

	COLOR = final_color;
}
