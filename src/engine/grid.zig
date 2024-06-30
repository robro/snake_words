const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;

pub const ColorChar = struct {
    char: u8,
    color: rl.Color,
};

pub fn createGrid(rows: usize, cols: usize, alloc: *Allocator) ![][]ColorChar {
    const grid = try alloc.alloc([]ColorChar, rows);
    for (0..rows) |row| {
        grid[row] = try alloc.alloc(ColorChar, cols);
    }
    return grid;
}

pub fn freeGrid(grid: [][]ColorChar, alloc: *Allocator) void {
    for (grid) |row| alloc.free(row);
    alloc.free(grid);
}

pub fn fillGrid(grid: [][]ColorChar, char: u8, color: rl.Color) void {
    for (grid) |row| {
        for (row) |*item| {
            item.char = char;
            item.color = color;
        }
    }
}
