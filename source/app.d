
import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.parallelism;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import image.dhash;
import image.scaling.bilinear;
import image.stb;
import image.view;

auto generate_dhash_for_file(string path)
{
    assert(exists(path));
    assert(isFile(path));

    path.writeln;
    auto hash = stb_load_ae(path).generate_dhash;
    return tuple(path, hash);
}

auto group(T)(T hashes)
    if (isTuple!(ElementType!T))
{
    ElementType!T[][typeof(ElementType!T.init[1])] groups;
    // Init, kinda hash uniqization
    foreach (const hash; hashes.map!"a[1]")
    {
        groups[hash] = [];
    }

    foreach (const key; groups.keys)
    {
        foreach (tup; hashes)
        {
            if (tup[1].bcmp(key))
            {
                groups[key] ~= tup;
            }
        }
    }

    ElementType!(typeof(groups.keys))[] keys_for_removal;
    foreach (key, val; groups)
    {
        if (val.length <= 1)
        {
            keys_for_removal ~= key;
        }
    }
    foreach (key; keys_for_removal)
    {
        groups.remove(key);
    }

    return groups;
}

bool bcmp(size_t diff = 2, T, U)(T lhs, U rhs)
{
    return (lhs ^ rhs).set_bits <= diff;
}

unittest
{
    assert( bcmp(0x00, 0x00));
    assert( bcmp(0x00, 0x01));
    assert( bcmp(0x00, 0x02));
    assert( bcmp(0x20, 0x02));
    assert( bcmp(0x00, 0x05));

    assert(!bcmp(0x20, 0x07));
    assert(!bcmp(0x20, 0x03));
}

auto to_bit_string(string pos = "1", string neg = "0")(ulong num)
{
    auto app = appender!(char[]);
    foreach (n; 0..64)
    {
        app.put((num & (1 << n)) ? pos : neg);
    }
    return app.data;
}

auto set_bits(in ulong num)
{
    size_t ret;
    foreach (n; 0..64)
    {
        if (num & (1 << n))
        {
            ++ret;
        }
    }

    // TODO: WTF?
    if (ret > 0)
    {
        ret = ret / 2;
    }
    return ret;
}

unittest
{
    assert(set_bits(0x00) == 0);
    assert(set_bits(0x01) == 1);
    assert(set_bits(0x7F) == 7);
    assert(set_bits(0xFF) == 8);
}

void print_dhash_of_file(string filename)
{
    stb_load_ae(filename).generate_dhash.to_bit_string.writeln;
}

void scan_for_progressive_jpegs(string dir_path)
{
    assert(exists(dir_path), dir_path ~ " does not exist!");
    assert(isDir(dir_path), dir_path ~ " is not a directory!");

    auto img_files = dirEntries(dir_path, "*.{png,jpg}", SpanMode.depth).array;

    if (img_files.empty)
    {
        "No files to be analyzed. Done.".writeln;
        return;
    }

    auto poolInstance = new TaskPool(totalCPUs);
    scope(exit) poolInstance.stop();

    static auto hi(string path)
    {
        import stb_image;
        int x, y, comp;
        ubyte* loaded = stbi_load(path.toStringz(), &x, &y, &comp, 0);
        if (loaded is null && to!string(stbi_failure_reason()) == "progressive jpeg")
        {
            return path;
        }
        else if (loaded is null)
        {
            return path ~ " - " ~ to!string(stbi_failure_reason());
        }
        stbi_image_free(loaded);
        return "";
    }

    poolInstance.amap!hi(img_files).filter!"!a.empty".join("\n").write;
}

void scan_for_duplicates(string dir_path)
{
    assert(exists(dir_path), dir_path ~ " does not exist!");
    assert(isDir(dir_path), dir_path ~ " is not a directory!");

    auto img_files = dirEntries(dir_path, "*.{png,jpg}", SpanMode.depth).array;

    if (img_files.empty)
    {
        "No files to be analyzed. Done.".writeln;
        return;
    }

    writeln("Analyzing ", img_files.length, " files.\n");

    auto cpu_count = totalCPUs - 1;

    writeln("Used CPUs: ", cpu_count);
    auto poolInstance = new TaskPool(cpu_count);
    scope(exit) poolInstance.stop();

    StopWatch sw;

    sw.start();

    auto hashes = poolInstance.map!generate_dhash_for_file(img_files).array;

    sw.stop();

    writeln("\nDone.\n\nTook me ", sw.peek.seconds, "s.\n");

    auto groups = hashes.group;

    groups.values.map!(
        t => t.map!(
            u => u[1].to_bit_string!("+", "-") ~ " - " ~ u[0]
        ).join("\n")
    ).join("\n\n - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n\n").writeln;
}

int main(string[] args) {
    args.popFront();

    if (args.empty)
    {
        "Error. First argument should be a command.".writeln;
        return 1;
    }

    auto cmd = args.front;
    args.popFront();

    switch (cmd)
    {
        case "dhash":
            args.front.print_dhash_of_file;
            break;
        case "scan":
            args.front.scan_for_duplicates;
            break;
        case "scan-progressive-jpeg":
            args.front.scan_for_progressive_jpegs;
            break;
        default:
            break;
    }

    return 0;
}
