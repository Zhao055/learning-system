import SwiftUI

struct CameraInputSheet: View {
    @Binding var isPresented: Bool
    let onCapture: (Data) -> Void

    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let image = selectedImage {
                    // Preview
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .cornerRadius(ZhiyaTheme.cornerRadius)
                        .padding()

                    HStack(spacing: 20) {
                        ZhiyaSecondaryButton(title: "重新选择") {
                            selectedImage = nil
                            showImagePicker = true
                        }

                        ZhiyaPrimaryButton(title: "发给知芽") {
                            if let data = image.jpegData(compressionQuality: 0.7) {
                                onCapture(data)
                                isPresented = false
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(ZhiyaTheme.lightBrown.opacity(0.5))

                        Text("拍一道题，知芽帮你分析")
                            .font(ZhiyaTheme.body())
                            .foregroundColor(ZhiyaTheme.lightBrown)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        ZhiyaPrimaryButton(title: "拍照") {
                            showImagePicker = true
                        }

                        ZhiyaSecondaryButton(title: "从相册选择") {
                            showImagePicker = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .background(ZhiyaTheme.cream.ignoresSafeArea())
            .navigationTitle("拍题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                        .foregroundColor(ZhiyaTheme.lightBrown)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

// Simple image picker wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // Use photo library as default; camera can be added with device check
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
