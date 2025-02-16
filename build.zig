const std = @import("std");

const MAX_DAY = 23;

pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Add utilities module to the project
    const util_modules = b.addModule("util", .{
        .root_source_file = b.path("src/util.zig"),
        .target = target,
        .optimize = optimize,
    });

    const regex_lib = b.dependency("regex", .{
        .target = target,
        .optimize = optimize,
    });

    // For each day and each part, add an executable built from the corresponding source file
    inline for (1..MAX_DAY + 1) |day| {
        inline for (1..3) |part| {
            const day_str = try std.fmt.allocPrint(b.allocator, "day{d:0>2}", .{day});
            const part_str = try std.fmt.allocPrint(b.allocator, "part{d}", .{part});
            const name = try std.fmt.allocPrint(b.allocator, "{s}_{s}", .{ day_str, part_str });

            const exe = b.addExecutable(.{
                .name = name,
                .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "src/{s}/{s}.zig", .{ day_str, part_str })),
                .target = target,
                .optimize = optimize,
            });

            exe.root_module.addImport("util", util_modules);
            exe.root_module.addImport("regex", regex_lib.module("regex"));

            b.installArtifact(exe);

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());

            const run_step = b.step(name, try std.fmt.allocPrint(b.allocator, "Run solution for day {d} part {d}", .{ day, part }));
            run_step.dependOn(&run_cmd.step);
        }
    }
}
