const std = @import("std");
const tallocator = std.testing.allocator;
const warn = std.debug.warn;
const assertEqual = std.testing.expectEqual;

pub fn reduce(
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.return_type.? 
) @typeInfo(@TypeOf(func)).Fn.return_type.? {
    var ans = init;
    for (iterable) | item | {
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
    var A = [_]u8{1, 2, 4};
    assertEqual(reduce(add8, &A, 0), 7);
    assertEqual(reduce(mul8, &A, 0), 0);
    assertEqual(reduce(mul8, &A, 1), 8);
    warn("\r\n", .{});
}


pub fn Iterator(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,
        iterable: []T,
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

        pub fn init(alloc: *std.mem.Allocator, iter: []T) Self {
            var temp: []T = alloc.dupe(T, iter) catch unreachable;
            return Self{
                .allocator = alloc,
                .iterable = temp,
                .len = iter.len
            };
        }

        pub fn deinit(it: *Self) void {
            it.allocator.free(it.iterable);
        }
    };
}

fn printTest(comptime T: type, iter: *Iterator(T), ans: []T) void{
    var i: usize = 0;
    while (iter.next()) | item | {
        // warn("\r\n ans: {} item: {} ", .{ans[i], item.*});
        assertEqual(ans[i], item.*);
        i += 1;
    }
}

test "Iterator" {

    var A: []u8 = tallocator.alloc(u8, 10) catch unreachable;
    defer tallocator.destroy(A.ptr);

    var i: u8 = 0;
    while ( i < 10 ) : ( i += 1 ) {
        A[i] = i;
    } 
    var iter = Iterator(u8).init(tallocator, A);
    defer iter.deinit();

    printTest(u8, &iter, A);

    var B = std.ArrayList(u8).init(tallocator);
    defer B.deinit();

    i =  0;
    while ( i < 10 ) : ( i += 1 ) {
        _ = try B.append(i*2);
    } 
    var iter2 = Iterator(u8).init(tallocator, B.items);
    defer iter2.deinit();

    printTest(u8, &iter2, B.items);
    warn("\r\n", .{});

}

pub fn map(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const RType = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []RType  = allocat.alloc(RType, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    for (ans) | _, i | { ans[i] = 0;}
    
    for(iterable) | item, i | {
        ans[i] =  func(item);
    }

    return Iterator(RType).init(allocat, ans);
}

fn addOne(a: u8) u8 {
    return a + @intCast(u8, 1);
}

test "Map" {
    var A = [_]u8{'a', 'b', 'c'};
    var ans = [_]u8{'b', 'c', 'd'};

    var res = map(tallocator, addOne, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

pub fn filter(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const RType = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []RType  = allocat.alloc(RType, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    for (ans) | _, i | { ans[i] = 0;}
    
    var j: usize = 0;
    for (iterable) | item, i | {
        if (func(item) == true) {
            ans[j] = item;
            j += 1;
        }
    }

    _ = allocat.shrink(ans, j);
    ans.len = j;

    return Iterator(RType).init(allocat, ans);
}

fn isLessThan10(a: u8) bool {
    if ( a < 10 ){
        return true;
    }
    return false;
}

test "Filter" {
    var A = [_]u8{1, 'a', 2, 'b', 3, 'c', 'd', 'e'};
    var ans = [_]u8{1, 2, 3, 0, 0, 0, 0, 0};

    var res = filter(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

pub fn accumulate(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.return_type.?) {
    const RType = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    var ans: []RType  = allocat.alloc(RType, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    for (ans) | _, i | { ans[i] = 0;}
    
    var i: usize = 0;
    ans[0] = func(init, iterable[0]);
    i += 1;
    while (i < iterable.len) : ( i += 1 ) {
        ans[i] =  func(ans[i-1], iterable[i]);
    }

    return Iterator(RType).init(allocat, ans);
}

fn add(a: u32, b:u32) u32 {
    return a + b;
}

fn mul(a:u32, b:u32) u32 {
    return a * b;
}

test "Accumulate" {
    var A = [_]u32{1, 2, 4};
    var ans1 = [_]u32{1, 3, 7};
    var ans2 = [_]u32{0, 0, 0};
    var ans3 = [_]u32{1, 2, 8};

    var res = accumulate(tallocator, add, &A, 0);
    defer res.deinit();

    var res2 = accumulate(tallocator, mul, &A, 0);
    defer res2.deinit();

    var res3 = accumulate(tallocator, mul, &A, 1);
    defer res3.deinit();

    printTest(u32, &res, &ans1);
    printTest(u32, &res2, &ans2);
    printTest(u32, &res3, &ans3);
    warn("\r\n", .{});
}
