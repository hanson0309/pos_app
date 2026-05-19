# 测试运行指南

## 快速测试

### Windows 平台
```bash
cd pos_app
flutter run -d windows
```

### Android 平台
```bash
# 1. 连接 Android 设备或启动模拟器
# 2. 检查设备
flutter devices

# 3. 运行应用
flutter run -d android
```

### iOS 平台（需要 Mac）
```bash
flutter run -d ios
```

## 预期结果

应用启动后会显示一个空白的 Splash 页面（因为我们还没有创建实际的 UI）。

这是正常的！说明项目配置正确。

## 下一步

开始创建实际的 UI 界面：
1. 启动页 (splash_screen.dart)
2. 设备配对页 (pairing_screen.dart)
3. 收银页 (cashier_screen.dart)

详见 CHECKLIST.md
