const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const Vector2 = rl.Vector2;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const Char = struct {
    cell: Cell,
    coord: Vector2,
};

pub const CharGroup = struct {
    chars: ArrayList(Char),

    pub fn init(text: [:0]const u8, color: rl.Color, grid: *Grid) !CharGroup {
        var chars = ArrayList(Char).init(std.heap.page_allocator);
        try newChars(&chars, text, color, grid);
        return CharGroup{ .chars = chars };
    }

    pub fn deinit(self: *CharGroup) void {
        self.chars.deinit();
    }

    pub fn pop(self: *CharGroup, idx: usize) Char {
        return self.chars.orderedRemove(idx);
    }

    pub fn draw(self: *const CharGroup, grid: *Grid) void {
        for (self.chars.items) |*char| grid.setCell(char.coord, char.cell);
    }
};

pub fn newChars(chars: *ArrayList(Char), text: [:0]const u8, color: rl.Color, grid: *Grid) !void {
    try chars.resize(text.len);
    for (text, 0..) |char, i| {
        const coord = try grid.getFreeCoord('.', &std.heap.page_allocator);
        chars.items[i] = .{
            .cell = .{
                .char = char,
                .color = color,
            },
            .coord = coord,
        };
        grid.setCell(chars.items[i].coord, chars.items[i].cell);
    }
}
