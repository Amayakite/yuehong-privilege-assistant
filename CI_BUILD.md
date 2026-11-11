# CI 打包说明

本仓库通过 GitHub Actions 在 Linux runner 上构建 arm64 APK，无需本地安装 Android SDK / NDK / Rust。

工作流：`.github/workflows/android-apk.yml`

## 触发方式

- **手动**：Actions → `Build APK` → Run workflow，`variant` 选 `release` 或 `debug`。
- **打标签**：推送 `v*` 形式的 tag（如 `git tag v1.6.7 && git push fork v1.6.7`）会自动按 release 构建。

产物在两个 artifact 中：`yuehong-apk-<variant>`（APK）与 `yuehong-mapping`（release 的混淆映射，仅 release 有）。

## 构建环境（与根 `build.gradle` 对齐）

| 组件 | 版本 |
| --- | --- |
| JDK | Temurin 21 |
| Android Platform | `platforms;android-37.0`（包名带小版本号，`android-37` 会找不到） |
| Build Tools | 36.0.0 |
| NDK | 29.0.13113456 |
| CMake | 3.22.1 |
| Gradle | 由 `gradle/wrapper` 提供 |
| Rust | stable + `aarch64-linux-android` target |

## Release 签名

`manager` 的 release 变体强制要求签名，缺失时 `validateSigningRelease` 会直接失败。CI 从以下 secrets 读取：

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | keystore 文件的 base64（`base64 -i release.jks`） |
| `ANDROID_KEYSTORE_PASSWORD` | storePassword |
| `ANDROID_KEY_ALIAS` | keyAlias |
| `ANDROID_KEY_PASSWORD` | keyPassword |

设置命令（需 `repo` 与 `workflow` 权限）：

```bash
base64 -i release.jks | gh secret set ANDROID_KEYSTORE_BASE64 --repo <owner>/<repo>
gh secret set ANDROID_KEYSTORE_PASSWORD --repo <owner>/<repo>
gh secret set ANDROID_KEY_ALIAS          --repo <owner>/<repo>
gh secret set ANDROID_KEY_PASSWORD       --repo <owner>/<repo>
```

> **务必备份密钥库与密码。** 丢失后无法对已安装的应用做覆盖升级，只能卸载重装（会清数据）。

本地构建时把同样的值写进仓库根目录的 `keystore.properties`（已被 `.gitignore` 忽略）：

```properties
storeFile=release.jks
storePassword=...
keyAlias=yuehong
keyPassword=...
```

## 本地构建（macOS / Linux）

```bash
./tools/build_android.sh Release   # 等价于 Windows 的 tools/build_android.ps1 -Variant Release
```

需要 JDK 21、SDK/NDK/CMake 上述版本、Rust `aarch64-linux-android`，并在 `local.properties` 或环境变量中提供 `sdk.dir` / `ANDROID_NDK_HOME`。

## 与上游脚本的差异

上游构建脚本按 Windows 宿主编写，本仓库补了宿主平台判断，否则 Linux/macOS 上原生步骤必失败：

- `third_party/ghostlock/app/build.gradle`：`clang++.exe` / `llvm-ar.exe` / `llvm-strip.exe` / `aarch64-linux-android34-clang.cmd` 改为按宿主解析。
- 同上：`TARGET_CONFIG_H` 宏的引号转义按宿主区分（Windows 的 `CreateProcess` 会再解析一次引号，POSIX 不会）。
