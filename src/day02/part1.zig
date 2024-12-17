const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const reports = try util.readInputFileLines([]u8, allocator, "day02.txt", parseLine);
    defer allocator.free(reports);
    defer {
        for (reports) |report| {
            allocator.free(report);
        }
    }

    var safe_count: u16 = 0;
    for (reports) |report| {
        if (isReportSafe(report)) {
            safe_count += 1;
        }
    }

    std.debug.print("{d}", .{safe_count});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    var pieces = std.mem.tokenizeAny(u8, line, " \r");

    var report = std.ArrayList(u8).init(allocator);
    defer report.deinit();

    while (pieces.next()) |piece| {
        const level = try std.fmt.parseInt(u8, piece, 10);
        try report.append(level);
    }

    return allocator.dupe(u8, report.items);
}

fn isReportSafe(report: []u8) bool {
    var window = std.mem.window(u8, report, 2, 1);
    const must_ascend = report[0] < report[1];

    while (window.next()) |pair| {
        // Check whether ascending/descending is consistent
        if (must_ascend) {
            if (pair[0] > pair[1]) {
                return false;
            }
        } else {
            if (pair[0] < pair[1]) {
                return false;
            }
        }

        // Check that each is pair is 1 to 3 units up or down
        const distance = @abs(@as(i16, pair[0]) - @as(i16, pair[1]));
        if (distance < 1 or distance > 3) {
            return false;
        }
    }

    return true;
}
