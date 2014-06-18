
module image.scaling.nearest_neighbour;

import image.view;

pure:
@safe:
nothrow:

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

unittest {
    import image.dummy;

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
