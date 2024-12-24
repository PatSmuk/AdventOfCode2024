const std = @import("std");
const util = @import("util");

const Direction = enum(u3) { up, right, down, left };

const DirectionVector = [2]i8;

const direction_vectors = std.EnumMap(Direction, DirectionVector).init(.{
    .up = .{ 0, -1 },
    .right = .{ 1, 0 },
    .down = .{ 0, 1 },
    .left = .{ -1, 0 },
});

const Position = struct {
    row: usize,
    col: usize,
};

var looping_position_count = std.atomic.Value(usize).init(0);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try util.readInputFileLines([]u8, allocator, "day06.txt", parseLine);
    defer allocator.free(grid);
    defer {
        for (grid) |line| {
            allocator.free(line);
        }
    }

    const max_row = grid.len;
    const max_col = grid[0].len;

    // Find starting position
    var start_position: Position = undefined;

    for (0.., grid) |row, line| {
        for (0.., line) |col, char| {
            if (char == '^') {
                start_position.row = row;
                start_position.col = col;
            }
        }
    }

    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{ .allocator = allocator });
    defer thread_pool.deinit();

    var wait_group = std.Thread.WaitGroup{};

    for (0..max_row) |row| {
        for (0..max_col) |col| {
            const blocked_position = Position{ .row = row, .col = col };
            thread_pool.spawnWg(&wait_group, worker, .{ grid, start_position, blocked_position });
        }
    }

    wait_group.wait();

    std.debug.print("\n{d}", .{looping_position_count.load(.unordered)});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn worker(grid: [][]const u8, start_position: Position, blocked_position: Position) void {
    if (willGuardLoopIfPositionBlocked(grid, blocked_position, start_position)) {
        _ = looping_position_count.fetchAdd(1, .monotonic);
    }
}

fn willGuardLoopIfPositionBlocked(grid: [][]const u8, blocked_position: Position, start_position: Position) bool {
    var guard1 = Guard{
        .position = start_position,
        .direction = .up,
        .grid = grid,
        .blocked_position = blocked_position,
    };
    var guard2 = Guard{
        .position = start_position,
        .direction = .up,
        .grid = grid,
        .blocked_position = blocked_position,
    };

    while (true) {
        // Guard 1 takes two steps, checking if it goes out of bounds on either
        if (!guard1.step() or !guard1.step()) {
            return false;
        }
        // Guard 2 takes one step, can't be OOB (guard 1 would already have been OOB)
        _ = guard2.step();

        // If they ever end up in the same position going the same direction, must be looping
        if (guard1.position.row == guard2.position.row and guard1.position.col == guard2.position.col and guard1.direction == guard2.direction) {
            return true;
        }

        // Otherwise continue until they collide or go out of bounds
    }
}

const Guard = struct {
    position: Position,
    direction: Direction,

    grid: [][]const u8,
    blocked_position: Position,

    fn step(self: *Guard) bool {
        var next_row: usize = undefined;
        var next_col: usize = undefined;

        // Loop until we have somewhere to go (might take up to 2 rotations)
        while (true) {
            const maybe_next_col = @as(isize, @intCast(self.position.col)) + direction_vectors.get(self.direction).?[0];
            const maybe_next_row = @as(isize, @intCast(self.position.row)) + direction_vectors.get(self.direction).?[1];

            if (!self.isInBounds(maybe_next_row, maybe_next_col)) {
                return false;
            }

            next_row = @as(usize, @intCast(maybe_next_row));
            next_col = @as(usize, @intCast(maybe_next_col));

            // If we're in a wall, try rotating
            if ((next_row == self.blocked_position.row and next_col == self.blocked_position.col) or self.grid[next_row][next_col] == '#') {
                const new_direction = (@intFromEnum(self.direction) + 1) % 4;
                self.direction = @enumFromInt(new_direction);
                continue;
            }

            break;
        }

        self.position.row = next_row;
        self.position.col = next_col;
        return true;
    }

    fn isInBounds(self: Guard, row: isize, col: isize) bool {
        if (col < 0 or row < 0 or col >= self.grid[0].len or row >= self.grid.len) {
            return false;
        }
        return true;
    }
};
