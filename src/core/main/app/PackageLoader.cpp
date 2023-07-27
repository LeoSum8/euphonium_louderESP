#include "PackageLoader.h"

using namespace euph;

PackageLoader::PackageLoader(std::shared_ptr<euph::Context> ctx) {
  this->ctx = ctx;
}

void PackageLoader::loadValidPackages() {
  this->packages = std::vector<PackageInfo>();
  EUPH_LOG(info, TAG, "Loading packages");
  std::string path = fmt::format("{}/pkgs", ctx->rootPath);

  std::string summaryString = "";

  // iterate over all the files in the pkgs directory
  for (const auto& entry : ghc::filesystem::directory_iterator(path)) {
    std::string manifestPath =
        fmt::format("{}/manifest.json", entry.path().c_str());

    try {
      std::ifstream manifestFile(manifestPath);
      nlohmann::json manifest = nlohmann::json::parse(manifestFile);

      // ensure that the manifest has all the required fields
      if (!manifest.contains("name") || !manifest.contains("version") ||
          !manifest.contains("description") || !manifest.contains("author") ||
          !manifest.contains("init_hook")) {
        EUPH_LOG(info, TAG, "Invalid manifest for package: %s",
                 entry.path().filename().c_str());
        continue;
      }

      PackageInfo info;
      info.name = manifest["name"];
      info.version = manifest["version"];
      info.description = manifest["description"];
      info.author = manifest["author"];
      info.initHook = manifest["init_hook"];

      this->packages.push_back(info);
      summaryString += fmt::format("{}=={}, ", info.name, info.version);
    } catch (...) {
      continue;
    }
  }

  if (summaryString.size() > 0) {
    // Remove two trailling char
    summaryString.pop_back();
    summaryString.pop_back();

    EUPH_LOG(info, TAG, "Registered following packages [%s]",
             summaryString.c_str());
  }
}

void PackageLoader::loadWithHook(const std::string& hook) {
  EUPH_LOG(info, TAG, "Loading packages with hook: %s", hook.c_str());
  for (auto pkg : this->packages) {
    if (pkg.initHook == hook) {
      EUPH_LOG(info, TAG, "Loading package: %s", pkg.name.c_str());
      std::string initPath =
          fmt::format("{}/pkgs/{}/init.be", ctx->rootPath, pkg.name);

      // Read init code file
      std::ifstream initCodeFile(initPath);
      std::stringstream initCodeBuffer;
      initCodeBuffer << initCodeFile.rdbuf();

      ctx->vm->execute_string(initCodeBuffer.str(), pkg.name);
    }
  }
}
