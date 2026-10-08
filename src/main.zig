const std = @import("std");
const wordfreq = @import("wordfreq");

pub fn main(init: std.process.Init) !void {
    // In Debug builds, init.gpa does leak checking for you,
    // so the manual DebugAllocator setup is no longer needed.
    const gpa = init.gpa;
    const io = init.io;

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len < 2) {
        std.debug.print("usage: {s} <file> [top_n]\n", .{args[0]});
        std.process.exit(1);
    }
    const top_n = if (args.len > 2) try std.fmt.parseInt(usize, args[2], 10) else 10;

    const text = std.Io.Dir.cwd().readFileAlloc(io, args[1], gpa, .limited(64 * 1024 * 1024)) catch |err| {
        std.debug.print("cannot read '{s}': {s}\n", .{ args[1], @errorName(err) });
        std.process.exit(1);
    };
    defer gpa.free(text);

    var counts = try wordfreq.countWords(gpa, text);
    defer counts.deinit();

    const entries = try gpa.alloc(wordfreq.Entry, counts.count());
    defer gpa.free(entries);

    var i: usize = 0;
    var map_it = counts.iterator();
    while (map_it.next()) |kv| : (i += 1) {
        entries[i] = .{ .word = kv.key_ptr.*, .count = kv.value_ptr.* };
    }
    std.mem.sort(wordfreq.Entry, entries, {}, wordfreq.moreFrequent);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    for (entries[0..@min(top_n, entries.len)]) |e| {
        try stdout.print("{d:>6}  {s}\n", .{ e.count, e.word });
    }
    try stdout.flush();
}
