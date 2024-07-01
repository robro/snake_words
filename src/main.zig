const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");
const objects = @import("objects");
const util = @import("util");

const Allocator = std.mem.Allocator;
const Cell = objects.grid.Cell;
const Grid = objects.grid.Grid;
const Snake = objects.snake.Snake;
const CharGroup = objects.char.CharGroup;
const State = objects.state.State;

const grid_rows = 20;
const grid_cols = 30;
const cell_size = 32;
const font_path = "resources/fonts/consola.ttf";

pub fn main() !void {
    rl.setTargetFPS(60);
    rl.setConfigFlags(.{ .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(grid_cols * cell_size, grid_cols * cell_size, "snakagram");
    defer rl.closeWindow();

    engine.render.setFont(rl.loadFontEx(font_path, cell_size * 2, null));

    const alloc = std.heap.page_allocator;

    var grid = try Grid.init(grid_rows, grid_cols, alloc);
    defer grid.deinit();
    grid.fill(Cell.empty_cell);

    var snake = try Snake.init("snake", rl.Color.gray, 0.1, .{ .x = 5, .y = 5 }, .right, alloc);
    defer snake.deinit();

    var char_group = try CharGroup.init(util.alphabet, rl.Color.orange, &grid);
    defer char_group.deinit();

    var state = try State.init(&snake, &grid, &char_group, alloc);

    while (!rl.windowShouldClose()) {
        engine.input.update();
        try state.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        engine.render.renderGrid(&grid, rl.Vector2.zero(), cell_size);
        rl.drawTextEx(
            engine.render.getFont(),
            state.curr_word,
            .{
                .x = (grid_cols * cell_size / 2) - (cell_size * 2 * 2.5),
                .y = grid_rows * cell_size + 10,
            },
            cell_size * 2,
            cell_size,
            state.color(),
        );
        rl.drawFPS(grid_cols * cell_size - 32, 0);
    }
}
