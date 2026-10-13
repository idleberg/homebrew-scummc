class Scummc < Formula
  desc "Set of tools allowing to create SCUMM games"
  homepage "https://github.com/AlbanBedel/scummc#readme"
  url "https://github.com/AlbanBedel/scummc/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "1d9b412d7ab6197495589a19a4745f58b35a002e26cea21bf6874a7ae4f1fd2e"

  depends_on "bison" => :build
  depends_on "freetype"

  def install
    # configure doesn't know about 64-bit ARM
    inreplace "configure", "i[3-9]86|x86_64|alpha)", "i[3-9]86|x86_64|alpha|arm64|aarch64)"

    # Requires Bison v2.7 or later, but macOS ships with v2.3
    system "./configure", "--bison", formula_opt_bin("bison")/"bison",
                          "--buildroot", "build",
                          "--release",
                          "--disable-gtk",
                          "--disable-sdl"
    system "make"

    # No install target; binaries land in build/<target>/
    bin.install %w[scc sld cost char soun midi].map { |b| Dir["build/*/#{b}"].first }

    pkgshare.install "include", "examples"
  end

  test do
    # Build the "road" example game in standalone mode and compare
    # the output against upstream's reference hashes
    cp_r pkgshare/"examples/road", testpath
    cp pkgshare/"examples/example.mak", testpath
    touch testpath/"scummc-config.mak"

    cd "road" do
      system "make", "BIN_DIR=#{bin}", "INC_DIR=#{pkgshare}/include"

      File.read("road.md5").scan(/^(\S+): (\h+)$/).each do |file, md5|
        assert_equal md5, Digest::MD5.file(file).hexdigest, file
      end
    end
  end
end
