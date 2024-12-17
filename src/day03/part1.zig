const std = @import("std");
const util = @import("util");
const regex = @import("regex");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var pattern = try regex.Regex.compile(allocator, "mul\\((\\d{1,3}),(\\d{1,3})\\)");
    defer pattern.deinit();

    const lines = try util.readInputFileLines([]u8, allocator, "day03.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var sum: u32 = 0;
    for (lines) |line| {
        var current_line = line;
        var maybe_captures = try pattern.captures(current_line);
        while (maybe_captures) |*captures| {
            const first_arg = captures.sliceAt(1).?;
            const second_arg = captures.sliceAt(2).?;

            const first_num = try std.fmt.parseInt(u32, first_arg, 10);
            const second_num = try std.fmt.parseInt(u32, second_arg, 10);
            sum += first_num * second_num;

            // Update line slice to remove everything up to end of current match
            const span = captures.boundsAt(0).?;
            current_line = current_line[span.upper..];

            // Try to capture another match, if one exists
            captures.deinit();
            maybe_captures = try pattern.captures(current_line);
        }
    }

    std.debug.print("{d}", .{sum});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}
