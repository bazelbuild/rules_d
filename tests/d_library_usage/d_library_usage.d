int main()
{
    import simple_library : plusOne;

    int x = 1;
    int y = plusOne(x);
    assert(y == x + 1);

    return 0;
}
