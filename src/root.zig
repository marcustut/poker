const std = @import("std");

pub const Rank = enum {
    two,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
    ten,
    jack,
    queen,
    king,
    ace,

    pub fn value(self: @This()) u8 {
        return switch (self) {
            .ace => 1,
            .two => 2,
            .three => 3,
            .four => 4,
            .five => 5,
            .six => 6,
            .seven => 7,
            .eight => 8,
            .nine => 9,
            .ten => 10,
            .jack => 11,
            .queen => 12,
            .king => 13,
        };
    }

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{s}", .{switch (self) {
            .two => "2",
            .three => "3",
            .four => "4",
            .five => "5",
            .six => "6",
            .seven => "7",
            .eight => "8",
            .nine => "9",
            .ten => "10",
            .jack => "J",
            .queen => "Q",
            .king => "K",
            .ace => "A",
        }});
    }
};
pub const Suit = enum {
    diamond,
    club,
    heart,
    spade,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{s}", .{switch (self) {
            .diamond => "d",
            .club => "c",
            .heart => "h",
            .spade => "s",
        }});
    }
};

pub const Card = struct {
    rank: Rank,
    suit: Suit,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{}{}", .{ self.rank, self.suit });
    }
};

pub const DeckLength = @typeInfo(Rank).@"enum".fields.len * @typeInfo(Suit).@"enum".fields.len;
pub const Deck = struct {
    cards: [DeckLength]?Card,
    len: u8,

    pub fn make_deck() Deck {
        var deck = Deck{ .cards = std.mem.zeroes([52]?Card), .len = DeckLength };
        inline for (std.meta.fields(Suit)) |s| {
            inline for (std.meta.fields(Rank)) |r| {
                const i = s.value * @typeInfo(Rank).@"enum".fields.len + r.value;
                deck.cards[i] = Card{ .rank = @enumFromInt(r.value), .suit = @enumFromInt(s.value) };
            }
        }
        return deck;
    }

    pub fn shuffle(self: *@This()) void {
        // Initialize a random number generator (PRNG)
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.nanoTimestamp()));
        const random = prng.random();

        var count = DeckLength - 1;
        while (count > 0) : (count -= 1) {
            const i = random.intRangeLessThan(u8, 0, DeckLength);
            swap(?Card, &self.cards[count], &self.cards[i]);
        }
    }

    pub fn draw(self: *@This()) ?Card {
        if (self.len == 0) return null;

        self.len -= 1;
        const card = self.cards[self.len];
        self.cards[self.len] = null;
        return card;
    }

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        var i: u8 = 0;
        while (i < self.len) : (i += 1) {
            try writer.print("{?}", .{self.cards[i]});
            if (i != self.len) try writer.print(" ", .{});
        }
    }
};

fn swap(comptime T: type, a: *T, b: *T) void {
    const temp = a.*;
    a.* = b.*;
    b.* = temp;
}

const Op = enum {
    plus,
    minus,
    multiply,
    divide,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("{s}", .{switch (self) {
            .plus => "+",
            .minus => "-",
            .multiply => "*",
            .divide => "/",
        }});
    }
};
const ExprType = enum { number, expr };
const Expr = union(ExprType) {
    number: f64,
    expr: struct { op: Op, x: *const Expr, y: *const Expr },

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .number => |n| try writer.print("{d}", .{n}),
            .expr => |_| {
                // try writer.print("(", .{});
                // try e.x.*.format("", .{}, writer); // recursive call
                // try writer.print(" {} ", .{e.op});
                // try e.y.*.format("", .{}, writer); // recursive call
                // try writer.print(")", .{});
            },
        }
    }
};

fn dfs(nums: []const f64, exprs: []const Expr, results: *std.ArrayList(Expr), target: f64) !void {
    if (nums.len == 1) {
        if (nums[0] == target) {
            try results.append(exprs[0]);
            return;
        }
    }

    // std.debug.print("exprs len: {}\n", .{exprs.len});

    var i: usize = 0;
    while (i < nums.len) : (i += 1) {
        var j: usize = i + 1;
        while (j < nums.len) : (j += 1) {
            // std.debug.print("i: {}, j: {}\n", .{ i, j });

            const a: f64 = nums[i];
            const b: f64 = nums[j];
            const expr_a = &exprs[i];
            const expr_b = &exprs[j];

            var pairs = [6]?struct { f64, Expr }{
                .{ a + b, Expr{ .expr = .{ .op = .plus, .x = expr_a, .y = expr_b } } },
                .{ a - b, Expr{ .expr = .{ .op = .minus, .x = expr_a, .y = expr_b } } },
                .{ b - a, Expr{ .expr = .{ .op = .minus, .x = expr_b, .y = expr_a } } },
                .{ a * b, Expr{ .expr = .{ .op = .multiply, .x = expr_a, .y = expr_b } } },
                null,
                null,
            };

            if (b != 0)
                pairs[4] = .{ a / b, Expr{ .expr = .{ .op = .divide, .x = expr_a, .y = expr_b } } };
            if (a != 0)
                pairs[5] = .{ b / a, Expr{ .expr = .{ .op = .divide, .x = expr_b, .y = expr_a } } };

            var remaining_nums: [5]f64 = undefined;
            var remaining_exprs: [5]Expr = undefined;
            var rc_index: usize = 0;
            var k: usize = 0;
            while (k < nums.len) : (k += 1) {
                if (k != i and k != j) {
                    remaining_nums[rc_index] = nums[k];
                    remaining_exprs[rc_index] = exprs[k];
                    rc_index += 1;
                }
            }

            // For each valid operation, recurse with remaining and result
            for (pairs) |pair| {
                if (pair == null) continue;

                // Call dfs with reduced input
                remaining_nums[rc_index] = pair.?.@"0";
                remaining_exprs[rc_index] = pair.?.@"1";

                try dfs(remaining_nums[0 .. rc_index + 1], remaining_exprs[0 .. rc_index + 1], results, target);
            }
        }
    }
}

pub fn solve_target(allocator: std.mem.Allocator, cards: []const Card, target: u8) !std.ArrayList(Expr) {
    var results = std.ArrayList(Expr).init(allocator);

    var nums = try allocator.alloc(f64, cards.len);
    defer allocator.free(nums);
    for (0..cards.len) |i| nums[i] = @floatFromInt(cards[i].rank.value());

    var exprs = try allocator.alloc(Expr, cards.len);
    defer allocator.free(exprs);
    for (0..cards.len) |i| exprs[i] = Expr{ .number = @floatFromInt(cards[i].rank.value()) };

    try dfs(nums, exprs, &results, @floatFromInt(target));
    return results;
}
