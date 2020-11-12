const std = @import("std");
const builtin = std.builtin;
const warn = std.debug.warn;
const assertEqual = std.testing.expectEqual;

pub fn ctreduce(
    comptime func: anytype, 
    comptime iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.return_type.? 
) @typeInfo(@TypeOf(func)).Fn.return_type.? {
    comptime var ans = init;
    inline for (iterable) | item | {
        ans = func(ans, item);
    }
    return ans;
}

fn add8(a: u8, b: u8) u8 { 
    return a + b; 
}
fn mul8(a: u8, b: u8) u8 { 
    return a * b; 
}

test "Reduce" {
    comptime {
        comptime var A = [_]u8{1, 2, 4};
        assertEqual(ctreduce(add8, &A, 0), 7);
        assertEqual(ctreduce(mul8, &A, 0), 0);
        assertEqual(ctreduce(mul8, &A, 1), 8);
    }
    warn("\r\n", .{});
}


pub fn CTIterator(comptime T: type) type {
    return struct {
        iterable: []const T,
        index: usize = 0,
        len: usize,

        const Self = @This();

        fn incr(it: *Self) void {
            it.index += 1;
        }

        pub fn next(it: *Self) ?*const T {
            if(it.index < it.len) {
                defer it.incr();
                return &it.iterable[it.index];
            }
            return null;
        }

        pub fn init(iter: []const T) Self {
            return Self{
                .iterable = iter,
                .len = iter.len
            };
        }
    };
}

fn printTest(comptime T: type, comptime iter: *CTIterator(T), comptime ans: []T) void{
    comptime var i: usize = 0;
    inline while (iter.next()) | item | {
        // warn("\r\n ans: {} item: {} ", .{ans[i], item.*});
        assertEqual(ans[i], item.*);
        i += 1;
    }
}

test "Iterator" {
    comptime {
        comptime var A = [_]u8{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
        comptime var iter = CTIterator(u8).init(&A);
        printTest(u8, &iter, &A);
    }
    warn("\r\n", .{});

}

pub fn ctmap(
    comptime func: anytype, 
    comptime iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) CTIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    comptime var rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    comptime var ans: []const rtype  = &[0]rtype{};
    
    inline for(iterable) | item, i | {
        ans = ans ++ &[1]rtype{ func(item) };
    }

    return CTIterator(rtype).init(ans);
}

fn addOne(comptime a: u8) u8 {
    return a + @intCast(u8, 1);
}

test "Map" {
    comptime {
        comptime var A = [_]u8{'a', 'b', 'c'};
        comptime var ans = [_]u8{'b', 'c', 'd'};
        comptime var res = ctmap(addOne, &A);
        printTest(u8, &res, &ans);
    }
    warn("\r\n", .{});
}

pub fn ctfilter(
    comptime func: anytype, 
    comptime iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) CTIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    comptime var rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    comptime var ans: []const rtype  = &[0]rtype{};
    
    inline for(iterable) | item, i | {
        if (func(item) == true) {
            ans = ans ++ &[1]rtype{ item };
        }
    }

    return CTIterator(rtype).init(ans);
}

fn isLessThan10(a: u8) bool {
    if ( a < 10 ){
        return true;
    }
    return false;
}

test "Filter" {
    comptime {
        comptime var A = [_]u8{1, 'a', 2, 'b', 3, 'c', 'd', 'e'};
        comptime var ans = [_]u8{1, 2, 3};
        comptime var res = ctfilter(isLessThan10, &A);
        printTest(u8, &res, &ans);
    }
    warn("\r\n", .{});
}

fn mul32 (comptime a: u32, comptime b: u32) u32 {
    return a * b;
}

pub fn starmap(
    comptime func: anytype, 
    comptime iterables: []const []const @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) CTIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const N: usize =  iterables.len;
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    comptime var ans: []const rtype  = &[0]rtype{};

    comptime var i: usize = 0;
    comptime var args = .{};
    inline while ( i < N ) : ( i += 1 ) {
        var a = @call(.{}, mul32,  .{1, 2} );
        ans = ans ++ &[1]rtype{ a  };
    }

    return CTIterator(rtype).init(ans);
}

// test "Starmap" {
//     comptime {
//         comptime var A = &[_][]const u32{ 
//             &[_]u32{1, 2}, 
//             &[_]u32{3, 4}
//         };
//         comptime var ans = [_]u32{2, 12};

//         comptime var res = starmap(mul32, A);
//         defer res.deinit();

//         //printTest(u32, &res, &ans);
//     }

//     warn("\r\n", .{});
// }