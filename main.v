module main

import sokol.sapp
import sokol.gfx
import gg

import time

#flag -I .
#include "march.h"

// defined inside sokol header
fn C.march_shader_desc(gfx.Backend) &gfx.ShaderDesc

struct Vertex_t {
	// Position
	x f32
	y f32
	z f32
	// Uv
	u f32
	v f32
} // vertex layout, used in pipeline

fn main() {
	mut app := &App{
		width: 800
		height: 400
		pass_action: gfx.create_clear_pass(0.0, 0.0, 0.0, 1.0) // This will create a black color as a default pass (window background color)
	}
	app.ticks = time.ticks()
	app.run()
}

struct App {
	pass_action gfx.PassAction
mut:
	width           int
	height          int
	shader_pipeline gfx.Pipeline
	bind            gfx.Bindings
	ticks           i64
}

fn (mut a App) run() {
	title := 'V Simple Shader Example'
	desc := sapp.Desc{
		width: a.width
		height: a.height
		user_data: a
		init_userdata_cb: init
		frame_userdata_cb: frame
		window_title: title.str
		html5_canvas_name: title.str
		cleanup_userdata_cb: cleanup
//		sample_count: 4 // MSAA x4
	}
	sapp.run(&desc)
}

fn init(user_data voidptr) {
	mut app := &App(user_data)
	mut desc := sapp.create_desc()

	gfx.setup(&desc)

	vertices := [
		Vertex_t{  3.0,  -1.0, 0.5, 2.0, 0.0},
		Vertex_t{ -1.0,   3.0, 0.5, 0.0, 2.0},
		Vertex_t{ -1.0,  -1.0, 0.5, 0.0, 0.0},
	] // fullscreen triangle (not quad), with correct UVs

	// create vertex buffer
	mut vertex_buffer_desc := gfx.BufferDesc{
		label: c'triangle-vertices'
	}
	unsafe { vmemset(&vertex_buffer_desc, 0, int(sizeof(vertex_buffer_desc))) }
	vertex_buffer_desc.size = usize(vertices.len * int(sizeof(Vertex_t)))
	vertex_buffer_desc.data = gfx.Range{
		ptr: vertices.data
		size: vertex_buffer_desc.size
	}
	app.bind.vertex_buffers[0] = gfx.make_buffer(&vertex_buffer_desc)

	// create shader from the code generated from the sokol glsl compiler
	shader := gfx.make_shader(C.march_shader_desc(gfx.query_backend()))

	// create a render pipeline
	mut pipeline_desc := gfx.PipelineDesc{}
	unsafe { vmemset(&pipeline_desc, 0, int(sizeof(pipeline_desc))) }

	// the shader and its inputs
	pipeline_desc.shader = shader
	pipeline_desc.layout.attrs[C.ATTR_vs_position].format  = .float3   // x,y,z as f32
	pipeline_desc.layout.attrs[C.ATTR_vs_texcoord0].format = .float2  // u,v as f32
	pipeline_desc.label = c'triangle-pipeline'

	app.shader_pipeline = gfx.make_pipeline(&pipeline_desc)
}

fn cleanup(user_data voidptr) {
	gfx.shutdown()
}

fn frame(user_data voidptr) {
	mut app := &App(user_data)

	gfx.begin_default_pass(&app.pass_action, sapp.width(), sapp.height())

	gfx.apply_pipeline(app.shader_pipeline)
	gfx.apply_bindings(&app.bind)

	time_ticks := f32(time.ticks() - app.ticks) / 1000

	ws := gg.window_size_real_pixels()
	ratio := f32(ws.width ) / ws.height
	// mut ratiox := f32(0)
	// mut ratioy := f32(0)
	// if ws.width > ws.height {ratiox = ratio ratioy = 1} else {ratiox = ratio ratioy = 1}
	mut tmp_fs_params := [
		f32(ws.width),
		ws.height * ratio, // x,y resolution to pass to FS
		ratio,
		time_ticks,
	]! // for padding, check SOKOL_SHDC_ALIGN

	fs_uniforms_range := gfx.Range{
		ptr: unsafe { &tmp_fs_params }
		size: usize(sizeof(tmp_fs_params))
	}
	gfx.apply_uniforms(.fs, C.SLOT_fs_params, &fs_uniforms_range)

	gfx.draw(0, 3, 1)

	gfx.end_pass()
	gfx.commit()
}
