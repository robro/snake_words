const rl = @import("raylib");

const Vector2 = rl.Vector2;
const Grid = @import("objects").grid.Grid;
const Font = rl.Font;

pub var _font: ?Font = null;

pub fn renderGrid(grid: *Grid, position: Vector2, cell_size: usize) void {
    var text: [1:0]u8 = .{0};
    for (grid.cells, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            text[0] = cell.char;
            rl.drawTextEx(
                getFont(),
                &text,
                position.add(.{
                    .x = @floatFromInt(x * cell_size),
                    .y = @floatFromInt(y * cell_size),
                }),
                @floatFromInt(cell_size),
                0,
                cell.color,
            );
        }
    }
}

pub fn setFont(font: Font) void {
    _font = font;
}

pub fn getFont() Font {
    return if (_font == null) rl.getFontDefault() else _font.?;
}
