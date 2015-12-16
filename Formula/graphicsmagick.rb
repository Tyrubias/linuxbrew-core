class Graphicsmagick < Formula
  desc "Image processing tools collection"
  homepage "http://www.graphicsmagick.org/"
  url "https://downloads.sourceforge.net/project/graphicsmagick/graphicsmagick/1.3.23/GraphicsMagick-1.3.23.tar.bz2"
  sha256 "6e14a9e9e42ec074239b2de4db37ebebb8268b0361332d5bc86d7c3fbfe5aabf"
  head "http://hg.code.sf.net/p/graphicsmagick/code", :using => :hg
  revision 1

  bottle do
    sha256 "96b2c3787f3c6c86d2a6b5088b51ee5c4e7c740ffc9e1c18a720c40414ff7fa0" => :el_capitan
    sha256 "954b907626decb5aa636c214e848a4dc374322f86b6d757680b6cf73f70f5bc8" => :yosemite
    sha256 "1252ee90b8812aea84378a9cad0cd2313e805d586bbca4fab6496839a5bc3a26" => :mavericks
  end

  option "with-quantum-depth-8", "Compile with a quantum depth of 8 bit"
  option "with-quantum-depth-16", "Compile with a quantum depth of 16 bit (default)"
  option "with-quantum-depth-32", "Compile with a quantum depth of 32 bit"
  option "without-magick-plus-plus", "disable build/install of Magick++"
  option "without-svg", "Compile without svg support"
  option "with-perl", "Build PerlMagick; provides the Graphics::Magick module"

  depends_on "libtool" => :run

  depends_on "pkg-config" => :build

  depends_on "jpeg" => :recommended
  depends_on "libpng" => :recommended
  depends_on "libtiff" => :recommended
  depends_on "freetype" => :recommended

  depends_on :x11 => :optional
  depends_on "little-cms2" => :optional
  depends_on "jasper" => :optional
  depends_on "libwmf" => :optional
  depends_on "ghostscript" => :optional
  depends_on "webp" => :optional

  fails_with :llvm do
    build 2335
  end

  skip_clean :la

  def ghostscript_fonts?
    File.directory? "#{HOMEBREW_PREFIX}/share/ghostscript/fonts"
  end

  def install
    args = ["--prefix=#{prefix}",
            "--disable-dependency-tracking",
            "--enable-shared",
            "--disable-static",
            "--with-modules",
            "--disable-openmp"]

    args << "--without-gslib" if build.without? "ghostscript"
    args << "--with-gs-font-dir=#{HOMEBREW_PREFIX}/share/ghostscript/fonts" if build.without? "ghostscript"
    args << "--without-magick-plus-plus" if build.without? "magick-plus-plus"
    args << "--with-perl" if build.with? "perl"
    args << "--with-webp=yes" if build.with? "webp"

    quantum_depth = [8, 16, 32].select { |n| build.with? "quantum-depth-#{n}" }
    if quantum_depth.length > 1
      odie "graphicsmagick: --with-quantum-depth-N options are mutually exclusive"
    end
    quantum_depth = quantum_depth.first || 16 # user choice or default

    args << "--with-quantum-depth=#{quantum_depth}"
    args << "--without-x" if build.without? "x11"
    args << "--without-ttf" if build.without? "freetype"
    args << "--without-xml" if build.without? "svg"
    args << "--without-lcms2" if build.without? "little-cms2"

    # versioned stuff in main tree is pointless for us
    inreplace "configure", "${PACKAGE_NAME}-${PACKAGE_VERSION}", "${PACKAGE_NAME}"
    system "./configure", *args
    system "make", "install"
    if build.with? "perl"
      cd "PerlMagick" do
        # Install the module under the GraphicsMagick prefix
        system "perl", "Makefile.PL", "INSTALL_BASE=#{prefix}"
        system "make"
        system "make", "install"
      end
    end
  end

  test do
    system "#{bin}/gm", "identify", test_fixtures("test.png")
  end

  def caveats
    if build.with? "perl"
      <<-EOS.undent
        The Graphics::Magick perl module has been installed under:

          #{lib}

      EOS
    end
  end
end
