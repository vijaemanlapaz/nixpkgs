{ stdenv, fetchurl, zlib, ncurses, readline }:

let version = "8.3.21"; in

stdenv.mkDerivation rec {
  name = "postgresql-${version}";

  src = fetchurl {
    url = "mirror://postgresql/source/v${version}/${name}.tar.bz2";
    sha256 = "1y1lw83jr3v91920xdhd4ypaa5iazmdh4snl5qzq0yq6z3lnsjx6";
  };

  buildInputs = [ zlib ncurses readline ];

  LC_ALL = "en_US";

  passthru = { inherit readline; };

  meta = {
    homepage = http://www.postgresql.org/;
    description = "A powerful, open source object-relational database system";
    license = "bsd";
  };
}
