class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.9.0/librtmp2-0.9.0-src.tar.gz"
  sha256 "fadefc43d890f16b02210b8081c1c324f016fd6bcfa7b57ad60f13217060b04b"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.9.0"
    sha256 cellar: :any, arm64_golden_gate: "81d003fb52fed9a39f9e178d1a521a6c4a310841090800b098e18bb57a8a2adc"
    sha256 cellar: :any, arm64_tahoe:       "7252703e876360a9d6a3332212bb0cfe0b97e4bc0818242977ad61c2553b798e"
    sha256 cellar: :any, arm64_sequoia:     "3d3f31b53dd84b89804525398cbc7a0afddd303007f94cd8dcd0aa0b54c752b5"
    sha256 cellar: :any, tahoe:             "65bd799ff9dc2d396b777ffa8feeb4a4518884a7f785de6146363b30e1cbea14"
    sha256 cellar: :any, sequoia:           "226aa7b1940dafbfc53746df9be80cf2d17354b55c9be52b13f34a9ec5e96780"
  end

  depends_on "cbindgen" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  def install
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    # The release source tarball ships no Cargo.lock (Rust library crates
    # don't commit one), so --locked would abort instead of resolving it.
    system "cargo", "build", "--release"

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
