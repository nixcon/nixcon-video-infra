{ stdenv, fetchurl, dpkg, jre_headless, nixosTests, openssl, makeWrapper, xorg, writeText }:

let
  pname = "jibri";
  version = "8.0-53-ga574be9";
  src = fetchurl {
    url = "https://download.jitsi.org/stable/${pname}_${version}-1_all.deb";
    sha256 = "0p09lf12gh587w25p30pyhbrnkch9v532cy1av4xxam7w98pj8n4";
  };

  xorgModulePaths = writeText "module-paths" ''
    Section "Files"
      ModulePath "${xorg.xorgserver}/lib/xorg/modules
      ModulePath "${xorg.xorgserver}/lib/xorg/extensions
      ModulePath "${xorg.xorgserver}/lib/xorg/drivers
      ModulePath "${xorg.xf86videodummy}/lib/xorg/modules/drivers
    EndSection
  '';

in
stdenv.mkDerivation {
  inherit pname version src;

  dontBuild = true;

  unpackCmd = "${dpkg}/bin/dpkg-deb -x $src debcontents";

  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/share/jibri $out/etc/jitsi
    cp -rf etc/jitsi/jibri $out/etc/jitsi
    cp opt/jitsi/jibri/jibri.jar $out/share/jibri

    cat '${xorgModulePaths}' >> $out/etc/jitsi/jibri/xorg-video-dummy.conf
  '';

  meta = with stdenv.lib; {
    description = "Jitsi BRoadcasting Infrastructure";
    longDescription = ''
      Jibri provides services for recording or streaming a Jitsi Meet conference.
    '';
    homepage = "https://github.com/jitsi/jibri";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}
