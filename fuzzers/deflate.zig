const std = @import("std");

export fn cMain() void {
    main() catch unreachable;
}

comptime {
    @export(cMain, .{ .name = "main", .linkage = .Strong });
}

pub fn main() !void {
    // Setup an allocator that will detect leaks/use-after-free/etc
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // this will check for leaks and crash the program if it finds any
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // Read the data from stdin
    const stdin = std.io.getStdIn();
    const data = try stdin.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(data);

    // Try to parse the data
    var fbs = std.io.fixedBufferStream(data);
    const reader = fbs.reader();
    var inflate = std.compress.flate.decompressor(reader);

    const inflated = inflate.reader().readAllAlloc(allocator, std.math.maxInt(usize)) catch {
        return;
    };
    defer allocator.free(inflated);
}
