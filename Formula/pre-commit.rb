class PreCommit < Formula
  include Language::Python::Virtualenv

  desc "Framework for managing multi-language pre-commit hooks"
  homepage "https://pre-commit.com/"
  url "https://files.pythonhosted.org/packages/1e/ba/8cf8b88d0e07588818de46877effc9971305541d9421bc6377b06639d135/pre_commit-2.20.0.tar.gz"
  sha256 "a978dac7bc9ec0bcee55c18a277d553b0f419d259dadb4b9418ff2d00eb43959"
  license "MIT"
  head "https://github.com/pre-commit/pre-commit.git", branch: "main"

  bottle do
    rebuild 3
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "7c75a21e7c43731035a05941e3d84720da3dfaccb96c61d4b20b93e6b9bfbd57"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "a8b37f8a39067ac6664fbb19ba4104ca7736ee81e52aea7bdce0860afa875df4"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "afd4642fb189b649e0b6ef45712379a8c97067d791b7f4c5466aeddfb02bda20"
    sha256 cellar: :any_skip_relocation, monterey:       "3ed2d228d4f1896e589755efb9d9c1b1569462aeeadfcf995bbc80be8dbdb6a8"
    sha256 cellar: :any_skip_relocation, big_sur:        "fd58b20ce989dc2e500fd57f976761c96356ef772ece6a475a284932a6eabc5c"
    sha256 cellar: :any_skip_relocation, catalina:       "735ac3350a76edf9f52737f6e7dd8eaa851348a3f390990db2deb7becf1a5bc4"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "7ef2db1ed7ba05a4cfe4d0ab6e75ddfb1e6e6626123f39cd6f3022b1b8716b73"
  end

  depends_on "python@3.11"
  depends_on "pyyaml"
  depends_on "six"
  depends_on "virtualenv"

  resource "cfgv" do
    url "https://files.pythonhosted.org/packages/c4/bf/d0d622b660d414a47dc7f0d303791a627663f554345b21250e39e7acb48b/cfgv-3.3.1.tar.gz"
    sha256 "f5a830efb9ce7a445376bb66ec94c638a9787422f96264c98edc6bdeed8ab736"
  end

  resource "distlib" do
    url "https://files.pythonhosted.org/packages/85/01/88529c93e41607f1a78c1e4b346b24c74ee43d2f41cfe33ecd2e20e0c7e3/distlib-0.3.4.zip"
    sha256 "e4b58818180336dc9c529bfb9a0b58728ffc09ad92027a3f30b7cd91e3458579"
  end

  resource "filelock" do
    url "https://files.pythonhosted.org/packages/f3/c7/5c1aef87f1197d2134a096c0264890969213c9cbfb8a4102087e8d758b5c/filelock-3.7.1.tar.gz"
    sha256 "3a0fd85166ad9dbab54c9aec96737b744106dc5f15c0b09a6744a445299fcf04"
  end

  resource "identify" do
    url "https://files.pythonhosted.org/packages/e5/8e/408d590e26fbc75a2e974aa1103d95a3ffef014209967f66f491306c4824/identify-2.5.1.tar.gz"
    sha256 "3d11b16f3fe19f52039fb7e39c9c884b21cb1b586988114fbe42671f03de3e82"
  end

  resource "nodeenv" do
    url "https://files.pythonhosted.org/packages/f3/9d/a28ecbd1721cd6c0ea65da6bfb2771d31c5d7e32d916a8f643b062530af3/nodeenv-1.7.0.tar.gz"
    sha256 "e0e7f7dfb85fc5394c6fe1e8fa98131a2473e04311a45afb6508f7cf1836fa2b"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/ff/7b/3613df51e6afbf2306fc2465671c03390229b55e3ef3ab9dd3f846a53be6/platformdirs-2.5.2.tar.gz"
    sha256 "58c8abb07dcb441e6ee4b11d8df0ac856038f944ab98b7be6b27b2a3c7feef19"
  end

  resource "toml" do
    url "https://files.pythonhosted.org/packages/be/ba/1f744cdc819428fc6b5084ec34d9b30660f6f9daaf70eead706e3203ec3c/toml-0.10.2.tar.gz"
    sha256 "b3bda1d108d5dd99f4a20d24d9c348e91c4db7ab1b749200bded2f839ccbe68f"
  end

  def python3
    "python3.11"
  end

  def install
    # Avoid Cellar path reference, which is only good for one version.
    inreplace "pre_commit/commands/install_uninstall.py",
              "f'INSTALL_PYTHON={shlex.quote(sys.executable)}\\n'",
              "f'INSTALL_PYTHON={shlex.quote(\"#{opt_libexec}/bin/#{python3}\")}\\n'"

    virtualenv_install_with_resources

    # we depend on virtualenv, but that's a separate formula, so install a `.pth` file to link them
    site_packages = Language::Python.site_packages("python3.11")
    virtualenv = Formula["virtualenv"].opt_libexec
    (libexec/site_packages/"homebrew-virtualenv.pth").write virtualenv/site_packages
  end

  # Avoid relative paths
  def post_install
    xy = Language::Python.major_minor_version Formula["python@3.11"].opt_bin/python3
    dirs_to_fix = [libexec/"lib/python#{xy}"]
    dirs_to_fix << (libexec/"bin") if OS.linux?
    dirs_to_fix.each do |folder|
      folder.each_child do |f|
        next unless f.symlink?

        realpath = f.realpath
        rm f
        ln_s realpath, f
      end
    end
  end

  test do
    system "git", "init"
    (testpath/".pre-commit-config.yaml").write <<~EOS
      -   repo: https://github.com/pre-commit/pre-commit-hooks
          sha: v0.9.1
          hooks:
          -   id: trailing-whitespace
    EOS
    system bin/"pre-commit", "install"
    (testpath/"f").write "hi\n"
    system "git", "add", "f"

    ENV["GIT_AUTHOR_NAME"] = "test user"
    ENV["GIT_AUTHOR_EMAIL"] = "test@example.com"
    ENV["GIT_COMMITTER_NAME"] = "test user"
    ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"
    git_exe = which("git")
    ENV["PATH"] = "/usr/bin:/bin"
    system git_exe, "commit", "-m", "test"
  end
end
