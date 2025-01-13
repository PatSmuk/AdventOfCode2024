const std = @import("std");
const util = @import("util");

const ITERATIONS = 2000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines(u24, allocator, "day22.txt", parseLine);
    defer allocator.free(lines);

    var total: usize = 0;

    for (lines) |initial| {
        var secret = initial;

        for (0..ITERATIONS) |_| {
            var temp = secret << 6;
            secret ^= temp;
            secret &= 0xff_ffff;

            temp = secret >> 5;
            secret ^= temp;

            temp = secret << 11;
            secret ^= temp;
            secret &= 0xff_ffff;
        }

        total += secret;

        std.debug.print("{d}: {d}\n", .{ initial, secret });
    }

    std.debug.print("{d}", .{total});
}

fn parseLine(_: std.mem.Allocator, line: []const u8) !u24 {
    return std.fmt.parseInt(u24, line, 10);
}
