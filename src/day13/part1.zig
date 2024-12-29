const std = @import("std");
const util = @import("util");
const Regex = @import("regex").Regex;

const Button = struct {
    x: u32,
    y: u32,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var button_regex = try Regex.compile(allocator, "Button (A|B): X\\+(\\d+), Y\\+(\\d+)");
    defer button_regex.deinit();
    var prize_regex = try Regex.compile(allocator, "Prize: X=(\\d+), Y=(\\d+)");
    defer prize_regex.deinit();

    const lines = try util.readInputFileLines([]u8, allocator, "day13.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var a_button = Button{ .x = 0, .y = 0 };
    var b_button = Button{ .x = 0, .y = 0 };

    var total_tokens: u32 = 0;

    for (lines) |line| {
        if (line.len == 0) {
            continue;
        }

        var maybe_captures = try button_regex.captures(line);
        if (maybe_captures) |*captures| {
            defer captures.deinit();

            const letter = captures.sliceAt(1).?;
            const x_str = captures.sliceAt(2).?;
            const y_str = captures.sliceAt(3).?;
            const x = try std.fmt.parseInt(u32, x_str, 10);
            const y = try std.fmt.parseInt(u32, y_str, 10);

            if (letter[0] == 'A') {
                a_button.x = x;
                a_button.y = y;
            } else {
                b_button.x = x;
                b_button.y = y;
            }
        } else {
            var captures = (try prize_regex.captures(line)).?;
            defer captures.deinit();

            const x_str = captures.sliceAt(1).?;
            const y_str = captures.sliceAt(2).?;
            const x = try std.fmt.parseInt(u32, x_str, 10);
            const y = try std.fmt.parseInt(u32, y_str, 10);

            if (lowestPriceToWin(x, y, a_button, b_button)) |price| {
                total_tokens += price;
            }
        }
    }

    std.debug.print("{d}", .{total_tokens});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn lowestPriceToWin(prize_x: u32, prize_y: u32, a_button: Button, b_button: Button) ?u32 {
    const max_a_presses = @min(prize_x / a_button.x, prize_y / a_button.y);
    var lowest_price: ?u32 = null;

    var first_a_presses: u32 = undefined;
    var first_b_presses: u32 = undefined;

    for (1..(max_a_presses + 1)) |i| {
        if (i > 100) {
            break;
        }

        const a_presses = @as(u32, @intCast(i));
        const remaining_x = prize_x - a_button.x * a_presses;
        const remaining_y = prize_y - a_button.y * a_presses;

        if (remaining_x % b_button.x != 0) {
            continue;
        }

        const b_presses = remaining_x / b_button.x;
        if (b_presses > 100 or b_presses * b_button.y != remaining_y) {
            continue;
        }

        std.debug.assert(lowest_price == null);

        const price = a_presses * 3 + b_presses;
        if (lowest_price == null or price < lowest_price.?) {
            lowest_price = price;
            first_a_presses = a_presses;
            first_b_presses = b_presses;
        }
    }

    return lowest_price;
}
