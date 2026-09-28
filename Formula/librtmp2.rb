class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.10.2/librtmp2-0.10.2-src.tar.gz"
  sha256 "5deb6aa72c26d67b49fd021b30b0d2f58052b45c3aa685baafd28dec9c086b9e"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.10.2"
    sha256 cellar: :any, arm64_golden_gate: "701f8e286b1945fd19f5a0843ec9e4d7c6f1c40b000a57d6f81c8ad9a1dc781a"
    sha256 cellar: :any, arm64_tahoe:       "df9ea59f796e10924627b7dba46d3887e4b62e983ea04242bdb4c4ead6945b0b"
    sha256 cellar: :any, arm64_sequoia:     "e032be3d8410d43f3395164e22445779e90ec3c6f208ee80ea9ab37fc83a8cf6"
    sha256 cellar: :any, tahoe:             "9c64b9296e2def1bae67a33f8fe60ba28bc09697dbb5131ca23d8159ef4b8f4d"
    sha256 cellar: :any, sequoia:           "fb28bf6db2c1374c983b8fd9532d5ccfb96bfe48b25db23e950edded0731b913"
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
