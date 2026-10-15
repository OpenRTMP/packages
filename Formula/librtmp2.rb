class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.14.0/librtmp2-0.14.0-src.tar.gz"
  sha256 "98e69ef428fc650e6e947763bef074b1a523f409af31fc5b8ce3657e85ec3351"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.14.0"
    sha256 cellar: :any, arm64_golden_gate: "ca971882e1417caf52b44cf48d095573b6d57de60681cfe16107c470d6017236"
    sha256 cellar: :any, arm64_tahoe:       "ced46f13a3061be319efadc2013868acf8609d27f0a1170b191186392d6d6053"
    sha256 cellar: :any, arm64_sequoia:     "8a1c01fc67e514cda6697fc80aa3fa4ab275616abfa972d6d7031ab7e8581eb6"
    sha256 cellar: :any, tahoe:             "320345325d0290b34fe305551f18710b5e381cdc62710f645b581248995a1fc5"
    sha256 cellar: :any, sequoia:           "f42a938c6546057bbd2040795449ce2e80d3a925408c235e9222a02b9a284299"
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
