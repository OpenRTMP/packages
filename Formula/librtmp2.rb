class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.13.0/librtmp2-0.13.0-src.tar.gz"
  sha256 "e368b94f35a87337c4c9df7c414e58c3ff96d025679cc9917253ac114a102dd0"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.13.0"
    sha256 cellar: :any, arm64_golden_gate: "a32af54e5a5019c1dea0260a20776d8fc14217c5f35126b653c2ad4b880a4d39"
    sha256 cellar: :any, arm64_tahoe:       "e1ca5949d3ce4909ba5c89880cdecc3a75dbd1f137f841c4428316a35cefc03d"
    sha256 cellar: :any, arm64_sequoia:     "c4c6bc7ae2dbb47f533ac02daf4808fed04a1787b43a0c41fac1f8b0614e004f"
    sha256 cellar: :any, tahoe:             "51637b006884d65697add081779e655d33bd8389be20cccbb27eb5cc7a49fa09"
    sha256 cellar: :any, sequoia:           "bc066e83e7ed37b0416e77d737fe9ebd4803080ca8b1c46cbb0ebd43c1a39dd9"
  end

  depends_on "cbindgen" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  def install
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    # Releases that ship a Cargo.lock are built with exactly those dependency
    # versions; older source tarballs without one still resolve them.
    locked = File.exist?("Cargo.lock") ? ["--locked"] : []
    system "cargo", "build", "--release", *locked

    unless File.exist?("include/librtmp2/librtmp2.h")
      mkdir_p "include/librtmp2"
      system "cbindgen", "--lang", "c", "--cpp-compat", "--crate", "librtmp2",
             "--output", "include/librtmp2/librtmp2.h"
    end

    include.install "include/librtmp2"
    lib.install "target/release/liblibrtmp2.a"
    lib.install_symlink "liblibrtmp2.a" => "librtmp2.a"

    if OS.mac?
      lib.install "target/release/liblibrtmp2.dylib"
      lib.install_symlink "liblibrtmp2.dylib" => "librtmp2.dylib"
    else
      lib.install "target/release/liblibrtmp2.so"
      lib.install_symlink "liblibrtmp2.so" => "librtmp2.so"
    end

    (lib/"pkgconfig").mkpath
    (lib/"pkgconfig/librtmp2.pc").write <<~EOS
      prefix=#{prefix}
      exec_prefix=${prefix}
      libdir=#{lib}
      includedir=#{include}

      Name: librtmp2
      Description: RTMP and RTMPS protocol library
      Version: #{version}
      Requires.private: openssl
      Libs: -L${libdir} -lrtmp2
      Cflags: -I${includedir}/librtmp2
    EOS
  end

  test do
    assert_predicate include/"librtmp2/librtmp2.h", :exist?
    assert_predicate lib/"librtmp2.a", :exist?
  end
end
