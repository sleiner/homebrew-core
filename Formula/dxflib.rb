class Dxflib < Formula
  desc "C++ library for parsing DXF files"
  homepage "https://www.ribbonsoft.com/en/what-is-dxflib"
  url "https://www.ribbonsoft.com/archives/dxflib/dxflib-3.26.4-src.tar.gz"
  sha256 "507db4954b50ac521cbb2086553bf06138dc89f55196a8ba22771959c760915f"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.ribbonsoft.com/en/dxflib-downloads"
    regex(/href=.*?dxflib[._-]v?(\d+(?:\.\d+)+)-src\.t/i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_monterey: "7394d8e91ad3daefb69baae95372e86243fa69252aaaff0671aae88c5385b8be"
    sha256 cellar: :any,                 arm64_big_sur:  "38f73afafa3258b4d298f173064099dac105ab5bc162eae367d76fe326f5fbb8"
    sha256 cellar: :any,                 monterey:       "47ebef21d6211ac7b080a8f1ed23dfb154febdf8dfd1a157b14e3c5dccea2812"
    sha256 cellar: :any,                 big_sur:        "86c60b0cc3b353b3652d6bb819c41fcec1cebc6c2f1f7ae435696bbae757a16f"
    sha256 cellar: :any,                 catalina:       "8bfd7c24979cf19191ff911bae9173666f84cf3b5995f3e16672041a9720220f"
  end

  depends_on "qt" => :build

  # Sample DXF file made available under GNU LGPL license.
  # See https://people.math.sc.edu/Burkardt/data/dxf/dxf.html.
  resource "testfile" do
    url "https://people.math.sc.edu/Burkardt/data/dxf/cube.dxf"
    sha256 "e5744edaa77d1612dec44d1a47adad4aad3d402dbf53ea2aff5a57c34ae9bafa"
  end

  def install
    # For libdxflib.a
    system "qmake", "dxflib.pro"
    system "make"

    # Build shared library
    inreplace "dxflib.pro", "CONFIG += staticlib", "CONFIG += shared"
    system "qmake", "dxflib.pro"
    system "make"

    (include/"dxflib").install Dir["src/*"]
    lib.install Dir["*.a", shared_library("*")]
  end

  test do
    resource("testfile").stage testpath

    (testpath/"test.cpp").write <<~EOS
      #include <dxflib/dl_dxf.h>
      #include <dxflib/dl_creationadapter.h>

      using namespace std;

      class MyDxfFilter : public DL_CreationAdapter {
        virtual void addLine(const DL_LineData& d);
      };

      void MyDxfFilter::addLine(const DL_LineData& d) {
        cout << d.x1 << "/" << d.y1 << " "
             << d.x2 << "/" << d.y2 << endl;
      }

      int main() {
        MyDxfFilter f;
        DL_Dxf* dxf = new DL_Dxf();
        dxf->test();
        if (!dxf->in("cube.dxf", &f)) return 1;
        return 0;
      }
    EOS

    system ENV.cxx, "test.cpp", "-o", "test",
           "-I#{include}/dxflib", "-L#{lib}", "-ldxflib"
    output = shell_output("./test")
    assert_match "1 buf1: '  10", output
    assert_match "2 buf1: '10'", output
    assert_match "-0.5/-0.5 0.5/-0.5", output.split("\n")[16]
  end
end
