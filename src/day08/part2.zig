const std = @import("std");
const util = @import("util");

const Location = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day08.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    const max_y = lines.len;
    const max_x = lines[0].len;

    var antenna_locations_by_frequency = std.AutoHashMap(u8, std.ArrayList(Location)).init(allocator);
    defer antenna_locations_by_frequency.deinit();
    defer {
        var iter = antenna_locations_by_frequency.valueIterator();
        while (iter.next()) |locations| {
            locations.deinit();
        }
    }

    for (lines, 0..) |line, y| {
        for (line, 0..) |char, x| {
            if (char == '.') {
                continue;
            }

            if (!antenna_locations_by_frequency.contains(char)) {
                const locations = std.ArrayList(Location).init(allocator);
                try antenna_locations_by_frequency.putNoClobber(char, locations);
            }

            var locations = antenna_locations_by_frequency.getPtr(char).?;
            try locations.append(.{ .x = x, .y = y });
        }
    }

    var antinode_locations = std.AutoHashMap(Location, void).init(allocator);
    defer antinode_locations.deinit();

    var frequency_iter = antenna_locations_by_frequency.keyIterator();
    while (frequency_iter.next()) |frequency| {
        const locations = antenna_locations_by_frequency.getPtr(frequency.*).?.items;

        for (0..locations.len - 1) |i| {
            const first_location = locations[i];

            for (1..locations.len - i) |j| {
                const second_location = locations[i + j];
                const dx = @as(isize, @intCast(second_location.x)) - @as(isize, @intCast(first_location.x));
                const dy = @as(isize, @intCast(second_location.y)) - @as(isize, @intCast(first_location.y));

                var m: isize = 0;
                while (true) : (m += 1) {
                    const x = @as(isize, @intCast(first_location.x)) - dx * m;
                    const y = @as(isize, @intCast(first_location.y)) - dy * m;

                    if (!isInBounds(x, y, max_x, max_y)) {
                        break;
                    }

                    try antinode_locations.put(.{ .x = @as(usize, @intCast(x)), .y = @as(usize, @intCast(y)) }, {});
                }

                m = 0;
                while (true) : (m += 1) {
                    const x = @as(isize, @intCast(second_location.x)) + dx * m;
                    const y = @as(isize, @intCast(second_location.y)) + dy * m;

                    if (!isInBounds(x, y, max_x, max_y)) {
                        break;
                    }

                    try antinode_locations.put(.{ .x = @as(usize, @intCast(x)), .y = @as(usize, @intCast(y)) }, {});
                }
            }
        }
    }

    var line_buffer = try allocator.alloc(u8, max_x + 1);
    defer allocator.free(line_buffer);
    line_buffer[max_x] = 0;

    for (0..max_y) |y| {
        for (0..max_x) |x| {
            if (lines[y][x] != '.') {
                line_buffer[x] = lines[y][x];
            } else {
                const location = Location{ .x = x, .y = y };
                if (antinode_locations.contains(location)) {
                    line_buffer[x] = '#';
                } else {
                    line_buffer[x] = '.';
                }
            }
        }
        std.debug.print("{s}\n", .{line_buffer});
    }

    std.debug.print("{d}", .{antinode_locations.count()});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn isInBounds(x: isize, y: isize, max_x: usize, max_y: usize) bool {
    if (x < 0 or y < 0 or x >= max_x or y >= max_y) {
        return false;
    }
    return true;
}
