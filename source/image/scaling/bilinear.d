
module image.scaling.bilinear;

import image.view;
import image.color : RGB_8;

/// Implements lazy image resizing using bilinear interpolation.
auto bilinear(V)(V src, size_t new_w, size_t new_h)
    if (isView!V)
{
    import std.conv : to;
    import std.traits;

    static struct BilinearAccess
    {
        V src;
        int w, h;

        const double x_ratio, y_ratio;

        auto opIndex(X, Y)(X in_x, Y in_y)
        {
            const x = (x_ratio * in_x).to!int;
            const y = (y_ratio * in_y).to!int;
            const x_diff = (x_ratio * in_x) - x;
            const y_diff = (y_ratio * in_y) - y;

            const A = src[x, y];
            const B = src[x, y + 1];
            const C = src[x + 1, y];
            const D = src[x + 1, y + 1];

            alias typeof(A) color;

            static if (__traits(compiles, {
                // Instantiate a new instance
                color(A.r, A.g, A.b);
            }) || is(color : RGB) || is(color : RGBA) || is(color : RGB_8))
            {
                alias typeof(color.r) ret;
                return color(
                    interp!ret(A.r, B.r, C.r, D.r, x_diff, y_diff)
                  , interp!ret(A.g, B.g, C.g, D.g, x_diff, y_diff)
                  , interp!ret(A.b, B.b, C.b, D.b, x_diff, y_diff)
                );
            }
            else static if(isIntegral!color)
            {
                return interp!color(A, B, C, D, x_diff, y_diff);
            }
            else
                static assert(0, "Unsupported color format.");
        }
    }

    const x_ratio = (src.w - 1.0) / new_w;
    const y_ratio = (src.h - 1.0) / new_h;

    return BilinearAccess(src, new_w, new_h, x_ratio, y_ratio);
}

private Ret interp(Ret, A, B, C, D, W, H)(A a, B b, C c, D d, W w, H h) pure @safe nothrow
{
    // Y = A(1-w)(1-h) + B(w)(1-h) + C(h)(1-w) + Dwh
    return cast(Ret) (a * (1 - w) * (1 - h) + b * w * (1 - h) + c * h * (1 - w) + d * w * h);
}

unittest {
    import image.dummy;
    import std.stdio;

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

    auto img_upscaled = Img!ubyte([
        [1, 1, 2, 2]
      , [1, 1, 2, 2]
      , [1, 2, 2, 3]
      , [1, 2, 2, 3]
    ]);

    auto processed = img_2x2.bilinear(4, 4);
    ubyte[][] derp;

    foreach (x; 0..4)
    {
        ubyte[] not_so_deep;
        foreach (y; 0..4)
        {
            not_so_deep ~= processed[x, y];
        }
        derp ~= not_so_deep;
    }
    auto processed_img = Img!ubyte(derp);
}

