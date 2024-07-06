const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");
const object = @import("object");
const util = @import("util");
const scratch = @import("scratch");
const math = @import("math");

const Color = rl.Color;
const Vec2 = math.Vec2;
const Range2 = math.Range2;
const Vector2 = rl.Vector2;
const Allocator = std.mem.Allocator;
const Facing = object.snake.Facing;
const TitleSnakeOptions = object.title.TitleSnakeOptions;
const Grid = object.grid.Grid;
const GridOptions = object.grid.GridOptions;
const SnakeOptions = object.snake.SnakeOptions;
const State = object.state.State;
const FontSize = engine.render.FontSize;

const setFont = engine.render.setFont;
const getFont = engine.render.getFont;
const monoText = engine.render.monoText;
const renderGrid = engine.render.renderGrid;
const drawToGrid = engine.render.drawToGrid;

const title = "snake_words";

// Dimensions
const grid_rows = 12;
const grid_cols = 12;
const cell_size = 64;
const grid_width = grid_cols * cell_size;
const grid_height = grid_rows * cell_size;
const win_width = grid_width;
const win_height = grid_height + (cell_size * 6);
const hud_y = grid_height + (cell_size / 2);

// Font
const font_size_small = 64;
const font_size_medium = font_size_small * 1.5;
const font_size_large = font_size_small * 2;
const font_path = "resources/fonts/consola.ttf";

// HUD formatting
const score_fmt = "{d:}";
const combo_fmt = "{d:} combo";
const multi_fmt = "x{d}";

// Snake defaults
const snake_text = "snake";
const snake_color = Color.ray_white;
const title_snake_color = Color.ray_white;
const snake_tick = 0.125;
const snake_coord = Vec2{ .x = grid_cols - 4, .y = grid_rows / 2 };
const snake_facing = Facing.left;

// Misc
const empty_char: u8 = '.';
const bg_color = Color.black;
const fps = 60;
const colors: []const [2]Color = &.{
    .{ Color.orange, Color.dark_brown },
    .{ Color.green, Color.dark_green },
    .{ Color.purple, Color.dark_purple },
    .{ Color.yellow, Color.dark_brown },
    .{ Color.sky_blue, Color.dark_blue },
    .{ Color.red, Color.init(100, 20, 30, 255) },
};

pub fn main() !void {
    rl.setConfigFlags(.{ .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(win_width, win_height, title);
    defer rl.closeWindow();

    setFont(.small, rl.loadFontEx(font_path, font_size_small, null));
    setFont(.medium, rl.loadFontEx(font_path, font_size_medium, null));
    setFont(.large, rl.loadFontEx(font_path, font_size_large, null));

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("gpa leaked!");
    }

    const bounds = Range2.init(0, 0, grid_rows, grid_cols);

    const title_snake_options = TitleSnakeOptions{
        .color = title_snake_color,
        .rows = grid_rows,
        .cols = grid_cols,
        .tick = snake_tick,
        .alloc = alloc,
    };
    const grid_options = GridOptions{
        .rows = grid_rows,
        .cols = grid_cols,
        .empty_char = empty_char,
        .alloc = alloc,
    };
    const snake_options = SnakeOptions{
        .text = snake_text,
        .color = snake_color,
        .tick = snake_tick,
        .coord = snake_coord,
        .facing = snake_facing,
        .alloc = alloc,
    };

    var state = try State.init(
        title_snake_options,
        snake_options,
        bounds,
        colors,
        alloc,
    );
    defer state.deinit();

    var grid = try Grid.init(grid_options);
    defer grid.deinit();

    rl.setTargetFPS(fps);

    while (!rl.windowShouldClose()) {
        try state.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(bg_color);

        grid.fill(state.gridColor());
        drawToGrid(&grid, &state.drawables);
        renderGrid(&grid, Vector2.zero(), cell_size, FontSize.small);
        renderHUD(&state);
        // rl.drawFPS(win_width - 30, 0);
    }
}

fn renderHUD(state: *State) void {
    const target_width: f32 = @as(f32, @floatFromInt(state.target_word.len)) * cell_size * 2;
    const partial_width: f32 = @as(f32, @floatFromInt(state.partialLength())) * cell_size * 2;
    const gameover_width: f32 = @as(f32, @floatFromInt(state.gameover_text.len)) * cell_size * 2;

    // Target word
    monoText(
        getFont(.large),
        @ptrCast(state.targetDisplay()),
        .{
            .x = (win_width / 2) - (target_width / 2) + (cell_size / 2),
            .y = hud_y,
        },
        cell_size * 2,
        cell_size * 2,
        state.targetColor(),
    );

    // Evaluation bar
    rl.drawRectangle(
        0,
        hud_y,
        win_width,
        cell_size * 2,
        state.evaluateColor(),
    );

    // Partial word
    monoText(
        getFont(.large),
        @ptrCast(state.partialWord()),
        .{
            .x = (win_width / 2) - (target_width / 2) + (cell_size / 2),
            .y = hud_y,
        },
        cell_size * 2,
        cell_size * 2,
        state.partialColor(),
    );

    // Title text
    monoText(
        getFont(.large),
        @ptrCast(state.title_text),
        .{
            .x = (win_width / 2) - (gameover_width / 2) + (cell_size / 2),
            .y = hud_y,
        },
        cell_size * 2,
        cell_size * 2,
        state.titleColor(),
    );

    // Gameover text
    monoText(
        getFont(.large),
        @ptrCast(state.gameover_text),
        .{
            .x = (win_width / 2) - (gameover_width / 2) + (cell_size / 2),
            .y = hud_y,
        },
        cell_size * 2,
        cell_size * 2,
        state.gameoverColor(),
    );

    // Terminal cursor
    rl.drawRectangle(
        @as(i32, @intFromFloat((win_width / 2) - (target_width / 2) + (cell_size / 2) + (partial_width))),
        hud_y,
        cell_size + 4,
        cell_size * 2,
        state.cursorColor(),
    );

    // Score
    rl.drawTextEx(
        getFont(.medium),
        std.fmt.bufPrintZ(scratch.scratchBuf(16), score_fmt, .{state.scoreDisplay()}) catch unreachable,
        .{
            .x = cell_size,
            .y = win_height - cell_size * 3,
        },
        font_size_medium,
        2,
        state.pointsColor(),
    );

    // Combo
    rl.drawTextEx(
        getFont(.small),
        std.fmt.bufPrintZ(
            scratch.scratchBuf(16),
            combo_fmt,
            .{if (state.game_state == .gameover) state.max_combo else state.combo},
        ) catch unreachable,
        .{
            .x = cell_size + cell_size / 8,
            .y = win_height - cell_size * 1.5,
        },
        font_size_small,
        2,
        state.pointsColor(),
    );

    // Multiplier
    rl.drawTextEx(
        getFont(.medium),
        std.fmt.bufPrintZ(scratch.scratchBuf(3), multi_fmt, .{state.multiplier}) catch unreachable,
        .{
            .x = win_width - cell_size * 3,
            .y = win_height - cell_size * 3,
        },
        font_size_medium,
        2,
        state.multiplierColor(),
    );
}
