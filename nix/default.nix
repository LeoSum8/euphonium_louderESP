{ stdenv, pkgs, writeShellScriptBin }:

let
  frontend-pkg = (pkgs.callPackage ../src/frontend { });
  esp-idf = (pkgs.callPackage ./esp-idf.nix { });
in
rec {
  # Euphonium's webinterface
  frontend = frontend-pkg.static;
  shell-frontend = frontend-pkg.shell;

  # Build recipe for storage
  fs-esp32 = stdenv.mkDerivation {
    name = "euphonium-fs-esp32";
    src = ../src/core/fs;
    buildInputs = [ frontend ];
    installPhase = ''
      mkdir -p $out/fs/cfg $out/fs/pkgs $out/fs/tmp

      # copy packages
      cp -r pkgs/system $out/fs/pkgs/system
      cp -r pkgs/bluetooth $out/fs/pkgs/bluetooth
      cp -r pkgs/cspot $out/fs/pkgs/cspot
      cp -r pkgs/radio $out/fs/pkgs/radio

      # copy platform support
      cp -r pkgs/platform_esp32 $out/fs/pkgs/platform_esp32 

      # copy web-ui files
      mkdir -p $out/fs/pkgs/web
      cp -r ${frontend} $out/fs/pkgs/web/dist
    '';
  };

  # Esp32 devshell
  shell-esp32 = pkgs.mkShell {
    inputsFrom = [ esp-idf ];
    shellHook = ''
      export IDF_PATH=${esp-idf}/sdk
      export IDF_TOOLS_PATH=${esp-idf}/.espressif
      export PATH=$IDF_PATH/tools:$PATH
      export IDF_PYTHON_ENV_PATH=$IDF_TOOLS_PATH/python_env/idf5.0_py3.9_env
    '';
  };

  # Helper for flashing storage partition
  flash-storage = writeShellScriptBin "flash-storage" ''
    #!/bin/bash
    if [ "$2" = "" ]
    then
      echo "Usage: flash-storage -- <path to storage.bin> <port>"
      exit 1
    fi
    ${esp-idf}/bin/esptool.py -p $2 -b 460800 --before default_reset --after hard_reset --chip esp32  write_flash --flash_mode dio --flash_size detect --flash_freq 80m 0x10000 $1
  '';

  # Build target esp32
  app-esp32 = stdenv.mkDerivation {
    name = "euphonium-esp32";
    src = ../.;

    nativeBuildInputs = with pkgs; [ esp-idf fs-esp32 pkg-config bash python39 ];

    # Patch nanopb shebangs to refer ot provided python
    postPatch = ''
      patchShebangs src/core/external/bell/external/nanopb/generator/*
    '';

    buildPhase = ''
      runHook preBuild
      export HOME=$TMP
      cd src/targets/esp32

      export IDF_PATH=${esp-idf}/sdk
      export IDF_TOOLS_PATH=${esp-idf}/.espressif

      # Include built fs
      rm -rf fs
      cp -r ${fs-esp32}/fs fs

      # build firmware
      idf.py build
      runHook postBuild
    '';
    installPhase = ''
      cd build
      mkdir -p $out $out/bootloader $out/partition_table
      cp storage.bin $out/storage.bin
      cp euphonium-esp32.bin $out/euphonium-esp32.bin
      cp bootloader/bootloader.bin $out/bootloader/bootloader.bin
      cp partition_table/partition-table.bin $out/partition_table/partition-table.bin
    '';
    dontConfigure = true;
  };
}
