{ stdenv, fetchurl, zlib, libX11, libXext, libSM, libICE, libXt
, freetype, fontconfig, libXft, libXrender, libxcb, expat, libXau, libXdmcp
, libuuid, cups, xz
, gstreamer, gst_plugins_base, libxml2
, gtkSupport ? true, glib, gtk, pango, gdk_pixbuf, cairo, atk
, kdeSupport ? false, qt4, kdelibs
}:

assert stdenv.isLinux && stdenv.gcc.gcc != null && stdenv.gcc.libc != null;

let
  mirror = http://get.geo.opera.com/pub/opera;
in

stdenv.mkDerivation rec {
  name = "opera-12.11-1661";

  src =
    if stdenv.system == "i686-linux" then
      fetchurl {
        url = "${mirror}/linux/1211/${name}.i386.linux.tar.xz";
        sha256 = "0ax2kcnl0hb7fz56c9gcjia3dnwabxl2mq2hvszmbky4i399jlkk";
      }
    else if stdenv.system == "x86_64-linux" then
      fetchurl {
        url = "${mirror}/linux/1211/${name}.x86_64.linux.tar.xz";
        sha256 = "1pnad4kdasrmm27kg6frldipyzcfy1y610rasbqic9frzb9q8dbp";
      }
    else throw "Opera is not supported on ${stdenv.system} (only i686-linux and x86_64 linux are supported)";

  dontStrip = 1;

  phases = "unpackPhase installPhase fixupPhase";

  installPhase = ''
    ./install --unattended --prefix $out
    '';

  buildInputs =
    [ stdenv.gcc.gcc stdenv.gcc.libc zlib libX11 libXt libXext libSM libICE
      libXft freetype fontconfig libXrender libuuid expat
      gstreamer libxml2 gst_plugins_base
    ]
    ++ stdenv.lib.optionals gtkSupport [ glib gtk pango gdk_pixbuf cairo atk ]
    ++ stdenv.lib.optionals kdeSupport [ kdelibs qt4 ];

  libPath = stdenv.lib.makeLibraryPath buildInputs
    + stdenv.lib.optionalString (stdenv.system == "x86_64-linux")
      (":" + stdenv.lib.makeSearchPath "lib64" buildInputs);

  preFixup =
    ''
    find $out/lib/opera -type f | while read f; do
      type=$(readelf -h "$f" 2>/dev/null | grep 'Type:' | sed -e 's/ *Type: *\([A-Z]*\) (.*/\1/')
      if [ -z "$type" ]; then
        :
      elif [ $type == "EXEC" ]; then
        echo "patching $f executable <<"
        patchelf \
            --set-interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
            --set-rpath "${libPath}" \
            "$f"
      elif [ $type == "DYN" ]; then
        echo "patching $f library <<"
        patchelf --set-rpath "${libPath}" "$f"
      else
        echo "Unknown type $type"
        exit 1
      fi
    done
    '';

  postFixup = ''
    oldRPATH=`patchelf --print-rpath $out/lib/opera/opera`
    patchelf --set-rpath $oldRPATH:${cups}/lib $out/lib/opera/opera
    '';

  meta = {
    homepage = http://www.opera.com;
    description = "The Opera web browser";
  };
}
