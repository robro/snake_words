const std = @import("std");
const rl = @import("raylib");
const object = @import("object");
const util = @import("util");
const math = @import("math");

const ArrayList = std.ArrayList;
const Vector2 = rl.Vector2;
const Vec2 = math.Vec2;
const Grid = object.grid.Grid;
const State = object.state.State;
const Font = rl.Font;
const Color = rl.Color;
const assert = util.assert;

var font_normal: ?Font = null;
var font_medium: ?Font = null;
var font_large: ?Font = null;

pub const FontSize = enum {
    small,
    medium,
    large,
};

pub const Drawable = struct {
    ptr: *anyopaque,
    vtab: *const VTab,

    const VTab = struct {
        draw: *const fn (ptr: *anyopaque, grid: *Grid) void,
    };

    pub fn draw(self: Drawable, grid: *Grid) void {
        self.vtab.draw(self.ptr, grid);
    }

    pub fn init(obj: anytype) Drawable {
        const Ptr = @TypeOf(obj);
        const impl = struct {
            fn draw(ptr: *anyopaque, grid: *Grid) void {
                const self = @as(Ptr, @ptrCast(@alignCast(ptr)));
                self.draw(grid);
            }
        };
        return Drawable{
            .ptr = obj,
            .vtab = &.{ .draw = impl.draw },
        };
    }
};

pub fn drawToGrid(grid: *Grid, drawables: ArrayList(Drawable)) void {
    for (drawables.items) |r| r.draw(grid);
}

pub fn renderGrid(grid: *Grid, position: Vector2, cell_size: usize, font_size: FontSize) void {
    var char: [1:0]u8 = .{0};
    for (grid.cells, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            char[0] = cell.char;
            rl.drawTextEx(
                getFont(font_size),
                &char,
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
