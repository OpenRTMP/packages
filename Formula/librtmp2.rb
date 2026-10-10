class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.12.0/librtmp2-0.12.0-src.tar.gz"
  sha256 "f91857493717591752aba3ead1e14d648aa54f543db0f4c7f0af47b2a17e8bdb"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.12.0"
    sha256 cellar: :any, arm64_golden_gate: "8177bb510b930243f1e478a8beacef3659022846b5aa289ca4e6a3cd8f5573ae"
    sha256 cellar: :any, arm64_tahoe:       "155d77643c10c60b0734d10c2fa384dfedb2e0960d196b54cc4b5c0b46a68fe5"
    sha256 cellar: :any, arm64_sequoia:     "874d6115e6dace32f650833409fbce3a1c63182e952175cc172ae27b0b1b8a37"
    sha256 cellar: :any, tahoe:             "e81307bf02d58ff31dff0f64015f94f3128b5efca319fde6ff83005ab3f8585d"
    sha256 cellar: :any, sequoia:           "4c7252072a1ee7d78a81b9c4647c88bfe410e1b4307f349fb9aab133dfd06bf2"
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
