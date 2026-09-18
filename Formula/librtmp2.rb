class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.8.1/librtmp2-0.8.1-src.tar.gz"
  sha256 "6f88dfee9c7f833ba6e4070e3cb26e9dd44978837b5812e21bccf4ac9eba38dd"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.8.1"
    sha256 cellar: :any, arm64_golden_gate: "70f8b03f2fd64e7d2faebe148a84f43ef34d7ff615d786c122f066d4ad7664e2"
    sha256 cellar: :any, arm64_tahoe:       "670369b53180dadeab0f3667086f68ff20740dedc6bfb7f01e9f19a4d6e5f8bc"
    sha256 cellar: :any, arm64_sequoia:     "23b571e8e9f757831d5808c26269158ca24c716058639de896f7f238c6ce9a82"
    sha256 cellar: :any, tahoe:             "d546291848e480427fb78fbba308d7e5bc2dfb2c211b38428b499eefb877f831"
    sha256 cellar: :any, sequoia:           "3697c82e9f0651499f4cc169528e4cb4209a30af35178f7b2d0f03fb1c8acb4b"
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
