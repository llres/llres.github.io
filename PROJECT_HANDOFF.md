# 落落资源站项目交接文档

这份文档用于把项目交给其他 AI 或开发者继续维护。项目是一个静态 GitHub Pages 网站，班级工具部分通过 Supabase RPC 读取和修改数据。

## 1. 项目基本信息

- 项目仓库：`llres/llres.github.io`
- 线上地址：<https://llres.github.io>
- 默认分支：`master`
- 部署方式：GitHub Pages，直接发布仓库根目录
- 本地项目目录：当前文档所在仓库目录
- 技术栈：HTML、CSS、原生 JavaScript、Supabase JavaScript SDK
- 当前没有 Node.js 构建流程，也没有打包步骤

## 2. 页面结构

| 文件 | 用途 |
| --- | --- |
| `index.html` | 网站首页、个人入口、背景动画、资源概览 |
| `resources.html` | 资源库、搜索、分类筛选、资源卡片 |
| `profile.html` | “落”的个人介绍页 |
| `tools.html` | 总工具箱入口 |
| `class-tools.html` | 班级工具箱，负责一次性登录验证 |
| `class-tool.html` | 低空 2601 班级花名册 |
| `random-picker.html` | 随机点名器 |
| `site-bg.css` | 公共页面背景样式 |
| `assets/` | 头像、二维码等静态资源 |

当前主要跳转链路：

```text
首页/资源页 → 工具箱 → 班级工具箱 → 花名册
                                      → 随机点名器
```

## 3. 班级工具登录机制

`class-tools.html` 是统一验证入口。登录成功后把当前会话写入浏览器的 `sessionStorage`：

```text
classToolSession = {
  studentId,
  password,
  role,
  roster
}
```

花名册和随机点名器读取这个会话，因此正常流程只需要在班级工具箱验证一次。

注意：

- `sessionStorage` 只在当前浏览器标签页有效。
- 关闭标签页后需要重新验证。
- `class-tool.html` 会优先使用会话中的名单快速显示，再后台请求最新名单，避免页面闪烁。
- 随机点名器没有有效会话时不会单独设计第二套登录流程，应返回班级工具箱验证。
- 不要在新的页面中复制一套密码判断逻辑，应复用 `classToolSession` 和 Supabase RPC。

## 4. 权限设计

当前角色有三种：

### 普通成员 `member`

- 可以进入班级工具箱
- 可以查看花名册
- 可以使用随机点名器
- 可以选择性别
- 可以选择已经存在的自定义分组
- 可以勾选临时名单
- 可以设置抽取人数
- 不能新增、删除或修改自定义分组
- 不能增删改查花名册

### 普通管理员 `admin`

- 拥有普通成员全部能力
- 可以增删改查花名册
- 可以在随机点名器中创建自定义分组
- 可以删除自定义分组
- 不能添加或取消其他管理员

### 超级管理员 `super_admin`

- 拥有普通管理员全部能力
- 可以设置普通管理员
- 可以取消普通管理员
- 不能取消超级管理员自己的身份

前端权限控制位置：

- 花名册：`class-tool.html` 的 `admin` 和 `role` 判断
- 超级管理员操作区：`class-tool.html` 的 `adminManage`
- 随机点名器分组管理：`random-picker.html` 的 `canManageGroups`

后端权限控制位置：

- `supabase-roster-function.sql`
- 重点函数：
  - `get_class_role`
  - `get_class_roster`
  - `admin_upsert_student`
  - `admin_delete_student`
  - `set_class_admin`

前端隐藏按钮不是安全边界。任何新增管理操作都必须同时在 Supabase RPC 中做权限校验。

## 5. 随机点名器功能

`random-picker.html` 支持：

- 按性别：不限、男生、女生
- 抽取人数
- 全班范围
- 自定义分组范围
- 临时勾选人员范围
- 同一轮默认不重复
- 重置本轮抽取记录

### 自定义分组规则

- 寝室号只是花名册资料，不再被当成分组。
- 管理员和超级管理员勾选人员后输入分组名称，可以保存分组。
- 分组保存在当前浏览器的 `localStorage`，键名为 `classPickerGroups`。
- 分组目前是浏览器本地配置，不是 Supabase 数据。
- 普通成员可以使用已有分组，但看不到新增和删除分组操作。
- 换浏览器、清理站点数据或使用无痕窗口后，本地分组不会自动同步。

如果未来希望全班共享分组，应新增 Supabase 表和 RPC，不要继续把 `localStorage` 当作共享数据库。

## 6. Supabase 文件与执行顺序

