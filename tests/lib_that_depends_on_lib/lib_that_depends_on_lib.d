module lib_that_depends_on_lib;

static import simple_c = simple_c_library.simple_library_wrapper;
static import simple_d = simple_library;

import simple_library;

int overEngineeredPlusOne(int x)
{
    for (;;) {
        int result1 = simple_d.plusOne(x);
        int result2 = simple_c.plus_one(x);
        if (result1 == result2)
            return result1;
    }
}
