const std = @import("std");
const util = @import("util");

const DirectionVector = [2]i8;

const direction_vectors = [_]DirectionVector{
    .{ 0, -1 }, // up
    .{ 1, 0 }, // right
    .{ 0, 1 }, // down
    .{ -1, 0 }, // left
};

const LeftOrRight = enum {
    left,
    right,
};

const UpOrDown = enum {
    up,
    down,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day15.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var grid = std.ArrayList([]u8).init(allocator);
    defer grid.deinit();

    var moves = std.ArrayList(u8).init(allocator);
    defer moves.deinit();

    var robot_x: u8 = undefined;
    var robot_y: u8 = undefined;

    for (lines, 0..) |line, y| {
        if (line[0] == '#') {
            try grid.append(line);
            if (std.mem.indexOfScalar(u8, line, '@')) |x| {
                robot_x = @as(u8, @intCast(x));
                robot_y = @as(u8, @intCast(y));
            }
        } else if (line.len > 0) {
            try moves.appendSlice(line);
        }
    }

    const total_boxes = countBoxes(grid.items);

    for (moves.items) |move| {
        if (move == '<') {
            if (shiftBoxesHorizontal(grid.items[robot_y], robot_x, .left)) {
                robot_x -= 1;
            }
        } else if (move == '>') {
            if (shiftBoxesHorizontal(grid.items[robot_y], robot_x, .right)) {
                robot_x += 1;
            }
        } else if (move == '^') {
            if (try shiftBoxesVertical(allocator, grid.items, robot_x, robot_y, .up)) {
                robot_y -= 1;
            }
        } else if (move == 'v') {
            if (try shiftBoxesVertical(allocator, grid.items, robot_x, robot_y, .down)) {
                robot_y += 1;
            }
        }

        std.debug.assert(countBoxes(grid.items) == total_boxes);
    }

    var coord_sum: usize = 0;
    for (grid.items, 0..) |line, y| {
        for (line, 0..) |char, x| {
            if (char == '[') {
                coord_sum += 100 * y + x;
            }
        }
    }

    std.debug.print("{d}", .{coord_sum});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    if (line[0] != '#') {
        return allocator.dupe(u8, line);
    }

    var doubled_line = try allocator.alloc(u8, line.len * 2);
    for (line, 0..) |char, i| {
        switch (char) {
            '#' => {
                doubled_line[i * 2] = '#';
                doubled_line[i * 2 + 1] = '#';
            },
            '.' => {
                doubled_line[i * 2] = '.';
                doubled_line[i * 2 + 1] = '.';
            },
            '@' => {
                doubled_line[i * 2] = '@';
                doubled_line[i * 2 + 1] = '.';
            },
            'O' => {
                doubled_line[i * 2] = '[';
                doubled_line[i * 2 + 1] = ']';
            },
            else => unreachable,
        }
    }
    return doubled_line;
}

fn shiftBoxesHorizontal(row: []u8, start_x: u8, left_or_right: LeftOrRight) bool {
    const dx: i8 = if (left_or_right == .left) -1 else 1;
    var end_x: u8 = @as(u8, @intCast(@as(i8, @intCast(start_x)) + dx));

    while (row[end_x] != '.') {
        if (row[end_x] == '#') {
            return false;
        }
        end_x = @as(u8, @intCast(@as(i8, @intCast(end_x)) + dx));
    }

    var x = end_x;
    while (x != start_x) {
        const prev_x = @as(u8, @intCast(@as(i8, @intCast(x)) - dx));
        row[x] = row[prev_x];
        x = prev_x;
    }
    row[start_x] = '.';
    return true;
}

const Cell = struct { x: u8, y: u8 };

fn shiftBoxesVertical(allocator: std.mem.Allocator, grid: [][]u8, start_x: u8, start_y: u8, up_or_down: UpOrDown) !bool {
    const dy: i8 = if (up_or_down == .up) -1 else 1;
    const num_cols = grid[0].len;

    var dirty_cells = std.ArrayList(Cell).init(allocator);
    defer dirty_cells.deinit();
    try dirty_cells.append(.{ .x = start_x, .y = start_y });

    var dirty_set = std.AutoHashMap(usize, void).init(allocator);
    defer dirty_set.deinit();
    try dirty_set.put(start_y * num_cols + start_x, {});

    var cells_to_check = std.ArrayList(Cell).init(allocator);
    defer cells_to_check.deinit();
    try cells_to_check.append(.{
        .x = start_x,
        .y = @as(u8, @intCast(@as(i8, @intCast(start_y)) + dy)),
    });

    while (cells_to_check.items.len > 0) {
        const cell = cells_to_check.orderedRemove(0);
        const value = grid[cell.y][cell.x];

        switch (value) {
            '#' => return false,
            '.' => continue,
            '[' => {
                if (!dirty_set.contains(cell.y * num_cols + cell.x)) {
                    try dirty_set.put(cell.y * num_cols + cell.x, {});
                    try dirty_set.put(cell.y * num_cols + cell.x + 1, {});

                    try dirty_cells.append(cell);
                    try dirty_cells.append(.{ .x = cell.x + 1, .y = cell.y });

                    try cells_to_check.append(.{
                        .x = cell.x,
                        .y = @as(u8, @intCast(@as(i8, @intCast(cell.y)) + dy)),
                    });
                    try cells_to_check.append(.{
                        .x = cell.x + 1,
                        .y = @as(u8, @intCast(@as(i8, @intCast(cell.y)) + dy)),
                    });
                }
            },
            ']' => {
                if (!dirty_set.contains(cell.y * num_cols + cell.x)) {
                    try dirty_set.put(cell.y * num_cols + cell.x, {});
                    try dirty_set.put(cell.y * num_cols + cell.x - 1, {});

                    try dirty_cells.append(cell);
                    try dirty_cells.append(.{ .x = cell.x - 1, .y = cell.y });

                    try cells_to_check.append(.{
                        .x = cell.x,
                        .y = @as(u8, @intCast(@as(i8, @intCast(cell.y)) + dy)),
                    });
                    try cells_to_check.append(.{
                        .x = cell.x - 1,
                        .y = @as(u8, @intCast(@as(i8, @intCast(cell.y)) + dy)),
                    });
                }
            },
            else => unreachable,
        }
    }

    while (dirty_cells.popOrNull()) |cell| {
        const new_y = @as(u8, @intCast(@as(i8, @intCast(cell.y)) + dy));
        grid[new_y][cell.x] = grid[cell.y][cell.x];
        grid[cell.y][cell.x] = '.';
    }

    return true;
}

fn countBoxes(grid: [][]const u8) u16 {
    var count: u16 = 0;

    for (grid) |row| {
        for (row) |char| {
            if (char == '[') {
                count += 1;
            }
        }
    }

    return count;
}
