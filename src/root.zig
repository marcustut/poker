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
