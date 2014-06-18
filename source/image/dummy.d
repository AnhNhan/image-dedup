
module image.dummy;

// This is just for testing
version(unittest)
struct Img(T)
{
    T[][] src;
    this(T[][] _src)
    {
        src = _src;
    }
    this(size_t w, size_t h)
    {
        src.length = w;
        foreach (ref r; src)
            r.length = h;
    }
    @property size_t w()
    {
        return src.length;
    }
    @property size_t h()
    {
        return src[0].length;
    }
    ref T opIndex(size_t w, size_t h)
    {
        return src[w][h];
    }
    T opIndexAssign(T value, size_t w, size_t h)
    {
        return src[w][h] = value;
    }
}

unittest
{
    import image.view;
    static assert(isWritableView!(Img!ubyte));
}
