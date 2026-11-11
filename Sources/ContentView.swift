import SwiftUI
import PhotosUI

private struct VillageMark: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let kind: String
}


private struct SectorAssessment: Identifiable {
    let index: Int
    let name: String
    let score: Int
    let count: Int
    var id: Int { index }
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
                        Text("TH\(level)").tag(level)
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
                            ForEach(marks) { mark in
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
                                    .accessibilityLabel("علامة: \(mark.kind)")
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
                    Text("عدد العلامات: \(marks.count)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !marks.isEmpty {
                    Text(marks.map(\.kind).reduce(into: [:]) { counts, kind in counts[kind, default: 0] += 1 }
                        .map { entry in "\(entry.key): \(entry.value)" }
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

    private let sectorNames = ["الشرق", "الجنوب الشرقي", "الجنوب", "الجنوب الغربي", "الغرب", "الشمال الغربي", "الشمال", "الشمال الشرقي"]

    private func threatWeight(for kind: String) -> Int {
        switch kind {
        case "قاعة المدينة", "مونيليث": return 5
        case "النسر", "سكّاتر": return 4
        case "إنفيرنو", "دفاع جوي", "قلعة القبيلة": return 3
        case "إكس بو", "منفاخ", "برج سحري": return 2
        case "فخ مشتبه": return 1
        default: return 0
        }
    }

    private func adjustedWeight(for mark: VillageMark) -> Int {
        var weight = threatWeight(for: mark.kind)
        if armyStyle == "جوي" && ["دفاع جوي", "منفاخ"].contains(mark.kind) { weight += 3 }
        if armyStyle == "أرضي" && ["مونيليث", "إنفيرنو", "سكّاتر", "النسر"].contains(mark.kind) { weight += 2 }
        return weight
    }

    private var sectorAssessments: [SectorAssessment] {
        var scores = Array(repeating: 0, count: 8)
        var counts = Array(repeating: 0, count: 8)
        for mark in marks {
            let dx = mark.x - 0.5
            let dy = mark.y - 0.5
            if abs(dx) < 0.025 && abs(dy) < 0.025 { continue }
            let angle = atan2(dy, dx)
            let normalized = (angle + .pi * 2).truncatingRemainder(dividingBy: .pi * 2)
            let index = Int((normalized / (.pi / 4)).rounded()) % 8
            scores[index] += adjustedWeight(for: mark)
            counts[index] += 1
        }
        return (0..<8).map { SectorAssessment(index: $0, name: sectorNames[$0], score: scores[$0], count: counts[$0]) }
            .sorted { $0.score == $1.score ? $0.count < $1.count : $0.score < $1.score }
    }

    private var topThreats: [VillageMark] {
        marks.filter { threatWeight(for: $0.kind) >= 3 }
            .sorted { adjustedWeight(for: $0) > adjustedWeight(for: $1) }
    }

    private var confidenceLabel: String {
        if marks.count >= 10 && marks.contains(where: { $0.kind == "قاعة المدينة" }) && marks.contains(where: { threatWeight(for: $0.kind) >= 3 }) {
            return "متوسطة — تعتمد على دقة العلامات اليدوية"
        }
        if marks.count >= 4 { return "منخفضة إلى متوسطة — بعض الدفاعات غير محددة" }
        return "منخفضة — أضف علامات أكثر قبل اعتماد الاتجاه"
    }

    private var tacticalAdvice: String {
        switch armyStyle {
        case "جوي":
            return "ابدأ بتقييم الدفاعات الجوية والمنافخ على جهة الدخول. لا تلتزم بالمسار المقترح إذا كانت الدفاعات الجوية المتبقية تغطيه بتداخل قوي."
        case "أرضي":
            return "افحص المونيليث والإنفيرنو والسكّاتر حول المسار. جهّز قمعاً جانبياً واضحاً قبل إدخال القوة الرئيسية."
        case "دفع مباشر":
            return "تأكد من وجود ممر متصل نحو قلب القرية، وحدد مبنى أو دفاعاً محورياً كهدف أول للقوة الرئيسية."
        case "استراتيجية دقيقة":
            return "قسّم الهجوم إلى مراحل: قمع، دخول، معالجة قلب القرية، ثم تنظيف الأطراف. احتفظ بقدرات الأبطال للطوارئ."
        default:
            return "وازن بين تهديدات الجو والأرض، وابنِ القمع من جهتين قبل إدخال القوة الرئيسية عبر المسار المختار."
        }
    }

    private var formationRecommendation: (name: String, role: String, phases: [String], caution: String) {
        let name: String
        let role: String
        let phases: [String]
        let caution: String

        switch armyStyle {
        case "جوي":
            name = "مسار هجومي جوي"
            role = "مناسب عندما تكون الدفاعات الجوية والمنافخ قابلة للتعامل من جهة دخول واضحة، وبعد التأكد من تغطية الدفاعات المتبقية."
            phases = [
                "افتح المسار الجوي بإزالة التهديدات الطرفية التي تعيق الانتشار.",
                "ابدأ التمركز من جهة تقل فيها تغطية الدفاعات الجوية وفق العلامات، لا وفق النقاط وحدها.",
                "أدخل القوة الجوية الرئيسية على خط واحد متماسك، مع تجنب تقسيمها مبكراً.",
                "استخدم التعاويذ وقدرات الأبطال عند عبور مناطق الضرر العالي.",
                "احتفظ بوحدات التنظيف للمباني البعيدة بعد تجاوز القلب."
            ]
            caution = "هذه فئة استراتيجية وليست قائمة جيش جاهزة؛ يلزم تحديد القوات المتاحة ومستوياتها قبل توزيع السعة."
        case "أرضي":
            name = "مسار هجومي أرضي / Smash"
            role = "مناسب إذا أمكن فتح ممر إلى القلب وبناء قمع يمنع القوة الرئيسية من الدوران حول القرية."
            phases = [
                "اختر مدخلًا يسمح بفتح طبقة الجدار الأولى ثم الوصول إلى القلب.",
                "أنشئ قمعاً على الجانبين قبل نشر القوة الرئيسية.",
                "أدخل القوة الرئيسية مع وسيلة فتح الجدران أو تجاوزها المناسبة لتشكيلتك.",
                "احتفظ بقدرات الأبطال والتعاويذ للحظة الاشتباك مع الدفاعات الثقيلة.",
                "نظّف الأطراف بعد عبور القوة الرئيسية."
            ]
            caution = "لا تعتمد هذا المسار إذا كانت الجدران أو مواقع الدفاعات تمنع الوصول المباشر إلى القلب."
        case "دفع مباشر":
            name = "اختراق مركزي"
            role = "يركز على الوصول إلى هدف مركزي محدد بسرعة، ويتطلب مساراً واضحاً وقمعاً مضبوطاً."
            phases = [
                "حدد الهدف المركزي الذي تريد الوصول إليه قبل بدء الهجوم.",
                "افتح ممراً متصلاً من جهة الدخول إلى الهدف.",
                "نفّذ القمع الجانبي ثم أرسل القوة الرئيسية دفعة متماسكة.",
                "فعّل قدرات الأبطال والتعاويذ عند دخول منطقة الضرر المركز.",
                "حوّل الوحدات المتبقية إلى تنظيف المباني الخارجية."
            ]
            caution = "الاختراق المباشر عالي الحساسية لمسار الوحدات؛ قد يفشل إذا انحرفت القوة عن الممر."
        case "استراتيجية دقيقة":
            name = "هجوم مرحلي دقيق"
            role = "مناسب عندما تحتاج القرية إلى معالجة أكثر من منطقة دفاعية قبل دخول القوة الرئيسية."
            phases = [
                "ابدأ بوحدة أو مجموعة جانبية لمعالجة هدف دفاعي محدد.",
                "نفّذ القمع من الجهة المقابلة حتى لا تنحرف القوة الرئيسية.",
                "أدخل القوة الرئيسية بعد فتح المسار المطلوب.",
                "وزّع التعاويذ والقدرات بحسب مراحل الضرر لا بشكل مبكر.",
                "اترك وحدات التنظيف للمحيط وراقب الوقت."
            ]
            caution = "يتطلب توقيتاً جيداً؛ لا تستخدمه دون معرفة دور كل مجموعة في الجيش."
        default:
            name = "خطة متوازنة قابلة للتكييف"
            role = "خيار تخطيطي عام إلى أن تتحدد القوات ومستوياتها ونقاط الضعف الفعلية."
            phases = [
                "عالج هدفاً دفاعياً أو اثنين على الأطراف لتسهيل الدخول.",
                "ابنِ قمعاً واضحاً على جانبي المدخل.",
                "أدخل القوة الرئيسية نحو المسار الأكثر أماناً بعد فحص الجدران.",
                "احتفظ بالتعاويذ والقدرات للحظة تعرض القوة لأعلى ضرر.",
                "وزّع وحدات التنظيف على المباني الطرفية."
            ]
            caution = "النمط المتوازن ليس تشكيلة ثابتة؛ يجب اختيار القوات بناءً على تصميم القرية ومستويات جيشك."
        }

        return (name, role, phases, caution)
    }

    private var planSection: some View {
        GroupBox {
            VStack(alignment: .trailing, spacing: 12) {
                Text("تحليل تكتيكي أولي").font(.headline)
                Text("TH\(townHall) • النمط: \(armyStyle) • العلامات: \(marks.count)")
                    .font(.subheadline).foregroundStyle(.secondary)
                HStack {
                    Text(confidenceLabel)
                    Spacer()
                    Text("الثقة")
                        .fontWeight(.semibold)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                if marks.isEmpty {
                    Text("لم تُضف علامات بعد. علّم مواقع قاعة المدينة والدفاعات الثقيلة أولاً.")
                        .foregroundStyle(.orange)
                } else {
                    Text("جهة الدخول المرشحة").font(.subheadline.bold())
                    if let best = sectorAssessments.first {
                        Text(best.name)
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                        Text("أقل مجموع تهديد بين الجهات التي رُصدت: \(best.score) نقطة، مع \(best.count) علامة.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Text("مقارنة الجهات").font(.subheadline.bold())
                    ForEach(sectorAssessments) { sector in
                        HStack(spacing: 8) {
                            Text(sector.name).frame(width: 105, alignment: .trailing)
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.secondary.opacity(0.15))
                                    Capsule().fill(sector.index == sectorAssessments.first?.index ? .green : .orange)
                                        .frame(width: proxy.size.width * CGFloat(sector.score) / CGFloat(max(sectorAssessments.map(\.score).max() ?? 1, 1)))
                                }
                            }
                            .frame(height: 9)
                            Text("\(sector.score)").monospacedDigit().frame(width: 24)
                        }
                        .font(.caption)
                    }
                    Text("أعلى التهديدات المعلّمة").font(.subheadline.bold())
                    if topThreats.isEmpty {
                        Text("لم تُعلّم دفاعات ثقيلة بعد.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        ForEach(topThreats.prefix(5)) { mark in
                            HStack {
                                Text(mark.kind)
                                Spacer()
                                Text("(\(Int(mark.x * 100))%, \(Int(mark.y * 100))%)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .font(.callout)
                        }
                    }
                }

                Divider()
                Divider()
                Text("مكتبة الاستراتيجيات المقترحة").font(.headline)
                Text(formationRecommendation.name).font(.title3.bold())
                Text(formationRecommendation.role).font(.callout).foregroundStyle(.secondary)
                ForEach(Array(formationRecommendation.phases.enumerated()), id: \.offset) { index, phase in
                    step(index + 1, "مرحلة \(index + 1)", phase)
                }
                Text(formationRecommendation.caution)
                    .font(.footnote).foregroundStyle(.orange)

                Text("خطة التنفيذ المقترحة").font(.headline)
                step(1, "تأكيد الهدف", "تحقق من موقع قاعة المدينة والدفاعات الثقيلة داخل الصورة، وعدّل العلامات إذا كانت غير دقيقة.")
                step(2, "الدخول من \(sectorAssessments.first?.name ?? "الجهة الأنسب")", "هذا ترشيح حسابي أولي مبني على العلامات الظاهرة فقط؛ افحص الجدران ومسار الوصول قبل التنفيذ.")
                step(3, "بناء القمع", "استخدم وحدات التنظيف على جانبي جهة الدخول حتى تتجه القوة الرئيسية إلى المسار المقصود.")
                step(4, "معالجة القلب", "وجّه القوة الرئيسية نحو الهدف المركزي، واحتفظ بالتعاويذ والقدرات للحظة تعرضها لأعلى ضرر.")
                step(5, "التنظيف والتحقق", "راقب المباني الطرفية والوقت المتبقي، ولا تفترض أن الفخاخ أو القوات المدافعة قد كُشفت.")
                Text("توصية حسب النمط").font(.subheadline.bold())
                Text(tacticalAdvice).font(.callout)
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("ملاحظاتك: \(notes)").font(.footnote)
                }
                Text("حدود التحليل: هذا محرك قواعد تجريبي، وليس رؤية حاسوبية. يوازن العلامات التي أدخلتها يدوياً ولا يعرف مستويات المباني أو الجدران أو الفخاخ المخفية. لا يضمن ثلاث نجوم ولا يختار تشكيلة قوات نهائية.")
                    .font(.footnote).foregroundStyle(.orange)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func step(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
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
