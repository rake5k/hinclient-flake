{ stdenv, fetchurl, lib }:

stdenv.mkDerivation rec {

  version = "1.5.6-81";
  packageVersion = builtins.replaceStrings [ "." ] [ "_" ] version;
  name = "hinclient";

  src = fetchurl {
    url = "https://download.hin.ch/download/distribution/install/${version}/HINClient_unix_${packageVersion}.tar.gz";
    sha256 = "1wcxqhj2pzmmkwp7pb22g4yfxsnfq2w3j673y8zs567yyynqfidc";
  };

  buildPhase = "true";

  installPhase = ''
    mkdir -p $out
    mv * $out
    mv .install4j $out
    mkdir -p $out/bin
    ln -sT $out/hinclient $out/bin/hinclient
  '';

  meta = with lib; {
    homepage = "https://download.hin.ch";
    license = licenses.unfree;
    description = "The Health Info Net Client";
    longDescription = ''
      The HIN Client is the access software for easy and secure access to the HIN
      platform. This software is installed on the workstations and thus enables
      HIN participants to securely access HIN protected web applications and the
      HIN email services.
    '';
    platforms = platforms.unix;
  };
}
