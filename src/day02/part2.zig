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
        if (try isReportSafe(allocator, report)) {
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

/// Returns `true` if `report` is safe, `false` otherwise
fn isReportSafe(allocator: std.mem.Allocator, report: []u8) !bool {
    // Get the first unsafe index or return true if it is safe
    const i = isReportSafeInner(report) orelse return true;

    // Special case: first pair is ascending and rest is descending or vice-versa
    // In this case we need to try removing the first level
    if (i == 1 and isReportSafeInner(report[1..]) == null) {
        return true;
    }

    // Remove the first element of the pair that caused an issue and check again
    const report_without_i = try std.mem.concat(allocator, u8, &[_][]const u8{
        report[0..i],
        report[i + 1 ..],
    });
    defer allocator.free(report_without_i);

    if (isReportSafeInner(report_without_i) == null) {
        return true;
    }

    // Remove the second element of the pair that caused an issue and check again
    const report_without_i_plus_one = try std.mem.concat(allocator, u8, &[_][]const u8{
        report[0 .. i + 1],
        report[i + 2 ..],
    });
    defer allocator.free(report_without_i_plus_one);

    return isReportSafeInner(report_without_i_plus_one) == null;
}

/// Checks whether `report` is safe, returning the index of the first pair of
/// elements that is unsafe or `null` is the entire report is safe
fn isReportSafeInner(report: []u8) ?usize {
    const must_ascend = report[0] < report[1];

    // Determine if the report is safe without modification
    var i: u8 = 0;
    while (i < report.len - 1) : (i += 1) {
        // Check whether ascending/descending is consistent
        if (must_ascend) {
            if (report[i] > report[i + 1]) {
                return i;
            }
        } else {
            if (report[i] < report[i + 1]) {
                return i;
            }
        }

        // Check that each pair is 1 to 3 units up or down
        const distance = @abs(@as(i16, report[i]) - @as(i16, report[i + 1]));
        if (distance < 1 or distance > 3) {
            return i;
        }
    }

    return null;
}
