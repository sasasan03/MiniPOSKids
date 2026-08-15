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
    
    /// 画面側で表示させるメニュー一覧
    let settingMenus = SettingMenu.allCases
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
