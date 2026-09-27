class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.10.1/librtmp2-0.10.1-src.tar.gz"
  sha256 "faf4906bb30e172158d23ee9bdc565c3d6ad8114e5d701b442d3ecf9e4cefb59"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.10.1"
    sha256 cellar: :any, arm64_golden_gate: "5b68ca162004db32f129371dce564e9102f3f1dfc2136d165a08a156f655d7b3"
    sha256 cellar: :any, arm64_tahoe:       "98fabe11dac2ed96ce66df2fb37943c9c1c26ba5125278da50a242e8a75fda90"
    sha256 cellar: :any, arm64_sequoia:     "6015856d04ab5d6b8e13937279637e1f4b3f431d1412ae7ad6c5365ff3f85c59"
    sha256 cellar: :any, tahoe:             "5f21715b9cb664bacebd2dcabc5a2da1bb4929d460509ad3c0f208d2362c8b9d"
    sha256 cellar: :any, sequoia:           "95f0bb8360b4a6b8341705038fd16381171cd29ce29e8d687352dd2a4a142ae2"
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
