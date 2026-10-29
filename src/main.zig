const std = @import("std");
const Io = std.Io;

const slop_or_good = @import("slop_or_good");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        return;
    }

    const path_good = "~/Documents/note-good.txt";
    const path_slop = "~/Documents/note-slop.txt";
    const path_note = "~/Documents/note-s.txt";
    const path_bin = args[0];

    const idx = std.mem.lastIndexOfAny(u8, path_bin, "/\\") orelse return;
    const name_bin = path_bin[idx + 1 ..];
    // std.log.info("binary name: {s}", .{name_bin});

    const Binary = enum { good, slop, note, unknown };
    const binary = std.meta.stringToEnum(Binary, name_bin) orelse .unknown;
    switch (binary) {
        .good => {
            // std.log.info("good ...", .{});
            try write(init, arena, path_good, args);
        },
        .slop => {
            // std.log.info("slop ...", .{});
            try write(init, arena, path_slop, args);
        },
        .note => {
            // std.log.info("note ...", .{});
            try write(init, arena, path_note, args);
        },
        .unknown => return,
    }
}

fn write(init: std.process.Init, arena: std.mem.Allocator, path: []const u8, args: []const [:0]const u8) !void {
    const actual_path: []const u8 = if (std.mem.startsWith(u8, path, "~/")) blk: {
        const home = init.environ_map.get("HOME") orelse return error.HomeNotSet;
        const expanded = try arena.alloc(u8, home.len + path.len - 1);
        @memcpy(expanded[0..home.len], home);
        @memcpy(expanded[home.len..], path[1..]);
        break :blk expanded;
    } else path;

    const file = try std.Io.Dir.cwd().createFile(
        init.io,
        actual_path,
        .{ .truncate = false },
    );
    defer file.close(init.io);

    const tail = if (args.len > 1) args[1..] else args[args.len..];

    var args_len: usize = if (tail.len > 0) tail.len - 1 else 0;
    for (tail) |arg| args_len += arg.len;

    var timestamp_buf: [20]u8 = undefined;
    const timestamp = blk: {
        const now = std.Io.Clock.real.now(init.io);
        const epoch: std.time.epoch.EpochSeconds = .{
            .secs = @intCast(now.toSeconds()),
        };
        const day = epoch.getEpochDay();
        const year_day = day.calculateYearDay();
        const month_day = year_day.calculateMonthDay();
        const day_seconds = epoch.getDaySeconds();

        break :blk try std.fmt.bufPrint(
            &timestamp_buf,
            "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2} ",
            .{
                year_day.year,
                month_day.month.numeric(),
                month_day.day_index + 1,
                day_seconds.getHoursIntoDay(),
                day_seconds.getMinutesIntoHour(),
                day_seconds.getSecondsIntoMinute(),
            },
        );
    };

    const text = try arena.alloc(u8, timestamp.len + args_len + 1);
    @memcpy(text[0..timestamp.len], timestamp);

    var pos = timestamp.len;
    for (tail, 0..) |arg, i| {
        if (i != 0) {
            text[pos] = ' ';
            pos += 1;
        }
        @memcpy(text[pos .. pos + arg.len], arg);
        pos += arg.len;
    }

    text[pos] = '\n';
    try file.writePositionalAll(init.io, text, try file.length(init.io));
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
