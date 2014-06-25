
module image.scaling.bilinear;

import image.view;
import image.color : RGB_8;

/// Implements lazy image resizing using bilinear interpolation.
auto bilinear(V)(in V src, size_t new_w, size_t new_h)
    if (isView!V)
{
    import std.conv : to;
    import std.traits;

    static const struct BilinearAccess
    {
        V src;
        int w, h;

        const double x_ratio, y_ratio;

        auto opIndex(X, Y)(X in_x, Y in_y)
        {
            immutable x_scaled = x_ratio * in_x;
            immutable y_scaled = y_ratio * in_y;

            immutable x = cast(int) x_scaled;
            immutable y = cast(int) y_scaled;

            immutable fx1 = x_scaled - x;
            immutable fy1 = y_scaled - y;
            immutable fx2 = 1.0 - fx1;
            immutable fy2 = 1.0 - fy1;

            immutable wgt1 = cast(int) (fx2 * fy2 * 256.0);
            immutable wgt2 = cast(int) (fx1 * fy2 * 256.0);
            immutable wgt3 = cast(int) (fx2 * fy1 * 256.0);
            immutable wgt4 = cast(int) (fx1 * fy1 * 256.0);

            auto interp(Col)(Col p1, Col p2, Col p3, Col p4) pure @safe nothrow
            {
                return cast(ubyte) ((p1 * wgt1 + p2 * wgt2 + p3 * wgt3 + p4 * wgt4) >> 8);
            }

            const A = src[x, y];
            const B = src[x + 1, y];
            const C = src[x, y + 1];
            const D = src[x + 1, y + 1];

            alias typeof(A) color;

            static if (__traits(compiles, {
                // Instantiate a new instance
                color(A.r, A.g, A.b);
            }) || is(color : RGB) || is(color : RGBA) || is(color : RGB_8))
            {
                return color(
                    interp(A.r, B.r, C.r, D.r)
                  , interp(A.g, B.g, C.g, D.g)
                  , interp(A.b, B.b, C.b, D.b)
                );
            }
            else static if(isIntegral!color)
            {
                return interp(A, B, C, D);
            }
            else
                static assert(0, "Unsupported color format.");
        }
    }

    const x_ratio = (src.w - 1.0) / new_w;
    const y_ratio = (src.h - 1.0) / new_h;

    return BilinearAccess(src, new_w, new_h, x_ratio, y_ratio);
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

