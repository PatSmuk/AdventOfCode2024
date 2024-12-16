const std = @import("std");

const days = [_][]const u8{
    "day01",
};

const parts = [_][]const u8{ "part1", "part2" };

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

    const util_modules = b.addModule("util", .{
        .root_source_file = b.path("src/util.zig"),
    });
    _ = util_modules; // autofix

    inline for (days) |day| {
        inline for (parts) |part| {
            const exe = b.addExecutable(.{
                .name = day ++ "_" ++ part,
                .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "src/{s}/{s}.zig", .{ day, part })),
                .target = target,
                .optimize = optimize,
            });

            exe.root_module.addImport("util", b.modules.get("util").?);

            b.installArtifact(exe);

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());

            const run_step = b.step(day ++ "_" ++ part, "Run " ++ day ++ "_" ++ part);
            run_step.dependOn(&run_cmd.step);
        }
    }
}
