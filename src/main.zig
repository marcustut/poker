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
    defer {
        for (exprs.items) |expr|
            expr.free(allocator) catch @panic("failed to free Expr");
        exprs.deinit();
    }

    std.debug.print("There are {} solutions for {s}\n", .{ exprs.items.len, cards });
    for (exprs.items) |expr| {
        std.debug.print("{}\n", .{expr});
    }

    std.debug.print("{} cards left in deck\n", .{d.len});
    std.debug.print("{}\n", .{d});
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("poker_lib");
