class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.8.0/librtmp2-0.8.0-src.tar.gz"
  sha256 "8e1be00972fa6f8c8b5452ed64189c7335ff5ce88f3779cdbb7d518b7af33a7b"
  license "MIT"

  bottle do
    root_url "https://github.com/OpenRTMP/packages/releases/download/librtmp2-v0.8.0-homebrew"
    sha256 cellar: :any, arm64_golden_gate: "6f9a49d3e0336aa66afbe76e467b98493d777b3ae31d848b708c2375a1c9b392"
    sha256 cellar: :any, arm64_tahoe:       "fcad22a037f4e73dddea844b42d5ce74397e2cd35b11fee027944a02cb5b4e4c"
    sha256 cellar: :any, arm64_sequoia:     "399faa27d261e5fca9bb74fdcbab9deadd8c1e25a0912a82bb53e831dfbc1a31"
    sha256 cellar: :any, arm64_sonoma:      "c0bab319e2e0f4b246c04b25f982f7a151625bfabf333acb62f14cee29fad7f7"
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
