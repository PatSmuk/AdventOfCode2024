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
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}
