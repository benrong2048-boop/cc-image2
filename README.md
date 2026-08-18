# CC Image 2

让 Codex 通过 CC Switch 调用 `gpt-image-2` 生成和编辑图片的 Skill。

它专门解决一个常见问题：`gpt-image-2` 只能通过图片专用接口调用，不能放到普通的 `/v1/responses` 对话接口里。本 Skill 会根据是否提供参考图，自动选择生成或编辑接口。

## 能做什么

- **从零生成图片**：海报、产品图、插画、思维导图、社媒素材等。
- **基于参考图编辑**：保留人物五官、产品结构、构图或材质，修改背景、服装、发型、表情、风格等。
- **局部重绘**：提供 PNG 蒙版后，仅编辑指定区域。
- **固定使用 `gpt-image-2`**：不会悄悄回退到 Codex 内置生图模型或其他模型。

## 前置条件

1. 已在 CC Switch 或兼容网关中配置 `gpt-image-2` 的图片生成、图片编辑接口。
2. 已在系统环境变量中配置：

```powershell
OPENAI_API_KEY
OPENAI_BASE_URL
```

3. 使用 Windows PowerShell；脚本位于 `scripts/generate.ps1`。

> 不要把 `gpt-image-2` 配为普通对话模型。它应只走 `/v1/images/generations` 或 `/v1/images/edits`，否则通常会报“only supported on images generations/edits”。

## 安装到 Codex

```powershell
git clone https://github.com/benrong2048-boop/cc-image2.git "$HOME\.codex\skills\cc-image2"
```

安装完成后，重启 Codex 或新建一个任务。随后可直接说：

- `用 image 2 生成一张产品海报`
- `用 CC Switch 的 image 2 保留这张人像的脸，换成商务头像背景`

## 用法示例

### 从零生成

```powershell
& "$HOME\.codex\skills\cc-image2\scripts\generate.ps1" `
  -Prompt "一张极简风格的便携式发电机产品海报，白色摄影棚背景，真实产品摄影，留出标题空间" `
  -Out "D:\output\generator-poster.png" `
  -Size "1536x1024" `
  -Quality high
```

### 参考图编辑

```powershell
& "$HOME\.codex\skills\cc-image2\scripts\generate.ps1" `
  -ReferenceImage "D:\input\portrait.jpg" `
  -Prompt "保留人物的五官比例、发际线、肤色与年龄感，换成干净的商务头像背景和深色西装" `
  -Out "D:\output\portrait-business.png" `
  -Size "1536x1536" `
  -Quality high
```

### 先检查调用路径，不实际生成

```powershell
& "$HOME\.codex\skills\cc-image2\scripts\generate.ps1" `
  -ReferenceImage "D:\input\portrait.jpg" `
  -Prompt "保留人物特征，改为插画风格" `
  -Out "D:\output\check.png" `
  -Size "1536x1536" `
  -DryRun
```

## 行为约束

- 没有参考图时调用图片生成接口；提供参考图时调用图片编辑接口。
- 输出文件存在时不会自动覆盖，会要求使用新的文件名。
- 不会输出、保存或回显 API Key、接口地址和其他凭据。
- `gpt-image-2` 不支持透明背景；若需要透明 PNG，应改用支持透明背景的其他图片模型。

## 文件结构

```text
cc-image2/
├── SKILL.md                 # Codex 的调用规则与提示词规范
└── scripts/
    └── generate.ps1         # 图片生成/编辑脚本
```

## 版本

当前版本：`1.0.0`
