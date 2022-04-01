//
//  DocumentPickerViewController.swift
//  peerConnect_swiftUI
//
//  Created by Jessie Hon on 2022-04-01.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker : UIViewControllerRepresentable {
    typealias UIViewControllerType = UIDocumentPickerViewController
    
    @Binding var urlChosed: URL?
    // I'm trying to include all types
    let supportedTypes: [UTType] = [UTType.image, UTType.text, UTType.plainText, UTType.utf8PlainText,    UTType.utf16ExternalPlainText, UTType.utf16PlainText,    UTType.delimitedText, UTType.commaSeparatedText,    UTType.tabSeparatedText, UTType.utf8TabSeparatedText, UTType.rtf,    UTType.pdf, UTType.webArchive, UTType.image, UTType.jpeg,    UTType.tiff, UTType.gif, UTType.png, UTType.bmp, UTType.ico,    UTType.rawImage, UTType.svg, UTType.livePhoto, UTType.movie,    UTType.video, UTType.audio, UTType.quickTimeMovie, UTType.mpeg,    UTType.mpeg2Video, UTType.mpeg2TransportStream, UTType.mp3,    UTType.mpeg4Movie, UTType.mpeg4Audio, UTType.avi, UTType.aiff,    UTType.wav, UTType.midi, UTType.archive, UTType.gzip, UTType.bz2,    UTType.zip, UTType.appleArchive, UTType.spreadsheet, UTType.epub]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentVC = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentVC.allowsMultipleSelection = false
        documentVC.shouldShowFileExtensions = true
        documentVC.delegate = context.coordinator
        
        return documentVC
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        //uiViewController.c
    }
    
    func makeCoordinator() -> DocumentCoordinator {
        DocumentCoordinator(self)
    }
    
    class DocumentCoordinator : NSObject, UIDocumentPickerDelegate{
        
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
            print("inside document picker, url: \(url)")
            parent.urlChosed = url
        }
    }
}


