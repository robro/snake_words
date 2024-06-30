const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");
const objects = @import("objects");

const Allocator = std.mem.Allocator;
const Cell = engine.grid.Cell;

const grid_rows = 30;
const grid_cols = 30;
const grid_size = 32;
const font_path = "resources/fonts/consola.ttf";

pub fn main() !void {
    rl.setConfigFlags(.{ .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(grid_cols * grid_size, grid_rows * grid_size, "snakagram");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var alloc = std.heap.page_allocator;

    const grid = try engine.grid.createGrid(grid_rows, grid_cols, &alloc);
    defer engine.grid.freeGrid(grid, &alloc);

    engine.grid.fillGrid(grid, Cell.empty_cell);
    engine.render.setFont(rl.loadFontEx(font_path, grid_size, null));

    var snake = try objects.snake.createSnake("snake", 0.1, .{ .x = 5, .y = 0 }, .right, &alloc);
    defer snake.free();

    while (!rl.windowShouldClose()) {
        snake.update();
        engine.grid.fillGrid(grid, Cell.empty_cell);
        snake.draw(grid);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        engine.render.renderGrid(grid, rl.Vector2.zero(), grid_size);
        rl.drawFPS(grid_cols * grid_size - 32, 0);
    }
}
