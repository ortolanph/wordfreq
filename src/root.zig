const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Entry = struct {
    word: []const u8,
    count: usize,
};

/// Lowercases `text` in place, turns non-letters into spaces, and counts words.
/// The map keys are slices into `text`, so `text` must outlive the map.
pub fn countWords(allocator: Allocator, text: []u8) !std.StringHashMap(usize) {
    for (text) |*c| {
        c.* = if (std.ascii.isAlphabetic(c.*)) std.ascii.toLower(c.*) else ' ';
    }

    var counts = std.StringHashMap(usize).init(allocator);
    errdefer counts.deinit();

    var it = std.mem.tokenizeScalar(u8, text, ' ');
    while (it.next()) |word| {
        const gop = try counts.getOrPut(word);
        if (!gop.found_existing) gop.value_ptr.* = 0;
        gop.value_ptr.* += 1;
    }
    return counts;
}

/// Sort order: highest count first, then alphabetical.
pub fn moreFrequent(_: void, a: Entry, b: Entry) bool {
    if (a.count != b.count) return a.count > b.count;
    return std.mem.lessThan(u8, a.word, b.word);
}

test "countWords is case-insensitive and ignores punctuation" {
    const allocator = std.testing.allocator;
    var text = "The the THE cat, cat. dog".*;

    var counts = try countWords(allocator, &text);
    defer counts.deinit();

    try std.testing.expectEqual(@as(usize, 3), counts.get("the").?);
    try std.testing.expectEqual(@as(usize, 2), counts.get("cat").?);
    try std.testing.expectEqual(@as(usize, 1), counts.get("dog").?);
}

test "moreFrequent orders by count, then alphabetically" {
    const a: Entry = .{ .word = "apple", .count = 2 };
    const b: Entry = .{ .word = "banana", .count = 2 };
    const c: Entry = .{ .word = "cherry", .count = 5 };

    try std.testing.expect(moreFrequent({}, c, a));
    try std.testing.expect(moreFrequent({}, a, b));
    try std.testing.expect(!moreFrequent({}, b, a));
}
