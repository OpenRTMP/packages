class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.8.0/librtmp2-0.8.0-src.tar.gz"
  sha256 "8e1be00972fa6f8c8b5452ed64189c7335ff5ce88f3779cdbb7d518b7af33a7b"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.8.0"
    sha256 cellar: :any, arm64_golden_gate: "bd55184690a1dd343b187b270299f736303ba0ee6c7ec8e4d9991a4a48ffe187"
    sha256 cellar: :any, arm64_tahoe:       "ec89932345414ae54bfb65d19afa13980838489955b9e8c68c19768a36608649"
    sha256 cellar: :any, arm64_sequoia:     "66348efcace2a9312f10b336f2b17ddfb0bcb54e62086691fd3e606b6a1019f5"
    sha256 cellar: :any, arm64_sonoma:      "aa4bc8d30b0ddf422dce84cec2077bcdcaf30b30cd1b25af0f5a3bdd8c8a0c98"
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
