const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");
const objects = @import("objects");

const Allocator = std.mem.Allocator;
const Cell = engine.grid.Cell;

const grid_rows = 30;
const grid_cols = 30;
const cell_size = 32;
const font_path = "resources/fonts/consola.ttf";

pub fn main() !void {
    rl.setConfigFlags(.{ .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(grid_cols * cell_size, grid_rows * cell_size, "snakagram");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var alloc = std.heap.page_allocator;

    var grid = try engine.grid.createGrid(grid_rows, grid_cols, &alloc);
    defer grid.free(&alloc);

    grid.fill(Cell.empty_cell);
    engine.render.setFont(rl.loadFontEx(font_path, cell_size, null));

    var snake = try objects.snake.createSnake(
        "snake",
        rl.Color.yellow,
        0.1,
        .{ .x = 5, .y = 0 },
        .right,
        &alloc,
    );
    defer snake.free();

    while (!rl.windowShouldClose()) {
        snake.update();
        grid.fill(Cell.empty_cell);
        snake.draw(&grid);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        engine.render.renderGrid(&grid, rl.Vector2.zero(), cell_size);
        rl.drawFPS(grid_cols * cell_size - 32, 0);
    }
}
