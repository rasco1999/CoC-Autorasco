import SwiftUI
import PhotosUI

private struct VillageMark: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let kind: String
}

struct ContentView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var villageImage: UIImage?
    @State private var townHall = 17
    @State private var armyStyle = "متوازن"
    @State private var notes = ""
    @State private var showPlan = false
    @State private var selectedMarkKind = "قاعة المدينة"
    @State private var marks: [VillageMark] = []

    private let levels = [15, 16, 17, 18]
    private let styles = ["متوازن", "جوي", "أرضي", "دفع مباشر", "استراتيجية دقيقة"]
    private let markKinds = [
        "قاعة المدينة", "النسر", "إنفيرنو", "سكّاتر", "مونيليث",
        "إكس بو", "دفاع جوي", "منفاخ", "قلعة القبيلة", "برج سحري", "مخزن", "فخ مشتبه"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .trailing, spacing: 18) {
                    header
                    villageSection
                    attackSettings
                    if villageImage != nil {
                        annotationSection
                    }
                    Button {
                        showPlan = true
                    } label: {
                        Label("إعداد خطة الهجوم", systemImage: "scope")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(villageImage == nil)

                    if showPlan { planSection }

                    Text("مهم: العلامات تُدخل يدوياً وليست اكتشافاً آلياً. الفخاخ والمباني المحجوبة تبقى غير مؤكدة. لا توجد ضمانة لثلاث نجوم.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                .padding()
            }
            .navigationTitle("CoC AutoRasco")
            .environment(\.layoutDirection, .rightToLeft)
            .task(id: selectedPhoto) {
                guard let selectedPhoto,
                      let data = try? await selectedPhoto.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                villageImage = image
                marks = []
                showPlan = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("مساعد تحليل الهجمات").font(.title2.bold())
            Text("علّم مواقع الدفاعات على الصورة، ثم راجع ورقة الهجوم.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var villageSection: some View {
        GroupBox {
            VStack(alignment: .trailing, spacing: 12) {
                Text("صورة قرية الخصم").font(.headline)
                if let villageImage {
                    Image(uiImage: villageImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .frame(maxHeight: 300)
                } else {
                    ContentUnavailableView("لم تُختر صورة بعد", systemImage: "photo.on.rectangle.angled", description: Text("ارفع لقطة شاشة واضحة لقرية الخصم"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("اختيار صورة القرية", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var attackSettings: some View {
        GroupBox {
            VStack(alignment: .trailing, spacing: 14) {
                Text("بيانات الهجوم").font(.headline)
                Picker("مستوى قاعة المدينة", selection: $townHall) {
                    ForEach(levels, id: \.self) { level in
                        Text("TH\\(level)").tag(level)
                    }
                }
                .pickerStyle(.segmented)
                Picker("نوع التشكيلة المفضلة", selection: $armyStyle) {
                    ForEach(styles, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                TextField("ملاحظات اختيارية: مستويات الأبطال أو القوات...", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var annotationSection: some View {
        GroupBox {
            VStack(alignment: .trailing, spacing: 12) {
                Text("علّم مواقع المباني").font(.headline)
                Text("اختر نوع المبنى، ثم المس موقعه على صورة القرية لإضافة علامة.")
                    .font(.footnote).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(markKinds, id: \.self) { kind in
                            Button(kind) { selectedMarkKind = kind }
                                .buttonStyle(.bordered)
                                .tint(selectedMarkKind == kind ? .orange : .secondary)
                        }
                    }
                }
                GeometryReader { proxy in
                    if let villageImage {
                        let fitted = fittedSize(for: villageImage.size, in: proxy.size)
                        ZStack {
                            Image(uiImage: villageImage)
                                .resizable()
                                .frame(width: fitted.width, height: fitted.height)
                                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            ForEach(Array(marks.enumerated()), id: \.element.id) { index, mark in
                                Text(shortLabel(mark.kind))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(5)
                                    .background(.red.opacity(0.9), in: Circle())
                                    .overlay(Circle().stroke(.white, lineWidth: 1))
                                    .position(
                                        x: (proxy.size.width - fitted.width) / 2 + mark.x * fitted.width,
                                        y: (proxy.size.height - fitted.height) / 2 + mark.y * fitted.height
                                    )
                                    .accessibilityLabel("علامة \\(index + 1): \\(mark.kind)")
                            }
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .frame(width: fitted.width, height: fitted.height)
                                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                                .gesture(SpatialTapGesture().onEnded { value in
                                    let x = min(max(value.location.x / fitted.width, 0), 1)
                                    let y = min(max(value.location.y / fitted.height, 0), 1)
                                    marks.append(VillageMark(x: x, y: y, kind: selectedMarkKind))
                                    showPlan = false
                                })
                        }
                    }
                }
                .frame(height: 300)
                .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                HStack {
                    Button("تراجع عن آخر علامة") {
                        if !marks.isEmpty { marks.removeLast() }
                        showPlan = false
                    }
                    .disabled(marks.isEmpty)
                    Button("مسح العلامات") {
                        marks.removeAll()
                        showPlan = false
                    }
                    .disabled(marks.isEmpty)
                    Spacer()
                    Text("عدد العلامات: \\(marks.count)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !marks.isEmpty {
                    Text(marks.map(\.kind).reduce(into: [:]) { counts, kind in counts[kind, default: 0] += 1 }
                        .map { "\\($0.key): \\($0.value)" }
                        .sorted()
                        .joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var planSection: some View {
        GroupBox {
            VStack(alignment: .trailing, spacing: 12) {
                Text("ورقة عمل الهجوم").font(.headline)
                Text("القرية المستهدفة: TH\\(townHall) • النمط المفضل: \\(armyStyle)")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("العلامات التي أدخلتها: \\(marks.count)")
                    .font(.subheadline.bold())
                ForEach(markKinds, id: \.self) { kind in
                    let count = marks.filter { $0.kind == kind }.count
                    if count > 0 {
                        HStack {
                            Text(kind)
                            Spacer()
                            Text("\\(count)").monospacedDigit().bold()
                        }
                        .font(.callout)
                    }
                }
                step(1, "راجع توزيع الدفاعات", "استخدم العلامات على الصورة لتحديد مناطق تداخل الضرر والدفاعات التي يجب التعامل معها أولاً.")
                step(2, "اختر جهة الدخول", "فضّل الجهة التي تمنحك مساراً واضحاً نحو الهدف وتقلل تعرض القوة الرئيسية لعدة دفاعات ثقيلة في وقت واحد.")
                step(3, "كوّن القمع", "نظّف المباني الجانبية قبل إنزال القوة الرئيسية حتى لا تنحرف عن المسار المقصود.")
                step(4, "نفّذ الهجوم على مراحل", "وزّع القوات وفق أدوارها، واحتفظ بالتعاويذ وقدرات الأبطال للحظات الحاسمة.")
                step(5, "تحقق من المخاطر", "الفخاخ غير المرئية، مستويات المباني، القوات المدافعة، ومسارات الحركة تحتاج إلى تحقق داخل اللعبة.")
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("ملاحظاتك: \\(notes)").font(.footnote)
                }
                Text("هذه الورقة تلخص العلامات اليدوية ولا تحلل الصورة تلقائياً أو تختار تشكيلة مثلى بعد. الخطوة التالية هي بناء محرك قواعد يربط مواقع الدفاعات ونوع الجيش بخطة أكثر تخصيصاً.")
                    .font(.footnote).foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\\(number)")
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(.tint.opacity(0.2), in: Circle())
            VStack(alignment: .trailing, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.callout).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func shortLabel(_ kind: String) -> String {
        switch kind {
        case "قاعة المدينة": return "TH"
        case "دفاع جوي": return "AD"
        case "قلعة القبيلة": return "CC"
        case "فخ مشتبه": return "!"
        default: return String(kind.prefix(2))
        }
    }

    private func fittedSize(for imageSize: CGSize, in container: CGSize) -> CGSize {
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}
