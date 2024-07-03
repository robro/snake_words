const std = @import("std");
const rl = @import("raylib");

const KeyboardKey = rl.KeyboardKey;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const InputQueue = struct {
    queue: ArrayList(KeyboardKey),

    pub fn init(alloc: Allocator) InputQueue {
        return InputQueue{
            .queue = ArrayList(KeyboardKey).init(alloc),
        };
    }

    pub fn deinit(self: *InputQueue) void {
        self.queue.deinit();
    }

    pub fn add(self: *InputQueue, key: KeyboardKey) !void {
        if (key != .key_null) try self.queue.append(key);
        if (self.queue.items.len > 2) _ = self.queue.orderedRemove(0);
    }

    pub fn pop(self: *InputQueue) KeyboardKey {
        if (self.queue.items.len == 0) return .key_null;
        return self.queue.orderedRemove(0);
    }

    pub fn clear(self: *InputQueue) void {
        self.queue.clearAndFree();
    }
};
