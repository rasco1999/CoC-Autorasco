import SwiftUI
import PhotosUI

private struct AttackMark: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let kind: String
}

private struct AttackSector: Identifiable {
    let id: Int
    let name: String
    let score: Int
    let count: Int
}

struct ContentView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var villageImage: UIImage?
    @State private var townHall = 18
    @State private var armyStyle = "متوازن"
    @State private var captureType = "استطلاع"
    @State private var selectedMark = "قاعة المدينة"
    @State private var marks: [AttackMark] = []
    @State private var notes = ""
    @State private var showReport = false
    @State private var selectedTab = "التحليل"

    private let gold = Color(red: 0.96, green: 0.69, blue: 0.22)
    private let cyan = Color(red: 0.20, green: 0.78, blue: 0.91)
    private let ink = Color(red: 0.035, green: 0.055, blue: 0.09)
    private let panel = Color(red: 0.075, green: 0.105, blue: 0.15)
    private let levels = [15, 16, 17, 18]
    private let styles = ["متوازن", "جوي", "أرضي", "دفع مباشر", "استراتيجية دقيقة"]
    private let markKinds = ["قاعة المدينة", "النسر", "إنفيرنو", "سكّاتر", "مونيليث", "إكس بو", "دفاع جوي", "منفاخ", "قلعة القبيلة", "برج ساحر", "مخزن", "فخ ظاهر"]

    private let sectorNames = ["الشرق", "الجنوب الشرقي", "الجنوب", "الجنوب الغربي", "الغرب", "الشمال الغربي", "الشمال", "الشمال الشرقي"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [ink, Color(red: 0.055, green: 0.09, blue: 0.14), ink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        topBar
                        heroPanel
                        modePanel
                        villagePanel
                        if villageImage != nil {
                            annotationPanel
                            reportButton
                        }
                        if showReport { reportPanel }
                        disclaimer
                        footer
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.layoutDirection, .rightToLeft)
            .task(id: photoItem) {
                guard let photoItem,
                      let data = try? await photoItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                villageImage = image
                marks = []
                showReport = false
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 3) {
                Text("COC AUTORASCO")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(2.2)
                    .foregroundStyle(gold)
                Text("مركز القيادة والتحليل")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color(red: 0.18, green: 0.29, blue: 0.39), Color(red: 0.07, green: 0.12, blue: 0.19)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 25, weight: .black))
                    .foregroundStyle(gold)
                Image(systemName: "scope")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(cyan)
                    .offset(x: 1, y: -1)
            }
            .frame(width: 52, height: 52)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(gold.opacity(0.35), lineWidth: 1))
        }
        .padding(.top, 8)
    }

    private var heroPanel: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Label("TH15 — TH18", systemImage: "crown.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(gold.opacity(0.12), in: Capsule())
                Spacer()
                Text("TACTICAL INTELLIGENCE")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(cyan.opacity(0.9))
            }
            Text("اقرأ القرية.\nخطّط للهجوم.")
                .font(.system(size: 31, weight: .black, design: .rounded))
                .lineSpacing(2)
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
            Text("حلّل توزيع الدفاعات، حدّد المدخل، وابنِ خطة تنفيذ يدوية خطوة بخطوة.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.68))
                .multilineTextAlignment(.trailing)
            HStack(spacing: 8) {
                featurePill("تحليل القاعدة", "viewfinder")
                featurePill("مسار الدخول", "arrow.turn.down.right")
                featurePill("خطة 3 نجوم", "star")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24).fill(LinearGradient(colors: [Color(red: 0.10, green: 0.20, blue: 0.29), Color(red: 0.07, green: 0.11, blue: 0.17)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Circle().fill(cyan.opacity(0.10)).frame(width: 180).blur(radius: 20).offset(x: -35, y: -60)
                Circle().stroke(cyan.opacity(0.16), lineWidth: 1).frame(width: 180, height: 180).offset(x: -10, y: 25)
                Circle().stroke(gold.opacity(0.12), lineWidth: 1).frame(width: 230, height: 230).offset(x: -35, y: 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func featurePill(_ title: String, _ icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.white.opacity(0.07), in: Capsule())
    }

    private var modePanel: some View {
        VStack(alignment: .trailing, spacing: 13) {
            sectionHeading("إعداد المهمة", subtitle: "حدد نوع اللقطة ومستوى الخصم")
            HStack(spacing: 8) {
                modeButton("استطلاع", icon: "map", detail: "قرية كاملة")
                modeButton("معركة", icon: "flame", detail: "لقطة أثناء الهجوم")
                modeButton("إعادة", icon: "play.rectangle", detail: "Replay")
            }
            HStack {
                Text("مستوى قاعة المدينة")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                ForEach(levels, id: \.self) { level in
                    Button {
                        townHall = level
                        showReport = false
                    } label: {
                        Text("TH\(level)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(townHall == level ? ink : .white.opacity(0.75))
                            .frame(width: 53, height: 34)
                            .background(townHall == level ? gold : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            HStack {
                Text("أسلوب الجيش")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Menu {
                    ForEach(styles, id: \.self) { style in
                        Button(style) { armyStyle = style; showReport = false }
                    }
                } label: {
                    HStack(spacing: 7) {
                        Text(armyStyle)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(15)
        .background(panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.07), lineWidth: 1))
    }

    private func modeButton(_ title: String, icon: String, detail: String) -> some View {
        let selected = captureType == title
        return Button {
            captureType = title
            showReport = false
        } label: {
            VStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 17, weight: .bold))
                Text(title).font(.system(size: 12, weight: .bold))
                Text(detail).font(.system(size: 9, weight: .medium)).opacity(0.65)
            }
            .foregroundStyle(selected ? ink : .white.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? gold : .white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? gold : .white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var villagePanel: some View {
        VStack(alignment: .trailing, spacing: 12) {
            sectionHeading("صورة الهدف", subtitle: "ارفع لقطة واضحة للقرية أو شاشة المعركة")
            if let villageImage {
                Image(uiImage: villageImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 310)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(cyan.opacity(0.35), lineWidth: 1))
                HStack {
                    Button {
                        self.villageImage = nil
                        marks = []
                        showReport = false
                        photoItem = nil
                    } label: {
                        Label("إزالة الصورة", systemImage: "trash")
                    }
                    .foregroundStyle(.red.opacity(0.9))
                    Spacer()
                    Text("الصورة جاهزة للتحليل")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(cyan)
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 11) {
                        ZStack {
                            Circle().fill(cyan.opacity(0.10)).frame(width: 58, height: 58)
                            Image(systemName: "viewfinder")
                                .font(.system(size: 25, weight: .semibold))
                                .foregroundStyle(cyan)
                        }
                        Text("اضغط لاختيار لقطة الشاشة")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text("PNG أو JPG • صورة واضحة • القرية كاملة")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.48))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 25)
                    .background(Color.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 5])).foregroundStyle(cyan.opacity(0.38)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(15)
        .background(panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.07), lineWidth: 1))
    }

    private var annotationPanel: some View {
        VStack(alignment: .trailing, spacing: 12) {
            sectionHeading("تحديد مواقع الدفاعات", subtitle: "اختر المبنى ثم المس موضعه على الصورة")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(markKinds, id: \.self) { kind in
                        Button(kind) { selectedMark = kind }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(selectedMark == kind ? ink : .white.opacity(0.8))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(selectedMark == kind ? gold : .white.opacity(0.07), in: Capsule())
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
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(ink)
                                .padding(5)
                                .background(gold, in: Circle())
                                .overlay(Circle().stroke(.white, lineWidth: 1))
                                .position(x: (proxy.size.width - fitted.width) / 2 + mark.x * fitted.width,
                                          y: (proxy.size.height - fitted.height) / 2 + mark.y * fitted.height)
                        }
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .frame(width: fitted.width, height: fitted.height)
                            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            .gesture(SpatialTapGesture().onEnded { value in
                                let x = min(max(value.location.x / fitted.width, 0), 1)
                                let y = min(max(value.location.y / fitted.height, 0), 1)
                                marks.append(AttackMark(x: x, y: y, kind: selectedMark))
                                showReport = false
                            })
                    }
                }
            }
            .frame(height: 260)
            .background(.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
            HStack {
                Button("تراجع") {
                    if !marks.isEmpty { marks.removeLast() }
                    showReport = false
                }
                .disabled(marks.isEmpty)
                Button("مسح الكل") {
                    marks.removeAll()
                    showReport = false
                }
                .disabled(marks.isEmpty)
                Spacer()
                Text("\(marks.count) علامة")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(gold)
            }
            .font(.system(size: 12, weight: .semibold))
            .tint(cyan)
            TextField("ملاحظات الجيش ومستويات الأبطال (اختياري)", text: $notes, axis: .vertical)
                .font(.system(size: 12))
                .padding(11)
                .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                .lineLimit(2...4)
        }
        .padding(15)
        .background(panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.07), lineWidth: 1))
    }

    private var reportButton: some View {
        Button {
            showReport = true
        } label: {
            HStack {
                Image(systemName: "scope").font(.system(size: 17, weight: .black))
                Text("حلّل القرية وأنشئ خطة الهجوم")
                    .font(.system(size: 15, weight: .black))
                Spacer()
                Image(systemName: "arrow.left").font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(ink)
            .padding(17)
            .background(LinearGradient(colors: [gold, Color(red: 1, green: 0.80, blue: 0.39)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var reportPanel: some View {
        VStack(alignment: .trailing, spacing: 14) {
            sectionHeading("تقرير المهمة", subtitle: "نتائج أولية مبنية على العلامات اليدوية")
            HStack(spacing: 8) {
                metricCard("المستوى", "TH\(townHall)", "crown.fill", gold)
                metricCard("العلامات", "\(marks.count)", "scope", cyan)
                metricCard("النمط", armyStyle, "bolt.fill", gold)
            }
            if marks.isEmpty {
                Text("لم تُضف علامات بعد. أضف قاعة المدينة والدفاعات الرئيسية للحصول على مقارنة أولية للجهات.")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
            } else {
                let sectors = sectorScores
                if let best = sectors.first {
                    HStack {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("مدخل مرشح مبدئياً").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
                            Text(best.name).font(.system(size: 24, weight: .black, design: .rounded)).foregroundStyle(cyan)
                            Text("درجة التهديد المسجّلة: \(best.score)").font(.system(size: 10)).foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Image(systemName: "arrow.down.right.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(cyan)
                    }
                    .padding(14)
                    .background(cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                }
                Text("مقارنة الجهات").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                ForEach(sectors) { sector in
                    HStack(spacing: 9) {
                        Text(sector.name).font(.system(size: 10, weight: .semibold)).frame(width: 88, alignment: .trailing)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.08))
                                Capsule().fill(sector.id == sectors.first?.id ? cyan : gold.opacity(0.75))
                                    .frame(width: geo.size.width * CGFloat(sector.score) / CGFloat(max(sectors.map(\.score).max() ?? 1, 1)))
                            }
                        }.frame(height: 8)
                        Text("\(sector.score)").font(.system(size: 10, weight: .bold, design: .rounded)).frame(width: 22)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            Divider().overlay(.white.opacity(0.12))
            Text("تسلسل الهجوم المقترح").font(.system(size: 14, weight: .black)).foregroundStyle(gold)
            ForEach(Array(attackPhases.enumerated()), id: \.offset) { index, phase in
                HStack(alignment: .top, spacing: 10) {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(ink)
                        .frame(width: 31, height: 31)
                        .background(gold, in: RoundedRectangle(cornerRadius: 9))
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(phase.0).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                        Text(phase.1).font(.system(size: 11)).foregroundStyle(.white.opacity(0.62))
                    }
                    Spacer(minLength: 0)
                }
            }
            Text("هذه نسخة تخطيطية تعتمد على العلامات اليدوية ولا تنفذ الهجوم. لا تكتشف المباني تلقائياً ولا تضمن ثلاث نجوم.")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.orange)
                .padding(11)
                .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(15)
        .background(panel, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(gold.opacity(0.22), lineWidth: 1))
    }

    private func metricCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 7) {
            Image(systemName: icon).foregroundStyle(color)
            Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(.white.opacity(0.55))
            Text(value).font(.system(size: 12, weight: .black)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(10)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
    }

    private var disclaimer: some View {
        Text("تنويه: هذا تطبيق مستقل غير رسمي، ولا ترعاه Supercell ولا تؤيده. لا يستخدم أتمتة أو تحكماً باللعبة. للاستخدام الإرشادي فقط.")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white.opacity(0.42))
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var footer: some View {
        HStack {
            Text("TACTICAL ASSISTANT • PRIVATE BUILD")
            Spacer()
            Text("v2.0 UI")
        }
        .font(.system(size: 8, weight: .bold, design: .rounded))
        .tracking(1)
        .foregroundStyle(.white.opacity(0.25))
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(title).font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(subtitle).font(.system(size: 10, weight: .medium)).foregroundStyle(.white.opacity(0.48))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var sectorScores: [AttackSector] {
        var scores = Array(repeating: 0, count: 8)
        var counts = Array(repeating: 0, count: 8)
        for mark in marks {
            let dx = mark.x - 0.5
            let dy = mark.y - 0.5
            if abs(dx) < 0.025 && abs(dy) < 0.025 { continue }
            let angle = atan2(dy, dx)
            let normalized = (angle + .pi * 2).truncatingRemainder(dividingBy: .pi * 2)
            let index = Int((normalized / (.pi / 4)).rounded()) % 8
            scores[index] += weight(mark.kind)
            counts[index] += 1
        }
        return (0..<8).map { AttackSector(id: $0, name: sectorNames[$0], score: scores[$0], count: counts[$0]) }
            .sorted { $0.score == $1.score ? $0.count < $1.count : $0.score < $1.score }
    }

    private func weight(_ kind: String) -> Int {
        switch kind {
        case "قاعة المدينة", "مونيليث": return 5
        case "النسر", "سكّاتر": return 4
        case "إنفيرنو", "دفاع جوي", "قلعة القبيلة": return 3
        case "إكس بو", "منفاخ", "برج ساحر": return 2
        case "فخ ظاهر": return 1
        default: return 0
        }
    }

    private var attackPhases: [(String, String)] {
        switch armyStyle {
        case "جوي":
            return [
                ("تقييم التغطية الجوية", "راجع الدفاعات الجوية والمنافخ المتبقية وحدد الجهة الأقل تداخلاً."),
                ("فتح المسار", "عالج الدفاعات الطرفية التي تعيق انتشار القوات الجوية."),
                ("إطلاق القوة الرئيسية", "حافظ على خط هجوم متماسك ولا تقسّم القوة مبكراً."),
                ("التعاويذ والقدرات", "استخدمها عند دخول مناطق الضرر الأعلى، لا قبل الحاجة."),
                ("التنظيف", "وزّع وحدات التنظيف على المباني البعيدة وراقب الوقت.")
            ]
        case "أرضي", "دفع مباشر":
            return [
                ("اختيار المدخل", "اختر جهة تسمح بفتح ممر نحو القلب بعد فحص الجدران."),
                ("بناء القمع", "نظّف الجانبين حتى لا تنحرف القوة الرئيسية إلى الأطراف."),
                ("إدخال القوة", "أدخل المجموعة الرئيسية عبر الممر المحدد."),
                ("اختراق القلب", "احتفظ بالقدرات والتعاويذ للحظة الاشتباك مع الدفاعات الثقيلة."),
                ("التنظيف", "عالج المباني الطرفية وتابع الوقت المتبقي.")
            ]
        case "استراتيجية دقيقة":
            return [
                ("مرحلة التهيئة", "عالج هدفاً دفاعياً محدداً قبل دخول القوة الرئيسية."),
                ("القمع المقابل", "افتح الجهة الثانية لتوجيه مسار القوات."),
                ("الدخول المرحلي", "أدخل القوة الرئيسية بعد تحقق الممر."),
                ("إدارة الموارد", "وزّع التعاويذ والقدرات وفق الضرر الفعلي."),
                ("إنهاء الهجوم", "خصص وحدات التنظيف للمحيط وراقب الوقت.")
            ]
        default:
            return [
                ("تحديد التهديدات", "راجع قاعة المدينة والمونيليث والنسر والدفاعات الجوية."),
                ("تهيئة المدخل", "عالج مبنيين طرفيين لبناء قمع واضح."),
                ("إدخال القوة الرئيسية", "وجّه الجيش نحو المسار المختار بعد فحص الجدران."),
                ("إدارة القدرات", "احتفظ بالتعاويذ وقدرات الأبطال للحظات الحاسمة."),
                ("التنظيف النهائي", "وزع وحدات التنظيف على الأطراف ولا تهمل الوقت.")
            ]
        }
    }

    private func shortLabel(_ kind: String) -> String {
        switch kind {
        case "قاعة المدينة": return "TH"
        case "دفاع جوي": return "AD"
        case "قلعة القبيلة": return "CC"
        case "فخ ظاهر": return "!"
        default: return String(kind.prefix(2))
        }
    }

    private func fittedSize(for imageSize: CGSize, in container: CGSize) -> CGSize {
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}
