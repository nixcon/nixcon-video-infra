{ stdenv, fetchFromGitHub, perl, perlPackages, makeWrapper, shortenPerlShebang
, nixosTests
}:

with stdenv.lib;

perlPackages.buildPerlPackage rec {
  pname = "convos";
  version = "4.23";

  src = fetchFromGitHub rec {
    owner = "Nordaaker";
    repo = pname;
    rev = version;
    sha256 = "0py9dvqf67vhgdlx20jzwnh313ns1d29yiiqgijydyfj2lflyz12";
  };

  nativeBuildInputs = [ makeWrapper ]
    ++ optional stdenv.isDarwin [ shortenPerlShebang ];

  buildInputs = with perlPackages; [
    CryptEksblowfish FileHomeDir FileReadBackwards
    IOSocketSSL IRCUtils JSONValidator LinkEmbedder ModuleInstall
    Mojolicious MojoliciousPluginOpenAPI MojoliciousPluginWebpack
    ParseIRC TextMarkdown TimePiece UnicodeUTF8
    CpanelJSONXS EV
  ];

  checkInputs = with perlPackages; [ TestDeep TestMore ];

  postPatch = ''
    patchShebangs script/convos
  '';

  preCheck = ''
    # A test fails since gethostbyaddr(127.0.0.1) fails to resolve to localhost in
    # the sandbox, we replace the this out from a substitution expression
    #
    substituteInPlace t/web-register-open-to-public.t \
      --replace '!127.0.0.1!' '!localhost!'

    # Time-impurity in test, (fixed in master)
    #
    substituteInPlace t/web-load-user.t \
      --replace '400' '410'

    # Disk-space check fails on zfs, (fixed in master)
    #
    substituteInPlace t/web-admin.t \
      --replace 'qr{/dev/}' 'qr{\w}'

    # Module::Install is a runtime dependency not covered by the tests, so we add
    # a test for it.
    #
    echo "use Test::More tests => 1;require_ok('Module::Install')" \
      > t/00_nixpkgs_module_install.t
  '';

  # Convos expects to find assets in both auto/share/dist/Convos, and $MOJO_HOME
  # which is set to $out
  #
  postInstall = ''
    AUTO_SHARE_PATH=$out/${perl.libPrefix}/auto/share/dist/Convos
    mkdir -p $AUTO_SHARE_PATH
    cp -vR public assets $AUTO_SHARE_PATH/
    ln -s $AUTO_SHARE_PATH/public/asset $out/asset
    cp -vR templates $out/templates
    cp cpanfile $out/cpanfile
  '' + optionalString stdenv.isDarwin ''
    shortenPerlShebang $out/bin/convos
  '' + ''
    wrapProgram $out/bin/convos --set MOJO_HOME $out
  '';

  passthru.tests = nixosTests.convos;

  meta = {
    homepage = "https://convos.chat";
    description = "Convos is the simplest way to use IRC in your browser";
    license = stdenv.lib.licenses.artistic2;
    maintainers = with maintainers; [ sgo ];
  };
}