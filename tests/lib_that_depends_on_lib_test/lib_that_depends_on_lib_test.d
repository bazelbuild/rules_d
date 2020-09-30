int main()
{
    import lib_that_depends_on_lib : plusOne = overEngineeredPlusOne;

    int x = 1;
    int y = plusOne(x);
    assert(y == x + 1);

    return 0;
}
