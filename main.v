module main

import sokol.sapp
import sokol.gfx
import gg
import gg.m4 { Mat4, Vec4 }

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

	cposition Vec4
	crotation Vec4
	cvelocity Vec4
	keys [6]bool
	// WASD Space Shift

	cfocal f32 = 1.5

	finter f32 = 0.0

	mouse_dx f32
	mouse_dy f32

	cmatrix Mat4 = m4.unit_m4()
}

fn (mut a App) run() {
	title := 'screen space triangle'
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

		event_userdata_cb: event
	}
	sapp.run(&desc)
}

fn event(ev &sapp.Event, mut app App) {
	sapp.lock_mouse(true)

	if ev.@type == .mouse_move {
		app.mouse_dx += ev.mouse_dx
		app.mouse_dy += ev.mouse_dy
		return
	}
	
	if ev.@type == .key_down {
		match ev.key_code {
			.w { app.keys[0] = true }
			.a { app.keys[1] = true }
			.s { app.keys[2] = true }
			.d { app.keys[3] = true }
			.space      { app.keys[4] = true }
			.left_shift { app.keys[5] = true }

			.q { app.cfocal += 0.02 }
			.e { app.cfocal -= 0.02 }
			.z { app.finter += 1    }
			.c { app.finter -= 1    }

			else {return}
		}
	} else if ev.@type == .key_up {
		match ev.key_code {
			.w { app.keys[0] = false }
			.a { app.keys[1] = false }
			.s { app.keys[2] = false }
			.d { app.keys[3] = false }
			.space      { app.keys[4] = false }
			.left_shift { app.keys[5] = false }
			else {return}
		}
	}
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

[inline]
fn vec4(x f32, y f32, z f32, w f32) m4.Vec4 {
	return m4.Vec4{e:[x, y, z, w]!}
}

[unsafe]
fn frame(user_data voidptr) {
	mut app := &App(user_data)
	mut static before_time := f32(0.0)
	
	gfx.begin_default_pass(&app.pass_action, sapp.width(), sapp.height())

	gfx.apply_pipeline(app.shader_pipeline)
	gfx.apply_bindings(&app.bind)

	time_ticks := f32(time.ticks() - app.ticks) / 1000
	dt := (time_ticks - before_time) 
	// println(time_ticks - before_time) <-- ms
	before_time = time_ticks

	ws := gg.window_size_real_pixels()
	ratio := f32(ws.width) / ws.height

	forward := f32(app.keys[0]) - f32(app.keys[2])
	side := f32(app.keys[3]) - f32(app.keys[1])
	up := f32(app.keys[4]) - f32(app.keys[5])
	
	speed := f32(0.17)

	app.crotation.e[0] += app.mouse_dy * 0.1 * dt
	app.crotation.e[1] += app.mouse_dx * 0.1 * dt
	app.mouse_dx = 0.0
	app.mouse_dy = 0.0
	// flush mouse movement

	app.cmatrix = rotatem4(app.crotation)
	app.cvelocity += m4.mul_vec(app.cmatrix.inverse(),vec4(side,0.0,forward,0.0).normalize()).mul_scalar(speed).mul_scalar(dt)
	//app.cvelocity += vec4(0.0,up,0.0,0.0).mul_scalar(speed).mul_scalar(dt)
	app.cmatrix = app.cmatrix.translate(app.cposition)

	app.cvelocity = app.cvelocity.mul_scalar(0.9)

unsafe {

	mut tmp_fs_params := [
		f32(ws.width),
		ws.height * ratio, // x,y resolution to pass to FS
		ratio,
		time_ticks,
		0,0,0, // app.cposition.e[0],app.cposition.e[1],app.cposition.e[2]
		app.cfocal,
		app.finter,
		0,0,0,
		app.cmatrix.e[0],app.cmatrix.e[1],app.cmatrix.e[2],app.cmatrix.e[3],app.cmatrix.e[4],app.cmatrix.e[5],app.cmatrix.e[6],app.cmatrix.e[7],app.cmatrix.e[8],app.cmatrix.e[9],app.cmatrix.e[10],app.cmatrix.e[11],app.cmatrix.e[12],app.cmatrix.e[13],app.cmatrix.e[14],app.cmatrix.e[15]
	]! // for padding, check SOKOL_SHDC_ALIGN

	fs_uniforms_range := gfx.Range{
		ptr: &tmp_fs_params
		size: usize(sizeof(tmp_fs_params))
	}
	gfx.apply_uniforms(.fs, C.SLOT_fs_params, &fs_uniforms_range)

}

	gfx.draw(0, 3, 1)

	gfx.end_pass()
	gfx.commit()
}

fn cameram4(t Vec4, r Vec4)Mat4{
	return rotatem4(r).translate(t)
}

fn rotatem4(r Vec4)Mat4{
	return 
		m4.rotate(r.e[0],vec4(1,0,0,0)) *
		m4.rotate(r.e[1],vec4(0,1,0,0)) *
		m4.rotate(r.e[2],vec4(0,0,1,0))
}