immutable uint yield_count = 1000;
immutable uint worker_count = 10;

void fiber_func()
{
    import core.thread : Fiber;

    uint i = yield_count;

    while (--i)
        Fiber.yield();
}

void thread_func()
{
    import core.thread : Thread;

    uint i = yield_count;

    while (--i)
        Thread.yield();
}

void fiber_test()
{
    import core.thread : Fiber;
    import std.datetime.stopwatch : StopWatch;
    import std.stdio : writeln;

    Fiber[worker_count] fib_array;

    foreach (ref f; fib_array)
        f = new Fiber(&fiber_func);

    uint i = yield_count;
    StopWatch sw;

    sw.start();
    bool done;
    do
    {
        done = true;
        foreach (f; fib_array)
        {
            f.call();
            if (f.state() != f.State.TERM)
                done = false;
        }
    }
    while (!done);
    sw.stop();

    writeln("Elapsed time for ", worker_count, " workers times ", yield_count,
            " yield() calls with fibers = ", sw.peek.total!"msecs", "ms");
}

void thread_test()
{
    import core.thread : Thread, thread_joinAll;
    import std.datetime.stopwatch : StopWatch;
    import std.stdio : writeln;

    Thread[worker_count] thread_array;

    foreach (ref t; thread_array)
        t = new Thread(&thread_func);

    StopWatch sw;
    sw.start();
    foreach (t; thread_array)
        t.start();
    thread_joinAll();
    sw.stop();

    writeln("Elapsed time for ", worker_count, " workers times ", yield_count,
            " yield() calls with threads = ", sw.peek.total!"msecs", "ms");
}

int main()
{
    fiber_test();
    thread_test();

    return 0;
}
