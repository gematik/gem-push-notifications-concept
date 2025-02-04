// Copyright 2025 Gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI

struct EncryptionView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $viewModel.plaintext)
                        .font(.body.monospacedDigit())
                } header: {
                    Text("Input")
                } footer: {
                    Text("This plaintext is the payload of the notification that will be encrypted within `ciphertext`")
                }

                Section {
                    Button("Encrypt") {
                        viewModel.encrypt()
                    }
                    .disabled(viewModel.generation.isEmpty)
                    
                    HStack {
                        LabeledContent("Cipher", value: viewModel.cipher.lineBreakEvery(32))
                            .font(.footnote.monospaced())
                            .multilineTextAlignment(.trailing)
                        
                        Button {
                            // copy ciphertext to clipboard
                            UIPasteboard.general.string = viewModel.cipher
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }

                    Button("Decrypt") {
                        viewModel.decrypt()
                    }
                    .disabled(viewModel.generation.isEmpty)
                    
                    LabeledContent("Decrypted", value: viewModel.decrypted)
                        .font(.footnote.monospaced())
                        .multilineTextAlignment(.trailing)
                } header: {
                    Text("Encrypt/Decrypt")
                } footer: {
                    if viewModel.generation.isEmpty {
                        Text("⚠️ Add at least one generation to encrypt/decrypt.")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    ScrollView(.horizontal) {
                        Text(viewModel.notificationFD2Gateway)
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Payload example `Fachdienst -> Push Gateway`")
                } footer: {
                    Button {
                        UIPasteboard.general.string = viewModel.notificationFD2Gateway
                    } label: {
                        Label("Copy to clipboard", systemImage: "doc.on.doc")
                            .font(.footnote)
                    }
                }
                
                Section {
                    ScrollView(.horizontal) {
                        Text(viewModel.notificationGateway2FdV)
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Payload example `Push Gateway -> FdV`")
                } footer: {
                    Button {
                        UIPasteboard.general.string = viewModel.notificationGateway2FdV
                    } label: {
                        Label("Copy to clipboard", systemImage: "doc.on.doc")
                            .font(.footnote)
                    }
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Encrypt/Decrypt")
        }
    }
}
