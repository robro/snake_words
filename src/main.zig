const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");
const objects = @import("objects");

const Allocator = std.mem.Allocator;
const Cell = objects.grid.Cell;

const grid_rows = 30;
const grid_cols = 30;
const cell_size = 32;
const font_path = "resources/fonts/consola.ttf";

pub fn main() !void {
    rl.setTargetFPS(60);
    rl.setConfigFlags(.{ .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(grid_cols * cell_size, grid_cols * cell_size, "snakagram");
    defer rl.closeWindow();

    var alloc = std.heap.page_allocator;

    var grid = try objects.grid.createGrid(grid_rows, grid_cols, &alloc);
    defer grid.free(&alloc);

    grid.fill(Cell.empty_cell);
    engine.render.setFont(rl.loadFontEx(font_path, cell_size, null));

    var snake = try objects.snake.createSnake(
        "snake",
        rl.Color.green,
        0.1,
        .{ .x = 5, .y = 0 },
        .right,
        &alloc,
    );
    defer snake.free();

    var charGroup = objects.char.createCharGroup(&alloc);
    defer charGroup.free();

    var timer: f64 = 0;
    var alphabet = [_:0]u8{0} ** 26;
    inline for ('a'..'{', 0..) |char, i| alphabet[i] = char;

    while (!rl.windowShouldClose()) {
        engine.input.update();

        snake.update();
        grid.fill(Cell.empty_cell);
        if (rl.getTime() > timer) {
            try charGroup.newChars(&alphabet, rl.Color.magenta, &grid);
            timer = rl.getTime() + 3;
        }
        charGroup.draw(&grid);
        snake.draw(&grid);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        engine.render.renderGrid(&grid, rl.Vector2.zero(), cell_size);
        rl.drawFPS(grid_cols * cell_size - 32, 0);
    }
}
