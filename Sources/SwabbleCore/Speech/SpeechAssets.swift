import Speech

public enum SpeechAssets {
    public static func ensureInstalled(for modules: [any SpeechModule]) async throws {
        if let request = try await AssetInventory.assetInstallationRequest(supporting: modules) {
            try await request.downloadAndInstall()
        }
    }
}
