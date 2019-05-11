extern (C) int plus_one(int x);

int main()
{
    int x = 1;
    int y;

    y = plus_one(x);
    assert(y == x + 1);

    return 0;
}
