import simple_c_library.simple_library_wrapper;

int main()
{
    int x = 1;
    int y;

    y = plus_one(x);
    assert(y == x + 1);

    return 0;
}
