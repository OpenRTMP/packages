class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.9.2/librtmp2-0.9.2-src.tar.gz"
  sha256 "a377ea8d5d9600fa96cc1c9a5af99582af2c9e9f544c10717d5fe080ab2e37cc"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.9.2"
    sha256 cellar: :any, arm64_golden_gate: "13f9f554fb4d98f85cb8ed85cd1bab66bc3fb33517bcf49e7a098f44c3ddc593"
    sha256 cellar: :any, arm64_tahoe:       "8178321481e580de7ab44476b498a47fb95546065f2d45a458c6552b49861f22"
    sha256 cellar: :any, arm64_sequoia:     "8011c79c74a819a75e75ad65f20ee796ba809a79553c9189466dbbb737134303"
    sha256 cellar: :any, tahoe:             "9ad3f6ff91ba982311533b14f248b0da55978d56c51a9becced5e6340d5c605f"
    sha256 cellar: :any, sequoia:           "8251f45713132d28f9864637cc1c780252d616461df5bbfa35e7f37985e233ae"
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
