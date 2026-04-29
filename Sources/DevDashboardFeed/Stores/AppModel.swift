import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var documents: [DocumentItem]
    var watchedFolders: [WatchedFolder]
    var folderStatusMessage: String?
    let preferredDocumentSelectionID: DocumentItem.ID?

    @ObservationIgnored
    private let folderAccessController: any FolderAccessControlling
    @ObservationIgnored
    private let documentScanner: any DocumentScanning

    init(
        folderAccessController: any FolderAccessControlling = FolderAccessManager.shared,
        documentScanner: any DocumentScanning = DocumentScanner(),
        launchOverrides: LaunchOverrides = LaunchOverrides()
    ) {
        self.folderAccessController = folderAccessController
        self.documentScanner = documentScanner
        self.preferredDocumentSelectionID = launchOverrides.preferredDocumentSelectionID
        self.folderStatusMessage = nil
        self.documents = []
        self.watchedFolders = launchOverrides.watchedFoldersOverride ?? folderAccessController.restoreWatchedFolders()
        reloadDocuments()
    }

    func chooseWatchedFolder() {
        do {
            let selectionResult = try folderAccessController.chooseFolder(existingFolders: watchedFolders)

            switch selectionResult {
            case .added(let folder, let updatedFolders):
                watchedFolders = updatedFolders
                folderStatusMessage = "\"\(folder.name)\" was added."
                reloadDocuments()
            case .alreadyAdded(let folder):
                folderStatusMessage = "\"\(folder.name)\" is already in the list."
            case .cancelled:
                break
            }
        } catch {
            folderStatusMessage = error.localizedDescription
        }
    }

    func removeWatchedFolder(_ folder: WatchedFolder) {
        watchedFolders = folderAccessController.removeFolder(folder, from: watchedFolders)
        folderStatusMessage = "\"\(folder.name)\" was removed."
        reloadDocuments()
    }

    func reloadDocuments() {
        let scannedDocuments = documentScanner.scanDocuments(in: watchedFolders)

        if scannedDocuments.isEmpty && watchedFolders.isEmpty {
            documents = DocumentItem.sampleItems
        } else {
            documents = scannedDocuments
        }
    }
}
