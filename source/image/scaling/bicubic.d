
module image.scaling.bicubic;

double cubicInterpolate(T)(in T[4] p, in double x) {
    return p[1] + 0.5 * x*(p[2] - p[0] + x*(2.0*p[0] - 5.0*p[1] + 4.0*p[2] - p[3] + x*(3.0*(p[1] - p[2]) + p[3] - p[0])));
}

T bicubicInterpolate(T)(in T[4][4] p, in double x, in double y) {
    double arr[4];
    arr[0] = cubicInterpolate(p[0], y);
    arr[1] = cubicInterpolate(p[1], y);
    arr[2] = cubicInterpolate(p[2], y);
    arr[3] = cubicInterpolate(p[3], y);
    return cast(T) cubicInterpolate(arr, x);
}

unittest {
    import std.math;
    double[4][4] p = [[1,3,3,4], [7,2,3,4], [1,6,3,6], [2,5,7,2]];
    int[4][4]    q = [[1,3,3,4], [7,2,3,4], [1,6,3,6], [2,5,7,2]];

    auto v1 = bicubicInterpolate(p, 0.1, 0.2);
    assert(v1.approxEqual(2.02059));

    auto v2 = bicubicInterpolate(q, 0.1, 0.2);
    assert(v2 == 2);
}
