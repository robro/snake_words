const rl = @import("raylib");

const Vector2 = rl.Vector2;
const Grid = @import("objects").grid.Grid;
const Font = rl.Font;
const Color = rl.Color;

pub var _font: ?Font = null;

pub fn renderGrid(grid: *Grid, position: Vector2, cell_size: usize) void {
    var char: [1:0]u8 = .{0};
    for (grid.cells, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            char[0] = cell.char;
            rl.drawTextEx(
                getFont(),
                &char,
                position.add(.{
                    .x = @floatFromInt(x * cell_size + cell_size / 4),
                    .y = @floatFromInt(y * cell_size + cell_size / 4),
                }),
                @floatFromInt(cell_size),
                0,
                cell.color,
            );
        }
    }
}

pub fn renderText(text: [:0]const u8, position: Vector2, font_size: f32, spacing: f32, color: Color) void {
    var char: [1:0]u8 = .{0};
    for (text, 0..) |c, i| {
        char[0] = c;
        rl.drawTextEx(
            getFont(),
            &char,
            position.add(.{ .x = spacing * @as(f32, @floatFromInt(i)), .y = 0 }),
            font_size,
            spacing,
            color,
        );
    }
}

pub fn setFont(font: Font) void {
    _font = font;
}

pub fn getFont() Font {
    return if (_font == null) rl.getFontDefault() else _font.?;
}
