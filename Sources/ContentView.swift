import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var villageImage: UIImage?
    @State private var townHall = 17
    @State private var armyStyle = "متوازن"
    @State private var notes = ""
    @State private var showPlan = false

    private let levels = [15, 16, 17, 18]
    private let styles = ["متوازن", "جوي", "أرضي", "دفع مباشر", "استراتيجية دقيقة"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .trailing, spacing: 18) {
                    header
                    GroupBox {
                        VStack(alignment: .trailing, spacing: 12) {
                            Text("صورة قرية الخصم").font(.headline)
                            if let villageImage {
                                Image(uiImage: villageImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .frame(maxHeight: 330)
                            } else {
                                ContentUnavailableView("لم تُختر صورة بعد", systemImage: "photo.on.rectangle.angled", description: Text("ارفع لقطة شاشة واضحة لقرية الخصم"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                            }
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("اختيار صورة القرية", systemImage: "photo.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

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

                    Button {
                        showPlan = true
                    } label: {
                        Label("إعداد خطة الهجوم", systemImage: "scope")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(villageImage == nil)

                    if showPlan {
                        planSection
                    }

                    Text("تنبيه: هذه النسخة الأولية تنظّم التحليل والخطة اليدوية. لا تدّعي اكتشاف الدفاعات أو الفخاخ تلقائياً، ولا تضمن ثلاث نجوم.")
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
                showPlan = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text("مساعد تحليل الهجمات").font(.title2.bold())
            Text("حلّل التصميم، حدّد نقطة الدخول، واتبع خطة يدوية واضحة.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var planSection: some View {
        GroupBox {
            VStack(alignment: .trailing, spacing: 12) {
                Text("ورقة عمل الهجوم").font(.headline)
                Text("المستوى المحدد: TH\(townHall) • النمط: \(armyStyle)")
                    .font(.subheadline).foregroundStyle(.secondary)
                step(1, "افحص التصميم", "حدّد مواقع الدفاعات الثقيلة، أبراج التعاويذ، الدفاعات الجوية، ومسارات الوصول إلى قاعة المدينة.")
                step(2, "اختر جهة الدخول", "ابحث عن جانب يقلّ فيه تداخل الدفاعات، وقيّم قيمة إزالة الدفاعات الخارجية لصنع قمع للقوات.")
                step(3, "اصنع القمع", "استخدم وحدات جانبية مناسبة لتوجيه القوة الرئيسية نحو المسار المقصود، وتأكد من عدم انحرافها.")
                step(4, "أنزل القوة الرئيسية", "ابدأ من الجهة المختارة بعد تكوين القمع. وزّع القوات وفق دور كل مجموعة ولا تُنزل كل الدعم دفعة واحدة.")
                step(5, "أدر الأبطال والتعاويذ", "احتفظ بقدرات الأبطال والتعاويذ للحظات الخطر أو عبور المناطق ذات الضرر العالي.")
                step(6, "راجع المخاطر", "ضع احتمال الفخاخ المخفية، مسارات التشتت، والوقت المتبقي ضمن حساباتك.")
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("ملاحظاتك: \(notes)").font(.footnote)
                }
                Text("هذه خطوات إرشادية عامة وليست تحليل رؤية حاسوبية مؤكداً للصورة. يلزم التحقق اليدوي من مواقع المباني والتشكيلة قبل اعتماد الخطة.")
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
}
