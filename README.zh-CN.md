# PDF Page Extractor

[English](README.md)

轻量原生 macOS 工具：预览 PDF，并把选定页面导出为 **200 DPI PNG 图片**。使用 Swift、AppKit 与 PDFKit，文档处理在本机完成。它渲染完整页面，不提取内嵌图片对象，也不生成新的 PDF。

## 下载与使用

从 [Releases](https://github.com/Jingyuan-Zheng/PDF-Page-Extractor/releases) 下载压缩包，解压后把 **PDF Page Extractor.app** 放入 `/Applications`。

- 下载包需要 macOS 13 或更新系统及 Apple 芯片。Intel 用户可以用 `python3 build_app.py --arch x86_64` 自行构建。
- 应用采用临时签名，未经 Apple 公证。首次运行可能需要在“系统设置 → 隐私与安全性”中允许打开。
- 这是 Finder／命令行辅助工具，没有 Dock 图标、独立菜单栏或 About 窗口。直接双击而不传入 PDF，会提示未提供文件。

传入一个或多个 PDF：

```sh
open -n "/Applications/PDF Page Extractor.app" --args "/path/to/document.pdf"
```

用 Command／Shift 多选缩略图，或输入 `1, 3-5, 9` 等页码后按回车。多个 PDF 可在文件下拉框中切换。点击 **Extract Pages** 导出。

默认勾选 **Export to Folder**，会在 PDF 旁新建输出文件夹；取消后直接保存到 PDF 所在目录。遇到同名输出会自动添加 `_2`、`_3` 等后缀，不修改原 PDF。需要对 PDF 所在目录有写入权限。图片背景为白色，分辨率固定为 200 DPI。目前界面为英文。

## 配套 Finder 快速操作

从 Releases 下载 **PDF-Page-Extractor-Workflows.zip**。先将应用放入 `/Applications` 或 `~/Applications`，再双击解压后的 workflow，通过 Automator 安装：

- **Extract Page to Image...**：将选定 PDF 传入应用，预览并选择页面。
- **Extract PDF as Images**：将每个选定 PDF 的全部页面导出为 200 DPI PNG，保存在 PDF 旁的新文件夹。脚本内嵌在 workflow 中，需要 Poppler，可用 `brew install poppler` 安装。交互式应用本身无需 Poppler。

在 Finder 选中 PDF 后，通过“快速操作／服务”调用；必要时在系统设置中启用。若已有同名服务，选择替换前请先备份。

仓库包含 workflow 文件和可编辑的生成器。修改脚本后运行 `python3 build_workflows.py` 重新生成，不依赖作者本机的安装路径。

## 从源码构建

安装 Apple Xcode Command Line Tools 和 Python 3，然后运行：

```sh
python3 build_app.py
python3 Tests/smoke_test.py
```

应用输出为 `dist/PDF Page Extractor.app`，面向当前芯片架构，最低部署版本为 macOS 13。不需要第三方依赖。构建会应用临时签名，不包含 Developer ID 签名或公证。

验证会生成双页测试 PDF，从应用实际渲染方法生成测试程序，并检查 PNG 文件、200 DPI 尺寸与非白色内容。CI 还会构建并验证应用签名。

需要诊断时，可在运行可执行文件前设置 `PDF_PAGE_EXTRACTOR_DEBUG=1`；日志可能包含文件路径，写入 `/tmp/pdf-page-extractor.log`。

## 当前限制

大量页面同步导出时窗口可能短暂失去响应；没有加密 PDF 的密码输入流程；输出格式与 DPI 固定；不提供 OCR。

作者：[Jingyuan Zheng](https://github.com/Jingyuan-Zheng)。贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。采用 [MIT 许可证](LICENSE)。
