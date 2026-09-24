class Librtmp2 < Formula
  desc "Modern RTMP and RTMPS protocol library"
  homepage "https://github.com/OpenRTMP/librtmp2"
  url "https://github.com/OpenRTMP/librtmp2/releases/download/v0.9.3/librtmp2-0.9.3-src.tar.gz"
  sha256 "c02e443d8924ce58871eb9871b9e0f84754f608236a363a97db87273593da493"
  license "MIT"

  bottle do
    root_url "https://packages.openrtmp.org/homebrew/librtmp2/0.9.3"
    sha256 cellar: :any, arm64_golden_gate: "f8b791d55b821a502571967e2c3f0682c57d0297ca4740381765ddef61ca3a71"
    sha256 cellar: :any, arm64_tahoe:       "bac37396976ac4130544b6ffbbff186fbd5a8e66141fad92f0f53d18fb411610"
    sha256 cellar: :any, arm64_sequoia:     "391cc6dae9de83f1fcfaf48d26d43b5decd86ab8421aa051feaa93fa18f9e3e9"
    sha256 cellar: :any, tahoe:             "107c5bd829f81e5f9902a20155e74c8e2198345fd6be9b65089a97dc0ef5d017"
    sha256 cellar: :any, sequoia:           "43a6b364a5ca68186af59a476b187150dc4d092d45a05be1ffc243e83652b7f4"
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
