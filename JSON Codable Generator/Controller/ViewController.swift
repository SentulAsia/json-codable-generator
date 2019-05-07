//
//  ViewController.swift
//  JSON Codable Generator
//
//  Created by Zaid Said on 20/03/2019.
//  Copyright © 2019 Zaid Said. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var nameTextField: NSTextField!
    @IBOutlet var inputTV: NSTextView!
    @IBOutlet var outputTV: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupTextField()
        setupTextView()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - IBActions - Menus
    
    @IBAction func newDocument(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to Reset current view?"
        alert.informativeText = "This will remove all existing work"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: self.view.window!) { [weak self] (modalResponse) in
            if modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn {
                self?.setupTextView()
            }
        }
    }
    
    @IBAction func saveDocument(_ sender: Any) {
        saveDocumentAs(sender)
    }
    
    @IBAction func saveDocumentAs(_ sender: Any) {
        var name = nameTextField.stringValue
        if name.isEmpty {
            name = "ModelName"
        }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = name + ".swift"
        savePanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
        savePanel.begin { [weak self] (result) in
            if result == NSApplication.ModalResponse.OK {
                if let url = savePanel.url {
                    try? self?.outputTV.string.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        }
    }
}

extension ViewController {
    func setupTextField() {
        nameTextField.delegate = self
    }
    
    func setupTextView() {
        inputTV.delegate = self
        inputTV.isAutomaticQuoteSubstitutionEnabled = false
        inputTV.enabledTextCheckingTypes = 0
        inputTV.font = NSFont(name: "Menlo-Regular", size: 12)
        outputTV.font = NSFont(name: "Menlo-Regular", size: 10)
        inputTV.string = ""
        outputTV.string = ""
    }
    
    func decode(string: String) -> String {
        if let data = string.data(using: .utf8), let response = try? JSONSerialization.jsonObject(with: data, options: []) {
            if let r = response as? [[String: Any]] {
                return printArrayCodable(response: r)
            } else if let r = response as? [String: Any] {
                return printCodable(response: r)
            }
            return "invalid JSON"
        }
        return "invalid JSON"
    }
    
    func printCodable(response: [String: Any]) -> String {
        var name = nameTextField.stringValue
        if name.isEmpty {
            name = "ModelName"
        }
        return CodableGenerator.shared.generate(fromInput: response, withName: name)
    }
    
    func printArrayCodable(response: [[String: Any]]) -> String {
        var name = nameTextField.stringValue
        if name.isEmpty {
            name = "ModelName"
        }
        return CodableGenerator.shared.generate(fromArrayInput: response, withName: name)
    }
}

extension ViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let newString = inputTV.string
        if !newString.isEmpty {
            outputTV.string = decode(string: newString)
        }
        return true
    }
}

extension ViewController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        if let r = replacementString {
            let char = r.cString(using: String.Encoding.utf8)!
            let isBackSpace = strcmp(char, "\\b")
            if (isBackSpace == -92) {
                outputTV.string = ""
            } else {
                let newString = textView.string + r
                outputTV.string = decode(string: newString)
            }
        } else {
            outputTV.string = ""
        }
        return true
    }
}
