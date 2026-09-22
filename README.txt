落落资源站 · 免费静态版

文件放置：
- index.html：网站完整页面，直接双击即可预览。
- assets/wechat-qr.png、assets/qq-qr.png：联系方式二维码。
- assets/avatar.jpg：网站头像和浏览器标签页图标。
- profile.html：落的个人介绍页，首页头像和名字可进入。
- tools.html：班级工具导航页，后续可继续添加其他工具。
- class-tool.html：低空2601 班级花名册页面，只能由工具导航页进入。
- supabase-schema.sql：Supabase 数据表、权限函数和班级名单初始化脚本。
- supabase-roster-function.sql：花名册查询及管理员表格管理函数。
- supabase-roster-data.sql：从最新学生信息表提取的花名册字段更新脚本，只导入学号、姓名、性别、手机号和寝室号；寝室号统一为 `楼栋-房间号` 格式，例如 `7-502`。
- supabase-roster-update.sql：将已初始化的旧学号更新为正式学号的迁移脚本。`r`n- supabase-password-update.sql：使用扩展 schema 正确更新班级管理密码。`r`n- supabase-password-update.sql：使用扩展 schema 正确更新班级管理密码。

添加资源：
1. 用记事本或 VS Code 打开 index.html。
2. 找到页面底部的 const resources=[ ... ]。
3. 复制一条大括号 { ... } 中的资源数据并修改内容。
4. url 填入你有权分享的真实公开下载链接。
5. 保存后双击 index.html 测试；部署后上传替换 GitHub 仓库中的同名文件。

联系方式：
- 邮箱：qq116343614qq@163.com
- 页面“找到我”区域可以展开微信和 QQ 二维码。

免费部署：
GitHub 用户名为 llres 时，创建公开仓库 llres.github.io，将本文件和 index.html 上传到仓库根目录；在仓库 Settings > Pages 选择 master 分支和 /(root)。

注意：GitHub Pages 只放网页、图片和小型静态资源。大型整合包、安装包请使用合规的外部文件托管，再把链接写入 url。

班级工具首次配置：
1. 打开 Supabase 项目后台的 SQL Editor。
2. 打开仓库中的 supabase-schema.sql，将第一段插入语句里的“请在执行前替换为你的管理密码”改成你要发给同学的密码，然后执行整个脚本。
3. 部署后从首页底部进入“班级工具”，再从工具箱打开花名册。
4. 同学使用统一管理密码进入花名册，可搜索姓名和学号、按性别筛选；花名册为只读，不提供修改功能。

花名册查询功能：
- 如果基础初始化脚本已经执行成功，请再执行 `supabase-roster-function.sql`。
- 之后从首页点击“班级工具”，输入学号和统一密码即可进入花名册；学号 `26050008` 为唯一管理员。
- 管理员 `26050008` 登录后可以直接编辑姓名、学号、性别、手机号、寝室号，也可以新增和删除人员；普通成员只能查看和搜索。

正式学号更新：
- 新上传的 2026 级注册学籍表对应正式学号为 `26050001` 至 `26050042`。
- 如果已经执行过旧版初始化脚本，请在 SQL Editor 额外执行 `supabase-roster-update.sql`；以后登录使用正式学号。

最新花名册数据导入：
- 如需将最新学生信息表同步到后端，请在执行花名册函数脚本后执行 `supabase-roster-data.sql`。
- 该脚本只写入花名册页面需要的学号、姓名、性别、手机号和寝室号，不会导入身份证号、政治面貌、民族、专业、班级或备注。
- 表格中标注“待确认”的第二个手机号不会导入，只保留已确认的号码。

安全说明：网页中只使用 Supabase publishable key；管理密码以哈希形式保存在数据库中，不写入网页源码。请不要把数据库密码或 service_role key 放进仓库。
