import SwiftUI
import SwiftData
import TaxEngine

/// 設定画面。対象年度・申告方法・税計算用プロフィール・予備資金を管理する。
/// 詳細設定を行っていなくてもアプリが使えるよう、すべての項目は未設定でも動作する初期値を持つ。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var appSettingsList: [AppSettings]
    @Query private var taxSettingsList: [TaxSettings]
    @Query private var reserveSettingsList: [ReserveSettings]

    @State private var viewModel = SettingsViewModel()
    @State private var errorMessage: String?

    private var currentYear: Int { Calendar.current.component(.year, from: .now) }

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                filingSection
                taxProfileSection
                socialInsuranceSection
                businessTaxSection
                reserveSection
                aboutSection
            }
            .navigationTitle("設定")
            .onAppear(perform: loadIfNeeded)
            .onChange(of: viewModel.displayName) { _, _ in save() }
            .onChange(of: viewModel.businessStartYear) { _, _ in save() }
            .onChange(of: viewModel.filingType) { _, _ in save() }
            .onChange(of: viewModel.blueReturnDeduction) { _, _ in save() }
            .onChange(of: viewModel.prefecture) { _, _ in save() }
            .onChange(of: viewModel.birthYear) { _, _ in save() }
            .onChange(of: viewModel.dependentsCount) { _, _ in save() }
            .onChange(of: viewModel.hasSpouse) { _, _ in save() }
            .onChange(of: viewModel.isNationalPensionEnrolled) { _, _ in save() }
            .onChange(of: viewModel.hasSetNationalHealthInsuranceAmount) { _, _ in save() }
            .onChange(of: viewModel.nationalHealthInsuranceAnnualAmount) { _, _ in save() }
            .onChange(of: viewModel.businessTaxCategory) { _, _ in save() }
            .onChange(of: viewModel.businessReserveAmount) { _, _ in save() }
            .onChange(of: viewModel.otherReserveAmount) { _, _ in save() }
            .alert(
                "保存に失敗しました",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - セクション

    private var profileSection: some View {
        Section("プロフィール") {
            TextField("表示名（任意）", text: $viewModel.displayName)

            Picker("事業開始年", selection: $viewModel.businessStartYear) {
                ForEach(((currentYear - 30)...currentYear).reversed(), id: \.self) { year in
                    Text("\(String(year))年").tag(year)
                }
            }

            HStack {
                Text("対象年度")
                Spacer()
                Button {
                    changeYear(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text("\(String(viewModel.selectedYear))年")
                    .monospacedDigit()
                    .frame(minWidth: 64)

                Button {
                    changeYear(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filingSection: some View {
        Section("申告方法") {
            Picker("申告方法", selection: $viewModel.filingType) {
                ForEach(FilingType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.filingType == .blue {
                Picker("青色申告特別控除", selection: $viewModel.blueReturnDeduction) {
                    ForEach(BlueReturnDeductionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    }

    private var taxProfileSection: some View {
        Section {
            Picker("都道府県", selection: $viewModel.prefecture) {
                ForEach(Prefecture.allCases) { prefecture in
                    Text(prefecture.displayName).tag(prefecture)
                }
            }
            .pickerStyle(.navigationLink)

            Picker("生年", selection: $viewModel.birthYear) {
                Text("未設定").tag(Int?.none)
                ForEach(((currentYear - 100)...(currentYear - 15)).reversed(), id: \.self) { year in
                    Text("\(String(year))年").tag(Int?.some(year))
                }
            }
            .pickerStyle(.navigationLink)

            Stepper("扶養人数: \(viewModel.dependentsCount)人", value: $viewModel.dependentsCount, in: 0...10)

            Toggle("配偶者がいる", isOn: $viewModel.hasSpouse)
        } header: {
            Text("税計算用の情報（\(String(viewModel.selectedYear))年）")
        } footer: {
            Text("配偶者控除・扶養控除は所得制限や年齢区分を考慮しない概算金額です。")
        }
    }

    private var socialInsuranceSection: some View {
        Section {
            Toggle("国民年金に加入している", isOn: $viewModel.isNationalPensionEnrolled)

            Toggle("国民健康保険料を入力する", isOn: $viewModel.hasSetNationalHealthInsuranceAmount)
            if viewModel.hasSetNationalHealthInsuranceAmount {
                CurrencyTextField(value: $viewModel.nationalHealthInsuranceAnnualAmount)
            }
        } header: {
            Text("社会保険")
        } footer: {
            Text("国民健康保険料は自治体により大きく異なるため自動計算していません。年額の目安をお住まいの自治体窓口やウェブサイトでご確認のうえ入力してください。未入力の場合は0円として概算します。")
        }
    }

    private var businessTaxSection: some View {
        Section {
            Picker("業種区分", selection: $viewModel.businessTaxCategory) {
                ForEach(BusinessTaxCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .pickerStyle(.navigationLink)
        } header: {
            Text("個人事業税")
        } footer: {
            Text("正確な業種区分の判定が必要な場合は、税務署・都道府県税事務所にご確認ください。")
        }
    }

    private var reserveSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("事業用に残しておきたい予備資金")
                CurrencyTextField(value: $viewModel.businessReserveAmount)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("その他確保したい資金（任意）")
                CurrencyTextField(value: $viewModel.otherReserveAmount)
            }
        } header: {
            Text("予備資金")
        }
    }

    private var aboutSection: some View {
        Section("このアプリについて") {
            DisclaimerText()
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(version)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - データ読み込み・保存

    private func loadIfNeeded() {
        viewModel.load(
            userProfile: userProfiles.first,
            appSettings: appSettingsList.first,
            taxSettings: taxSettingsList.first { $0.year == (appSettingsList.first?.selectedYear ?? currentYear) },
            reserveSettings: reserveSettingsList.first
        )
    }

    private func changeYear(by delta: Int) {
        let newYear = viewModel.selectedYear + delta
        viewModel.selectYear(
            newYear,
            taxSettings: taxSettingsList.first { $0.year == newYear },
            context: modelContext
        )
    }

    private func save() {
        do {
            try viewModel.save(context: modelContext)
        } catch {
            errorMessage = "しばらくしてからもう一度お試しください。"
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [
            UserProfile.self,
            TaxSettings.self,
            ReserveSettings.self,
            AppSettings.self
        ], inMemory: true)
}
