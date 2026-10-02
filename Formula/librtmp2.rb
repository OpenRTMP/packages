class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.11.0/librtmp2-0.11.0-src.tar.gz"
  sha256 "79d902f631b7de00557b482ca0c9af657d456e11743f362be898cfea7f4ba52d"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.11.0"
    sha256 cellar: :any, arm64_golden_gate: "5cbd84825e03b919a7f081b25852d00f4ba8ed38536c1c97ee1a5e21ed7b63ce"
    sha256 cellar: :any, arm64_tahoe:       "f55154d38dafe1b5fc64bd63edbcb41f0f1626d84f283a6adc60b7e1c58d759d"
    sha256 cellar: :any, arm64_sequoia:     "c7c48a85292edf853de659c14eb59c45405264de8008a71faf6a0931914a8efb"
    sha256 cellar: :any, tahoe:             "385cfec0b013dd0a7e1643288b90a0ddcb7df7755813ee2796f310be013407fb"
    sha256 cellar: :any, sequoia:           "feeca4f6efc242bc5a500c97682dc311604f4a3391d8d356bf2d1646771e4626"
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
