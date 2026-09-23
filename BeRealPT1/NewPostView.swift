import SwiftUI
import PhotosUI
import ImageIO
import CoreLocation
import ParseSwift


struct NewPostView: View {
    var onPosted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var imageData: Data?
    @State private var caption = ""
    @State private var isPosting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 8) {
            TextField("Caption (optional)", text: $caption)
                .padding(10)
                .background(Color.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Select Photo")
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color(red: 0.0, green: 0.09, blue: 0.2))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Post Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isPosting {
                    ProgressView()
                } else {
                    Button("Post") { Task { await post() } }
                        .disabled(image == nil)
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                imageData = data
                image = UIImage(data: data)
            }
        }
    }

    private func post() async {
        guard let image, let jpeg = image.jpegData(compressionQuality: 0.3) else { return }
        isPosting = true
        errorMessage = nil
        defer { isPosting = false }

        var newPost = Post()
        newPost.imageFile = ParseFile(name: "image.jpg", data: jpeg)
        newPost.caption = caption.isEmpty ? nil : caption
        newPost.user = User.current

        
        if let imageData {
            let metadata = PhotoMetadata(data: imageData)
            newPost.takenAt = metadata.dateTaken
            if let coordinate = metadata.coordinate {
                newPost.location = await placeName(for: coordinate)
            }
        }

        do {
            _ = try await newPost.save()

            if var me = User.current {
                me.lastPostedDate = Date()
                _ = try? await me.save()
            }
            onPosted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    
    private func placeName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return nil
        }
        let parts = [placemark.locality ?? placemark.name, placemark.administrativeArea]
        return parts.compactMap { $0 }.joined(separator: ", ")
    }
}



struct PhotoMetadata {
    var coordinate: CLLocationCoordinate2D?
    var dateTaken: Date?

    init(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return }

        if let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any],
           var lat = gps[kCGImagePropertyGPSLatitude] as? Double,
           var lon = gps[kCGImagePropertyGPSLongitude] as? Double {
            if (gps[kCGImagePropertyGPSLatitudeRef] as? String) == "S" { lat = -lat }
            if (gps[kCGImagePropertyGPSLongitudeRef] as? String) == "W" { lon = -lon }
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }

        if let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any],
           let raw = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            dateTaken = formatter.date(from: raw)
        }
    }
}
