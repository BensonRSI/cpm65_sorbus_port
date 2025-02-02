from build.ab import export
from build.pkg import package

package(name="libreadline", package="readline")
package(name="libfmt", package="fmt")

export(
    name="all",
    items={
        "bin/cpmemu": "tools/cpmemu",
        "bin/mads": "third_party/mads",
        "bin/atbasic.com": "third_party/altirrabasic",
        "bbcmicro.ssd": "src/arch/bbcmicro+diskimage",
        "oric.dsk": "src/arch/oric+diskimage",
        "apple2e.po": "src/arch/apple2e+diskimage",
        "atari800.atr": "src/arch/atari800+atari800_diskimage",
        "atari800hd.atr": "src/arch/atari800+atari800hd_diskimage",
        "atari800xlhd.atr": "src/arch/atari800+atari800xlhd_diskimage",
        "c64.d64": "src/arch/commodore+c64_diskimage",
        "pet4032.d64": "src/arch/commodore+pet4032_diskimage",
        "pet8032.d64": "src/arch/commodore+pet8032_diskimage",
        "pet8096.d64": "src/arch/commodore+pet8096_diskimage",
        "vic20.d64": "src/arch/commodore+vic20_diskimage",
        "x16.zip": "src/arch/x16+diskimage",
    },
)
