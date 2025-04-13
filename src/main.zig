//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("allocator leak");
    }

    var d = lib.Deck.make_deck();
    d.shuffle();
    std.debug.print("Deck: {}\n", .{d});

    const cards = [_]lib.Card{ d.draw().?, d.draw().?, d.draw().?, d.draw().?, d.draw().? };
    var exprs = try lib.solve_target(allocator, &cards, 24);
    defer exprs.deinit();

    std.debug.print("There are {} solutions for {s}\n", .{ exprs.items.len, cards });
    for (exprs.items) |expr| {
        std.debug.print("{}\n", .{expr});
    }

    std.debug.print("{} cars left in deck\n", .{d.len});
    std.debug.print("{}\n", .{d});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("poker_lib");
