
module image.scaling.nearest_neighbour;

import image.view;

auto nearest_neighbour(V)(V src, size_t new_w, size_t new_h)
    if (isWritableView!V && is(typeof(V(1, 1))))
{
    auto w_ratio = (src.w << 16) / new_w + 1;
    auto h_ratio = (src.h << 16) / new_h + 1;
    size_t pw, ph;

    auto dst = V(new_w, new_h);

    foreach (w; 0..new_w)
    {
        foreach (h; 0..new_h)
        {
            pw = (w * w_ratio) >> 16;
            ph = (h * h_ratio) >> 16;
            dst[w, h] = src[pw, ph];
        }
    }

    return dst;
}

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

unittest {
    static assert(isWritableView!(Img!ubyte));

    auto img_2x2 = Img!ubyte([
        [1, 2],
        [3, 4],
    ]);

    auto img_4x4 = Img!ubyte([
        [1, 1, 2, 2],
        [1, 1, 2, 2],
        [3, 3, 4, 4],
        [3, 3, 4, 4],
    ]);

    assert(img_2x2.nearest_neighbour(4, 4) == img_4x4);
    assert(img_4x4.nearest_neighbour(2, 2) == img_2x2);
}
