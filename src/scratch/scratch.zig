const assert = @import("util").assert;

var scratch: [256]u8 = [_]u8{0} ** 256;
var idx: usize = 0;

pub fn scratchBuf(size: usize) []u8 {
    assert(
        size <= scratch.len,
        "size must be no bigger than {d}. requested {d}",
        .{ scratch.len, size },
    );
    if (idx + size > scratch.len) {
        idx = 0;
    }

    const out = scratch[idx .. idx + size];
    idx += out.len;
    return out;
}
