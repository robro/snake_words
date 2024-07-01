var scratch: [256]u8 = [_]u8{0} ** 256;
var idx: usize = 0;

pub fn scratchBuf(size: usize) []u8 {
    if (size > scratch.len) @panic("Need more scratch!");
    if (idx + size > scratch.len) {
        idx = 0;
    }

    const out = scratch[idx .. idx + size];
    idx += out.len;
    return out;
}
