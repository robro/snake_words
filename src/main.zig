const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Allocator = std.mem.Allocator;

const grid_rows = 30;
const grid_cols = 30;
const grid_size = 32;
const font_path = "resources/fonts/consola.ttf";

pub fn main() !void {
    rl.setConfigFlags(.{ .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(grid_cols * grid_size, grid_rows * grid_size, "snakegram");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var alloc = std.heap.page_allocator;

    const grid = try engine.grid.createGrid(grid_rows, grid_cols, &alloc);
    defer engine.grid.freeGrid(grid, &alloc);

    engine.grid.fillGrid(grid, 'Z', rl.Color.ray_white);
    engine.render.setFont(rl.loadFontEx(font_path, grid_size, null));

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);
        engine.render.renderGrid(grid, rl.Vector2.zero(), grid_size);
        rl.drawFPS(0, 0);
        defer rl.endDrawing();
    }
}
