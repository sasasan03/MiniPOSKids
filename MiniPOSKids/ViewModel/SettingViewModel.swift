//
//  SettingViewModel.swift
//  MiniPOSKids
//
//  Created by sako0602 on 2026/08/14.
//

import Foundation

@MainActor
@Observable
class SettingViewModel {
    
    enum SettingMenu: String, CaseIterable, Identifiable {
        case logout
        
        var id: String { rawValue }
        
        var title: String {
           switch self {
            case .logout:
                return "ログアウト"
            }
        }
    }

    /// デモモード中かどうか。メニューやアラートの文言を切り替えるために保持する。
    let isDemo: Bool

    /// 画面側で表示させるメニュー一覧
    let settingMenus = SettingMenu.allCases

    /// メニューの表示名を返す。デモモードではログインしていないため「デモモードを終了」に読み替える。
    /// - Parameter menu: 表示対象のメニュー。
    /// - Returns: 画面に表示する文言。
    func title(for menu: SettingMenu) -> String {
        switch menu {
        case .logout:
            return isDemo ? "デモモードを終了" : menu.title
        }
    }

    /// 終了確認アラートのタイトル。
    var logoutAlertTitle: String {
        isDemo ? "デモモードを終了しますか？" : "ログアウトしますか？"
    }

    /// 終了確認アラートの実行ボタン名。
    var logoutConfirmTitle: String {
        isDemo ? "終了" : "ログアウト"
    }

    /// - Parameter isDemo: デモモードで起動しているかどうか。
    init(isDemo: Bool) {
        self.isDemo = isDemo
    }
    /// ログアウトのアラートの制御
    var isLogoutAlertPresented: Bool = false
    
    /// タップされたメニューに応じて処理を切り替える
    func handle(_ menu: SettingMenu) {
        switch menu {
        case .logout:
            showLogoutAlert()
        }
    }
    
    /// ログアウトアラート表示
    func showLogoutAlert(){
        isLogoutAlertPresented = true
    }
     
    /// ログアウトアラート非表示
    func dismissLogoutAlert(){
        isLogoutAlertPresented = false
    }
    
}
