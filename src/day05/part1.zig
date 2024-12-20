const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ordersAndLists = try util.readInputFileLines(OrderOrList, allocator, "day05.txt", parseLine);
    defer allocator.free(ordersAndLists);
    defer {
        for (ordersAndLists) |orderOrList| {
            switch (orderOrList) {
                .list => |list| allocator.free(list),
                else => {},
            }
        }
    }

    // Map from a page number to the set of all pages numbers that must come before it
    var pages_that_must_come_before = std.AutoHashMap(u8, std.AutoHashMap(u8, void)).init(allocator);
    defer pages_that_must_come_before.deinit();
    defer {
        var iter = pages_that_must_come_before.valueIterator();
        while (iter.next()) |page_set| {
            page_set.deinit();
        }
    }

    var valid_middle_sum: u16 = 0;

    for (ordersAndLists) |orderOrList| {
        switch (orderOrList) {
            .order => |order| {
                const maybe_pages = pages_that_must_come_before.getPtr(order.second);
                if (maybe_pages != null) {
                    try maybe_pages.?.put(order.first, {});
                } else {
                    var pages = std.AutoHashMap(u8, void).init(allocator);
                    try pages.put(order.first, {});
                    try pages_that_must_come_before.put(order.second, pages);
                }
            },
            .list => |list| {
                var is_valid = true;

                outer: for (list, 0..) |first_page, first_page_idx| {
                    const maybe_pages_before = pages_that_must_come_before.getPtr(first_page);
                    var j = first_page_idx + 1;
                    while (j < list.len) : (j += 1) {
                        if (maybe_pages_before != null and maybe_pages_before.?.contains(list[j])) {
                            is_valid = false;
                            break :outer;
                        }
                    }
                }

                if (is_valid) {
                    const middle = list[list.len / 2];
                    // std.debug.print("{any} is valid, middle: {d}\n", .{ list, middle });
                    valid_middle_sum += middle;
                }
            },
        }
    }

    std.debug.print("{d}", .{valid_middle_sum});
}

const OrderOrListTag = enum { order, list };

const OrderOrList = union(OrderOrListTag) {
    order: struct { first: u8, second: u8 },
    list: []u8,
};

fn parseLine(allocator: std.mem.Allocator, line: []const u8) !OrderOrList {
    // XX|YY
    if (std.mem.containsAtLeast(u8, line, 1, "|")) {
        var iter = std.mem.tokenizeScalar(u8, line, '|');
        const first = try std.fmt.parseInt(u8, iter.next().?, 10);
        const second = try std.fmt.parseInt(u8, iter.next().?, 10);
        return .{ .order = .{ .first = first, .second = second } };
    }

    // XX,YY,ZZ
    var iter = std.mem.tokenizeScalar(u8, line, ',');

    var nums = std.ArrayList(u8).init(allocator);
    defer nums.deinit();

    while (iter.next()) |num_string| {
        const num = try std.fmt.parseInt(u8, num_string, 10);
        try nums.append(num);
    }

    return .{ .list = try allocator.dupe(u8, nums.items) };
}
