const rl = @import("raylib");

const Vector2 = rl.Vector2;
const Cell = @import("grid.zig").Cell;

var _font: ?rl.Font = null;

pub fn renderGrid(grid: [][]Cell, position: Vector2, grid_size: usize) void {
    var text: [1:0]u8 = .{0};
    for (grid, 0..) |row, y| {
        for (row, 0..) |item, x| {
            text[0] = item.char;
            rl.drawTextEx(
                if (_font == null) rl.getFontDefault() else _font.?,
                &text,
                position.add(.{
                    .x = @floatFromInt(x * grid_size),
                    .y = @floatFromInt(y * grid_size),
                }),
                @floatFromInt(grid_size),
                0,
                item.color,
            );
        }
    }
}

pub fn setFont(font: rl.Font) void {
    _font = font;
}
