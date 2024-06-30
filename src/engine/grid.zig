const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;

pub const Cell = struct {
    char: u8,
    color: rl.Color,
};

pub fn createGrid(rows: usize, cols: usize, alloc: *Allocator) ![][]Cell {
    const grid = try alloc.alloc([]Cell, rows);
    for (0..rows) |row| {
        grid[row] = try alloc.alloc(Cell, cols);
    }
    return grid;
}

pub fn drawToCell(grid: [][]Cell, coord: Vector2, cell: Cell) void {
    if (coord.x < 0 or coord.y < 0) return;
    if (coord.x >= @as(f32, @floatFromInt(grid[0].len)) or
        coord.y >= @as(f32, @floatFromInt(grid.len))) return;
    grid[@intFromFloat(coord.y)][@intFromFloat(coord.x)] = cell;
}

pub fn freeGrid(grid: [][]Cell, alloc: *Allocator) void {
    for (grid) |row| alloc.free(row);
    alloc.free(grid);
}

pub fn fillGrid(grid: [][]Cell, char: u8, color: rl.Color) void {
    for (grid) |row| {
        for (row) |*item| {
            item.char = char;
            item.color = color;
        }
    }
}
