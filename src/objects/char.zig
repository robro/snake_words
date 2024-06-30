const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = engine.grid.Grid;
const Cell = engine.grid.Cell;
const Vector2 = rl.Vector2;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const Char = struct {
    cell: Cell,
    coord: Vector2,
};

pub const CharGroup = struct {
    chars: ArrayList(Char),

    pub fn newChars(self: *CharGroup, text: [:0]const u8, color: rl.Color, grid: *Grid) !void {
        try self.chars.resize(text.len);
        for (text, 0..) |char, i| {
            const coord = try grid.getFreeCoord('.', &std.heap.page_allocator);
            self.chars.items[i] = .{
                .cell = .{
                    .char = char,
                    .color = color,
                },
                .coord = coord,
            };
            grid.setCell(self.chars.items[i].coord, self.chars.items[i].cell);
        }
    }

    pub fn draw(self: *CharGroup, grid: *Grid) void {
        for (self.chars.items) |*char| grid.setCell(char.coord, char.cell);
    }

    pub fn free(self: *CharGroup) void {
        self.chars.deinit();
    }
};

pub fn createCharGroup(alloc: *Allocator) CharGroup {
    return CharGroup{ .chars = ArrayList(Char).init(alloc.*) };
}