| 文件 | 作用 |
| --- | --- |
| `supabase-schema.sql` | 创建基础表、基础字段、RLS 和初始配置 |
| `supabase-roster-data.sql` | 导入/更新名单字段 |
| `supabase-roster-update.sql` | 旧名单学号更新脚本，通常只执行一次 |
| `supabase-password-update.sql` | 密码哈希更新脚本 |
| `supabase-roster-function.sql` | 当前权限、查询、管理 RPC 的主要脚本 |

首次搭建建议顺序：

1. 执行 `supabase-schema.sql`
2. 按需要执行 `supabase-roster-update.sql`
3. 执行 `supabase-roster-data.sql`
4. 执行 `supabase-password-update.sql`
5. 最后执行最新的 `supabase-roster-function.sql`
6. 执行 `notify pgrst, 'reload schema';`

已有生产数据时，不要随意重复执行带有初始化插入内容的脚本。修改 RPC 后，至少需要重新执行 `supabase-roster-function.sql` 并刷新 PostgREST schema。

## 7. 数据表

主要表：

- `public.class_students`
  - `student_id`
  - `name`
  - `gender`
  - `phone`
  - `dorm`
  - `remark`
  - `updated_at`
- `public.class_settings`
  - 普通成员密码哈希
  - 管理员密码哈希
- `public.class_admins`
  - 普通管理员学号
  - 创建时间

不要把身份证号、民族、政治面貌等不需要的字段导入网站。

## 8. 继续开发时的注意事项

1. GitHub Pages 只能托管静态文件，不能在页面中运行服务端代码。
2. Supabase anon key 可以出现在前端，但所有敏感操作必须由 `security definer` RPC 校验。
3. 不要把服务角色密钥、数据库密码或其他管理密钥写入 HTML。
4. 修改页面后优先运行：

```powershell
git diff --check
git status --short
```

5. 页面发布前检查内部链接：

```text
index.html
resources.html
tools.html
class-tools.html
class-tool.html
random-picker.html
profile.html
```

6. 不要上传大型整合包、安装包、压缩包或原始学生信息表。
7. 修改登录流程时要同时检查三处：
   - `class-tools.html`
   - `class-tool.html`
   - `random-picker.html`
8. 修改角色权限时必须同时更新前端显示和 Supabase RPC。

## 9. 发布流程

当前仓库没有构建命令，修改完成后可以直接提交：

```powershell
git diff --check
git add <需要提交的文件>
git commit -m "描述本次修改"
git push origin master
```

发布后检查：

```text
https://llres.github.io/
https://llres.github.io/resources.html
https://llres.github.io/class-tools.html
https://llres.github.io/class-tool.html
https://llres.github.io/random-picker.html
```

GitHub Pages 有缓存，刚推送的新文件短时间内可能暂时返回旧内容或 404。

## 10. 交接前检查清单

每次转交给新的 AI 或开发者前，建议按下面顺序检查：

1. 确认 `git status --short` 只包含本次准备提交的文件。
2. 执行 `git diff --check`，确保没有空格错误或冲突标记。
3. 检查七个页面都能打开：首页、资源页、工具箱、班级工具箱、花名册、随机点名器、个人介绍页。
4. 使用普通成员账号验证：能打开花名册和随机点名器；能使用性别筛选、人数设置、临时勾选和已有分组；看不到分组新增/删除控件；不能修改花名册。
5. 使用普通管理员账号验证：能增删改查花名册；能新增和删除随机点名分组；不能设置或取消其他管理员。
6. 使用超级管理员账号验证：能增删改查花名册；能设置和取消普通管理员；不能取消 `26050008` 的超级管理员身份。
7. 在 Supabase SQL Editor 中确认最新 RPC 已执行，并执行 `notify pgrst, 'reload schema';`。
8. 发布后检查页面 HTTP 状态和浏览器控制台错误。

已知的维护边界：

- 当前自定义分组只保存在浏览器 `localStorage`，不是全班共享数据。
- 当前会话会在当前标签页 `sessionStorage` 中保存密码；不要把会话对象改存到 `localStorage`。
- 前端隐藏按钮不是权限安全边界，所有管理 RPC 必须继续在数据库函数内部校验角色。
- `supabase-roster-function.sql` 中的函数授权给匿名客户端是静态站点所需设计，安全性依赖函数内部的密码和角色校验。
- 不要把 Supabase service role key、数据库密码或学生原始表格上传到公开仓库。

## 11. 建议的后续改进

- 把重复的内联 CSS 和 JavaScript 抽成公共文件。
- 将随机点名器的分组从 `localStorage` 迁移到 Supabase，实现全班共享。
- 为分组增加创建者、更新时间和删除权限记录。
- 在花名册中增加管理员操作日志。
- 将前端会话改为短时有效，并提供主动退出按钮。
- 增加移动端真实浏览器测试。
- 清理 `README.txt` 中早期历史说明，统一维护入口改为本交接文档。

