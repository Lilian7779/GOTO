# 政企通 部署指南

三步将网站部署到 GitHub Pages 并绑定自定义域名。

---

## 第一步：推送到 GitHub

在 output 目录下执行：

```bash
git init
git add .
git commit -m "政企通 PWA 全栈部署"
git branch -M main
git remote add origin https://github.com/<你的用户名>/zqtong.git
git push -u origin main
```

> 也可以在 GitHub 网页端直接上传：进入仓库 → **Add file** → **Upload files**，将 output 目录下所有文件拖入。

---

## 第二步：开启 GitHub Pages

1. 进入仓库 **Settings** → **Pages**
2. **Source** 选择 **Deploy from a branch**
3. **Branch** 选择 `main`，目录选 `/ (root)`
4. 点击 **Save**，等待 1-2 分钟

部署成功后访问：`https://<你的用户名>.github.io/zqtong/`

---

## 第三步：绑定自定义域名（可选）

1. 仓库 **Settings** → **Pages** → **Custom domain** 填入域名，点击 **Save**
2. 在 DNS 服务商处添加 CNAME 记录：
   - **记录类型**: CNAME
   - **主机记录**: 子域名前缀（如 `zqtong`）
   - **记录值**: `<你的用户名>.github.io`
3. 等待 DNS 生效（10 分钟~24 小时），勾选 **Enforce HTTPS**

> 也可直接编辑仓库根目录的 `CNAME` 文件写入域名，GitHub Pages 会自动识别。

---

## 前置条件

部署前请确认已完成 Supabase 配置：
- 在 [supabase.com](https://supabase.com) 创建项目并执行 `schema.sql` 建表
- 修改 `supabase-client.js` 中的 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY`
- 在 Supabase SQL Editor 中执行 `INSERT INTO admin_users ...` 设置管理员

详请参考项目中的 `schema.sql` 文件。
