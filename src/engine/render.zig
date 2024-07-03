const rl = @import("raylib");

const Vector2 = rl.Vector2;
const Grid = @import("objects").grid.Grid;
const Font = rl.Font;
const Color = rl.Color;

const FontSize = enum {
    small,
    medium,
    large,
};

var font_normal: ?Font = null;
var font_medium: ?Font = null;
var font_large: ?Font = null;

pub fn renderGrid(grid: *Grid, position: Vector2, cell_size: usize, font_size: FontSize) void {
    var char: [1:0]u8 = .{0};
    for (grid.cells, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            char[0] = cell.char;
            rl.drawTextEx(
                getFont(font_size),
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

pub fn monoText(font: Font, text: [:0]const u8, position: Vector2, font_size: f32, spacing: f32, color: Color) void {
    var char: [1:0]u8 = .{0};
    for (text, 0..) |c, i| {
        char[0] = c;
        rl.drawTextEx(
            font,
            &char,
            position.add(.{ .x = spacing * @as(f32, @floatFromInt(i)), .y = 0 }),
            font_size,
            0,
            color,
        );
    }
}

pub fn setFont(font_size: FontSize, font: Font) void {
    switch (font_size) {
        .small => font_normal = font,
        .medium => font_medium = font,
        .large => font_large = font,
    }
}

pub fn getFont(font_size: FontSize) Font {
    var font: ?Font = undefined;
    switch (font_size) {
        .small => font = font_normal,
        .medium => font = font_medium,
        .large => font = font_large,
    }
    return if (font == null) rl.getFontDefault() else font.?;
}
