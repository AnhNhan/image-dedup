
module image.scaling.nearest_neighbour;

import image.view;

import std.math : floor;

auto nearest_neighbour(V)(V src, size_t new_w, size_t new_h)
    if (isWritableView!V && is(typeof(V(1, 1))))
{
    auto w_ratio = src.w / cast(float) new_w;
    auto h_ratio = src.h / cast(float) new_h;
    size_t pw, ph;

    auto dst = V(new_w, new_h);

    foreach (w; 0..new_w)
    {
        foreach (h; 0..new_h)
        {
            pw = cast(size_t) (w * w_ratio).floor;
            ph = cast(size_t) (h * h_ratio).floor;
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
