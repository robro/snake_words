const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");
const objects = @import("objects");
const util = @import("util");
const scratch = @import("scratch");

const Allocator = std.mem.Allocator;
const Cell = objects.grid.Cell;
const Grid = objects.grid.Grid;
const Snake = objects.snake.Snake;
const FoodGroup = objects.food.FoodGroup;
const State = objects.state.State;

const grid_rows = 12;
const grid_cols = 12;
const cell_size = 64;
const win_width = grid_cols * cell_size;
const win_height = (grid_rows * cell_size) + (cell_size * 6);
const font_path = "resources/fonts/consola.ttf";
const start_tick = 0.125;
const score_scale = 1.5;

pub fn main() !void {
    rl.setTargetFPS(60);
    rl.setConfigFlags(.{ .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(win_width, win_height, "snakagram");
    defer rl.closeWindow();

    engine.render.setFont(rl.loadFontEx(font_path, cell_size * 2, null));

    const alloc = std.heap.page_allocator;

    var grid = try Grid.init(grid_rows, grid_cols, alloc);
    defer grid.deinit();
    grid.fill(Cell.empty_cell);

    var snake = try Snake.init(
        "snake",
        rl.Color.ray_white,
        start_tick,
        .{ .x = grid_cols - 5, .y = grid_rows / 2 },
        .left,
        alloc,
    );
    defer snake.deinit();
    snake.draw(&grid);

    var food_group = try FoodGroup.init(util.words[0], rl.Color.orange, &grid);
    defer food_group.deinit();

    var state = try State.init(&snake, &food_group, &grid, alloc);

    while (!rl.windowShouldClose()) {
        engine.input.update();
        try state.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        engine.render.renderGrid(&grid, rl.Vector2.zero(), cell_size);
        try renderHUD(&state, &food_group);
    }
}

fn renderHUD(state: *State, food_group: *FoodGroup) !void {
    const score_fmt = "{d:}";
    const combo_fmt = "{d:} combo";
    const multi_fmt = "x{d}";
    const target_string = scratch.scratchBuf(6);

    if (!food_group.edible) {
        for (target_string) |*char| {
            char.* = std.crypto.random.uintLessThan(u8, 26) + 97;
        }
    } else {
        std.mem.copyForwards(u8, target_string, state.target_word);
    }
    target_string[5] = 0;

    rl.drawRectangle(
        0,
        (grid_rows * cell_size) + (cell_size / 2),
        win_width,
        cell_size * 2,
        state.evalColor(),
    );
    engine.render.renderText(
        @ptrCast(target_string),
        .{
            .x = (win_width / 2) - (cell_size * 5) + (cell_size / 2),
            .y = (grid_rows * cell_size) + (cell_size / 2),
        },
        cell_size * 2,
        cell_size * 2,
        state.bgColor(),
    );
    engine.render.renderText(
        state.partialWord(),
        .{
            .x = (win_width / 2) - (cell_size * 5) + (cell_size / 2),
            .y = (grid_rows * cell_size) + (cell_size / 2),
        },
        cell_size * 2,
        cell_size * 2,
        state.partialColor(),
    );
    rl.drawRectangle(
        @intFromFloat((win_width / 2) - (cell_size * 5) + (cell_size / 2) + (cell_size * 2 * @as(f32, @floatFromInt(state.partialLength())))),
        (grid_rows * cell_size) + (cell_size / 2),
        cell_size + 4,
        cell_size * 2,
        state.cursorColor(),
    );
    rl.drawTextEx(
        engine.render.getFont(),
        try std.fmt.bufPrintZ(scratch.scratchBuf(16), score_fmt, .{state.score}),
        .{
            .x = cell_size,
            .y = win_height - cell_size * 3,
        },
        cell_size * score_scale,
        1,
        state.bgColor(),
    );
    rl.drawTextEx(
        engine.render.getFont(),
        try std.fmt.bufPrintZ(scratch.scratchBuf(16), combo_fmt, .{state.combo}),
        .{
            .x = cell_size + cell_size / 8,
            .y = win_height - cell_size * 1.5,
        },
        cell_size,
        1,
        state.bgColor(),
    );
    rl.drawTextEx(
        engine.render.getFont(),
        try std.fmt.bufPrintZ(scratch.scratchBuf(4), multi_fmt, .{state.multiplier}),
        .{
            .x = win_width - cell_size * 3,
            .y = win_height - cell_size * 3,
        },
        cell_size * score_scale,
        1,
        state.multiColor(),
    );
}
