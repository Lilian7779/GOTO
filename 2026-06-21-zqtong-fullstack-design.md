# 政企通全栈升级设计文档

> 日期：2026-06-21 | 团队：老A/Vue哥/Node叔/SQL姐/盾哥/运维仔

## 1. 项目概述

将政企通从9个静态HTML页面升级为生产级全栈应用，包含前端展示端、管理后台、用户系统、数据库、PWA客户端。

## 2. 技术选型

**方案三：Supabase + 现有HTML改造**

| 层 | 技术 | 说明 |
|----|------|------|
| 数据库 | Supabase PostgreSQL | 免费500MB，内置Row Level Security |
| 鉴权 | Supabase Auth | 邮箱注册登录，企业认证 |
| API | Supabase JS SDK | 前端直接调用，零后端代码 |
| 前端 | 现有HTML/CSS/JS + Supabase SDK | 增量改造，保留现有设计 |
| 存储 | Supabase Storage | 证照模板、表单文件 |
| 托管 | GitHub Pages | 免费静态托管 |
| PWA | manifest.json + Service Worker | 可安装、离线缓存 |
| 域名 | zqtong.cn | ¥29-39/年 |

## 3. 数据库设计

### 核心数据表（8张）

| 表名 | 对应页面 | 核心字段 |
|------|----------|----------|
| policies | policy.html | title, region, industry[], biz_type[], subsidy_type, amount, deadline, conditions, tags[], status |
| services | service.html | name, category, rating, price, description, phone, tags[] |
| ip_items | ip.html | type, name, fee_range, duration, steps(jsonb), tags[] |
| software_list | software.html | name, industry[], features[], price, trial_url, rating |
| offices | office.html | title, region, area_type, size, price, subsidy, address, vr_url |
| licenses | license.html | name, conditions, materials(jsonb), process(jsonb), duration, price |
| guide_industries | guide.html | name, steps(jsonb), authority, phone, address, form_links[] |
| newco_tasks | newco.html | day, title, description, action_url, category |

### 用户相关表（4张）

| 表名 | 说明 | 核心字段 |
|------|------|----------|
| profiles | 用户档案(关联auth.users) | company_name, contact, phone, biz_type, industry |
| favorites | 收藏 | user_id, target_type, target_id |
| tickets | 咨询工单 | user_id, type, title, content, status, created_at |
| admin_users | 管理员标识 | user_id, role(super/editor) |

## 4. 管理端 admin.html

- 侧边栏导航：9个模块（8个数据管理 + 仪表盘）
- 每个模块：表格CRUD + 搜索筛选 + 批量操作
- 仪表盘：政策数/服务商数/工单量/用户数统计卡片
- 鉴权：Supabase RLS，仅admin_users表中用户可访问

## 5. 前端改造

- index.html + 8个详情页：数据源从硬编码改为Supabase JS SDK动态拉取
- 页面间跳转保持现有window.location.href方式
- 新增：登录/注册按钮、收藏功能(❤)、工单提交弹窗
- 搜索区4个字段联动数据库筛选

## 6. PWA

- manifest.json：应用名"政企通"、图标、全屏模式
- sw.js：缓存核心页面，离线可用
- 各页面注入注册代码

## 7. 实施顺序

| Phase | 内容 | 预估 |
|-------|------|------|
| Phase 1 | 建表SQL + Supabase初始化 | 2h |
| Phase 2 | admin.html管理端 | 4h |
| Phase 3 | 前端页面改造 | 3h |
| Phase 4 | PWA + 部署上线 | 1h |

## 8. 待授权项

- Supabase账号注册（需邮箱）
- 域名购买 zqtong.cn（¥29-39/年）
