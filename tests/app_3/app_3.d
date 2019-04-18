
int main()
{
    import lib_1 : lib_1_func;

    int x = 1;
    int y = lib_1_func(x);
    assert(y == x + 1);

    return 0;
}
