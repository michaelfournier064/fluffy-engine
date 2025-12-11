shader_type canvas_item;

// Water animation parameters
uniform float wave_speed : hint_range(0.1, 2.0) = 0.5;
uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.05;
uniform float wave_frequency : hint_range(1.0, 10.0) = 3.0;
uniform vec4 water_color : source_color = vec4(0.15, 0.35, 0.65, 0.75);
uniform vec4 wave_color : source_color = vec4(0.25, 0.5, 0.85, 0.75);
uniform vec4 sparkle_color : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform float sparkle_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float sparkle_speed : hint_range(0.1, 5.0) = 2.0;

// Random function for sparkles
float random(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	// Create wave pattern based on position and time
	float wave1 = sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
	float wave2 = cos(UV.y * wave_frequency * 0.7 + TIME * wave_speed * 0.8) * wave_amplitude;
	float wave3 = sin((UV.x + UV.y) * wave_frequency * 0.5 + TIME * wave_speed * 1.2) * wave_amplitude;

	// Combine waves
	float wave = (wave1 + wave2 + wave3) * 0.5 + 0.5;

	// Mix colors based on wave pattern
	vec4 final_color = mix(water_color, wave_color, wave);

	// Enhanced shimmer effect
	float shimmer = sin(UV.x * 20.0 + TIME * 2.0) * cos(UV.y * 20.0 + TIME * 1.5) * 0.15;
	final_color.rgb += shimmer;

	// Add sparkles - multiple layers for depth
	vec2 sparkle_uv1 = UV * 30.0;
	vec2 sparkle_uv2 = UV * 45.0;
	vec2 sparkle_uv3 = UV * 60.0;

	// Animate sparkle positions
	sparkle_uv1 += TIME * sparkle_speed * 0.1;
	sparkle_uv2 += TIME * sparkle_speed * 0.15;
	sparkle_uv3 += TIME * sparkle_speed * 0.2;

	// Create sparkle patterns
	float sparkle1 = random(floor(sparkle_uv1));
	float sparkle2 = random(floor(sparkle_uv2));
	float sparkle3 = random(floor(sparkle_uv3));

	// Make sparkles twinkle with sine wave
	float twinkle1 = sin(TIME * 3.0 + sparkle1 * 6.28) * 0.5 + 0.5;
	float twinkle2 = sin(TIME * 4.0 + sparkle2 * 6.28) * 0.5 + 0.5;
	float twinkle3 = sin(TIME * 5.0 + sparkle3 * 6.28) * 0.5 + 0.5;

	// Combine sparkles with threshold to make them appear as bright points
	float sparkle = 0.0;
	if (sparkle1 > 0.95) sparkle += twinkle1 * 0.4;
	if (sparkle2 > 0.97) sparkle += twinkle2 * 0.5;
	if (sparkle3 > 0.98) sparkle += twinkle3 * 0.6;

	// Add sparkles to final color
	final_color.rgb += sparkle_color.rgb * sparkle * sparkle_intensity;

	// Add subtle color variation for depth
	float depth = sin(UV.y * 5.0 + TIME * 0.3) * 0.05;
	final_color.rgb += depth;

	COLOR = final_color;
}
