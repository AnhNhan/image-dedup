
module image.view;

public import ae.utils.graphics.color;
public import ae.utils.graphics.image;
public import ae.utils.graphics.view;

/// Implements lazy image resizing using bilinear interpolation.
auto greyscale(V)(in V src)
    if (isView!V)
{
    static const struct Greyscale
    {
        V src;

        @property auto w() { return src.w; }
        @property auto h() { return src.h; }

        auto opIndex(int in_x, int in_y)
        {
            const orig = src[in_x, in_y];
            alias typeof(orig) color;

            static if (__traits(compiles, orig.r, orig.g, orig.b, color(0, 0, 0)))
            {
                const c = cast(typeof(orig.r)) ((orig.r + orig.g + orig.b) / 3);
                return color(c, c, c);
            }
            else static if(isIntegral!color)
            {
                return orig;
            }
            else
                static assert(0, "Unsupported color format: " ~ color.stringof);
        }
    }

    return Greyscale(src);
}

unittest {
    static assert(isView!(typeof(greyscale(onePixel(42)))));
    static assert(isView!(typeof(greyscale(onePixel(RGB(10, 20, 30))))));
}
