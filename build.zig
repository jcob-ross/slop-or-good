const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("slop_or_good", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const names = [_][]const u8{ "good", "slop", "note" };
    const run_step = b.step("run", "Run the good app");
    var good_root_module: *std.Build.Module = undefined;

    for (names) |name| {
        const root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "slop_or_good", .module = mod },
            },
        });

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = root_module,
        });
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.addPassthruArgs();

        const named_run_step = b.step(
            b.fmt("run-{s}", .{name}),
            b.fmt("Run the {s} app", .{name}),
        );
        named_run_step.dependOn(&run_cmd.step);

        if (std.mem.eql(u8, name, "good")) {
            good_root_module = root_module;
            run_step.dependOn(&run_cmd.step);
        }
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = good_root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
