-- ============================================================================
-- 政企通 (ZQTong) 全栈升级 Phase 1 — 数据库建表SQL
-- 目标数据库: Supabase PostgreSQL 15+
-- 执行方式: 在 Supabase SQL Editor 中逐段执行或整体执行
-- ============================================================================

-- 0. 扩展启用 ----------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. 核心数据表 (8张)
-- ============================================================================

-- 1.1 惠企政策表 ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS policies (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title       TEXT NOT NULL,                          -- 政策标题
    region      TEXT NOT NULL DEFAULT '南通市',         -- 适用区域
    industry    TEXT NOT NULL DEFAULT '通用',           -- 适用行业
    policy_type TEXT NOT NULL DEFAULT '资金补贴',       -- 政策类型: 资金补贴/税收优惠/人才引进/资质认定
    enterprise_scale TEXT DEFAULT '不限',              -- 企业规模: 不限/小微/中型/大型/专精特新
    description TEXT,                                   -- 政策描述
    conditions  TEXT,                                   -- 申报条件
    amount      TEXT,                                   -- 补贴/优惠金额
    deadline    DATE,                                   -- 申报截止日期
    source_dept TEXT,                                   -- 发文部门
    doc_url     TEXT,                                   -- 原文链接
    tags        TEXT[] DEFAULT '{}',                    -- 标签数组
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 1.2 企业服务商表 ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS services (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,                          -- 服务商名称
    category    TEXT NOT NULL,                          -- 分类: 财税/法律/审计/税务
    description TEXT,                                   -- 服务描述
    price_range TEXT,                                   -- 价格区间
    rating      NUMERIC(3,1) DEFAULT 4.0,              -- 评分 (1.0-5.0)
    review_count INTEGER DEFAULT 0,                    -- 评价数
    contact     TEXT,                                   -- 联系方式
    website     TEXT,                                   -- 官网
    tags        TEXT[] DEFAULT '{}',
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 1.3 知识产权表 ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ip_items (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,                          -- 名称
    category    TEXT NOT NULL,                          -- 分类: 商标/发明专利/实用新型专利/外观专利/软著/贯标
    description TEXT,                                   -- 说明
    fee_range   TEXT,                                   -- 费用区间
    cycle_days  INTEGER,                                -- 办理周期(天)
    process_steps TEXT[],                               -- 办理流程步骤
    requirements TEXT,                                  -- 申请要求
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 1.4 企业软件推荐表 --------------------------------------------------------
CREATE TABLE IF NOT EXISTS software_list (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,                          -- 软件名称
    category    TEXT NOT NULL,                          -- 分类: 通用办公/建筑施工/餐饮服务/信息技术/商贸物流/油气贸易
    subcategory TEXT,                                   -- 子分类: OA/CRM/ERP/财务/项目管理
    description TEXT,                                   -- 功能描述
    pricing     TEXT,                                   -- 价格方案
    trial_url   TEXT,                                   -- 试用链接
    features    TEXT[],                                 -- 功能特性
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 1.5 办公房源表 ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS offices (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title       TEXT NOT NULL,                          -- 房源标题
    region      TEXT NOT NULL DEFAULT '崇川区',         -- 区域
    address     TEXT,                                   -- 详细地址
    area_sqm    NUMERIC(8,1),                           -- 面积(平米)
    price_month NUMERIC(10,2),                          -- 月租金(元)
    property_type TEXT DEFAULT '写字楼',                -- 类型: 写字楼/产业园/众创空间/孵化器
    subsidy     TEXT,                                   -- 补贴说明
    vr_url      TEXT,                                   -- VR看房链接
    tags        TEXT[] DEFAULT '{}',
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 1.6 证照办理表 ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS licenses (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        TEXT NOT NULL,                          -- 证照名称
    category    TEXT,                                   -- 分类
    conditions  TEXT,                                   -- 办理条件
    materials   TEXT[],                                 -- 所需材料
    process     TEXT[],                                 -- 办理流程
    duration_days INTEGER,                              -- 办理时限(天)
    fee         TEXT,                                   -- 费用说明
    dept        TEXT,                                   -- 主管部门
    apply_url   TEXT,                                   -- 线上办理链接
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 1.7 行业办事指南表 --------------------------------------------------------
CREATE TABLE IF NOT EXISTS guide_industries (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    industry    TEXT NOT NULL,                          -- 行业名称
    steps       TEXT[],                                 -- 设立步骤
    timeline    JSONB,                                  -- 时间线 [{day:1, task:"..."}, ...]
    dept        TEXT,                                   -- 主管部门
    forms       JSONB,                                  -- 表单下载 [{name:"",url:""}]
    notes       TEXT,                                   -- 注意事项
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 1.8 新公司必做任务表 ------------------------------------------------------
CREATE TABLE IF NOT EXISTS newco_tasks (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    day_num     INTEGER NOT NULL,                       -- 第几天 (1-30)
    task        TEXT NOT NULL,                          -- 任务描述
    category    TEXT DEFAULT '通用',                    -- 分类
    detail      TEXT,                                   -- 详细说明
    action_url  TEXT,                                   -- 办理入口
    sort_order  INTEGER DEFAULT 0,
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 2. 用户相关表 (4张)
-- ============================================================================

-- 2.1 用户档案表 (关联 Supabase auth.users) --------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email       TEXT,
    full_name   TEXT,
    company     TEXT,                                   -- 公司名称
    phone       TEXT,
    region      TEXT DEFAULT '南通市',
    industry    TEXT,
    role        TEXT DEFAULT 'user',                    -- user / admin
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 2.2 收藏表 ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS favorites (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_type   TEXT NOT NULL,                          -- policy / service / ip / software / office / license
    item_id     UUID NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, item_type, item_id)
);

-- 2.3 工单/反馈表 -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS tickets (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    content     TEXT,
    category    TEXT DEFAULT '咨询',                    -- 咨询/建议/投诉/其他
    status      TEXT DEFAULT '待处理',                  -- 待处理/处理中/已回复/已关闭
    reply       TEXT,                                   -- 管理员回复
    replied_by  UUID REFERENCES auth.users(id),
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 2.4 管理员表 --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_users (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    email       TEXT NOT NULL,
    role        TEXT DEFAULT 'editor',                  -- super_admin / editor / viewer
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 3. 索引
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_policies_region       ON policies(region);
CREATE INDEX IF NOT EXISTS idx_policies_industry      ON policies(industry);
CREATE INDEX IF NOT EXISTS idx_policies_type          ON policies(policy_type);
CREATE INDEX IF NOT EXISTS idx_policies_deadline      ON policies(deadline);
CREATE INDEX IF NOT EXISTS idx_services_category      ON services(category);
CREATE INDEX IF NOT EXISTS idx_ip_items_category      ON ip_items(category);
CREATE INDEX IF NOT EXISTS idx_software_category      ON software_list(category);
CREATE INDEX IF NOT EXISTS idx_offices_region         ON offices(region);
CREATE INDEX IF NOT EXISTS idx_favorites_user         ON favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_type_item    ON favorites(item_type, item_id);
CREATE INDEX IF NOT EXISTS idx_tickets_user           ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_users_user       ON admin_users(user_id);

-- ============================================================================
-- 4. RLS (Row Level Security) 策略
-- ============================================================================

-- 4.1 辅助函数: 判断当前用户是否为管理员 ------------------------------------
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.2 policies 表 RLS -------------------------------------------------------
ALTER TABLE policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON policies
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON policies
    FOR SELECT TO authenticated
    USING (true);

-- 4.3 services 表 RLS -------------------------------------------------------
ALTER TABLE services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON services
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON services
    FOR SELECT TO authenticated
    USING (true);

-- 4.4 ip_items 表 RLS -------------------------------------------------------
ALTER TABLE ip_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON ip_items
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON ip_items
    FOR SELECT TO authenticated
    USING (true);

-- 4.5 software_list 表 RLS -------------------------------------------------
ALTER TABLE software_list ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON software_list
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON software_list
    FOR SELECT TO authenticated
    USING (true);

-- 4.6 offices 表 RLS --------------------------------------------------------
ALTER TABLE offices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON offices
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON offices
    FOR SELECT TO authenticated
    USING (true);

-- 4.7 licenses 表 RLS -------------------------------------------------------
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON licenses
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON licenses
    FOR SELECT TO authenticated
    USING (true);

-- 4.8 guide_industries 表 RLS ----------------------------------------------
ALTER TABLE guide_industries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON guide_industries
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON guide_industries
    FOR SELECT TO authenticated
    USING (true);

-- 4.9 newco_tasks 表 RLS ---------------------------------------------------
ALTER TABLE newco_tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON newco_tasks
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "普通用户只读" ON newco_tasks
    FOR SELECT TO authenticated
    USING (true);

-- 4.10 profiles 表 RLS -----------------------------------------------------
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON profiles
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "用户读写自己的数据" ON profiles
    FOR ALL TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4.11 favorites 表 RLS ----------------------------------------------------
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON favorites
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "用户读写自己的收藏" ON favorites
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4.12 tickets 表 RLS ------------------------------------------------------
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "管理员全读写" ON tickets
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "用户读写自己的工单" ON tickets
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 4.13 admin_users 表 RLS --------------------------------------------------
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "仅管理员可读写" ON admin_users
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

-- 4.14 匿名用户允许读取公开数据 ---------------------------------------------
CREATE POLICY "匿名用户只读" ON policies
    FOR SELECT TO anon USING (true);
CREATE POLICY "匿名用户只读" ON services
    FOR SELECT TO anon USING (true);
CREATE POLICY "匿名用户只读" ON ip_items
    FOR SELECT TO anon USING (true);
CREATE POLICY "匿名用户只读" ON software_list
    FOR SELECT TO anon USING (true);
CREATE POLICY "匿名用户只读" ON offices
    FOR SELECT TO anon USING (true);
CREATE POLICY "匿名用户只读" ON licenses
    FOR SELECT TO anon USING (true);
CREATE POLICY "匿名用户只读" ON guide_industries
    FOR SELECT TO anon USING (true);
CREATE POLICY "匿名用户只读" ON newco_tasks
    FOR SELECT TO anon USING (true);

-- ============================================================================
-- 5. 触发器: 自动更新 updated_at
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为所有核心表创建 updated_at 触发器
CREATE TRIGGER trg_policies_updated_at   BEFORE UPDATE ON policies        FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_services_updated_at   BEFORE UPDATE ON services        FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_ip_items_updated_at   BEFORE UPDATE ON ip_items        FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_software_updated_at   BEFORE UPDATE ON software_list   FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_offices_updated_at    BEFORE UPDATE ON offices         FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_licenses_updated_at   BEFORE UPDATE ON licenses        FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_guide_updated_at      BEFORE UPDATE ON guide_industries FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_newco_updated_at      BEFORE UPDATE ON newco_tasks     FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_profiles_updated_at   BEFORE UPDATE ON profiles        FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_tickets_updated_at    BEFORE UPDATE ON tickets         FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- 6. 函数: 新用户注册自动创建 profile
-- ============================================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, full_name, role)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), 'user');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 当 auth.users 插入新行时自动触发
CREATE OR REPLACE TRIGGER trg_new_user_profile
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- 7. 种子数据
-- ============================================================================

-- 7.1 policies 种子数据 -----------------------------------------------------
INSERT INTO policies (title, region, industry, policy_type, enterprise_scale, description, conditions, amount, deadline, source_dept, tags) VALUES
('南通市小微企业创业补贴',         '南通市', '通用',   '资金补贴', '小微', '对新注册小微企业给予一次性创业补贴，支持初创企业发展', '注册不满2年/正常经营6个月以上/社保缴纳正常', '最高5万元', '2027-12-31', '南通市人社局',      ARRAY['创业','小微','补贴']),
('崇川区科技创新专项资金',         '崇川区', '信息技术','资金补贴','不限', '支持企业开展科技研发，对获得专利或软著的企业给予资金支持', '拥有自主知识产权/研发投入占比>5%', '10-50万元', '2027-06-30', '崇川区科技局',      ARRAY['科技','创新','研发']),
('南通市人才引进安家补贴',         '南通市', '通用',   '人才引进','不限', '对引进高层次人才的企业给予安家补贴和薪酬补助', '引进硕士及以上学历人才/签订3年以上合同', '每人3-20万元', '2027-12-31', '南通市人才办',      ARRAY['人才','安家','高层次']),
('开发区高新技术企业认定奖励',      '开发区', '信息技术','资质认定','不限', '对首次通过高新技术企业认定的企业给予一次性奖励', '通过高新技术企业认定/开发区内注册', '30万元', '2027-09-30', '开发区经发局',      ARRAY['高新','认定','奖励']),
('通州区建筑业转型升级补贴',        '通州区', '建筑施工','资金补贴','中型', '支持建筑企业向绿色建筑、智能建造方向转型升级', '建筑施工资质/有在建绿色项目', '10-30万元', '2027-08-31', '通州区住建局',      ARRAY['建筑','绿色','转型']),
('海门区商贸物流发展扶持',          '海门区', '商贸物流','税收优惠','不限', '对在海门区注册的商贸物流企业给予税收减免和运费补贴', '年营收超500万/海门区纳税', '税收减免30%', '2027-12-31', '海门区商务局',      ARRAY['商贸','物流','税收']),
('南通市专精特新企业培育计划',      '南通市', '通用',   '资质认定','专精特新','对入选专精特新培育库的企业提供阶梯式奖励和专项服务', '细分市场占有率排名前三/研发占比>8%', '50-200万元', '2027-11-30', '南通市工信局',      ARRAY['专精特新','培育','奖励']),
('崇川区餐饮业数字化改造补贴',      '崇川区', '餐饮服务','资金补贴','小微', '支持餐饮企业进行数字化升级，包括外卖平台搭建、智能点餐系统', '持有食品经营许可证/有实体门店', '最高3万元', '2027-06-30', '崇川区商务局',      ARRAY['餐饮','数字化','补贴']),
('南通市油气贸易合规奖励',          '南通市', '油气贸易','税收优惠','不限', '对合规经营的油气贸易企业给予增值税返还奖励', '持有危化品经营许可证/纳税信用A级', '增值税返还20%', '2027-12-31', '南通市商务局',      ARRAY['油气','贸易','合规']),
('开发区生物医药研发资助',          '开发区', '医疗器械','资金补贴','中型', '支持医疗器械企业开展二类以上医疗器械研发', '具备医疗器械生产许可/有在研项目', '20-100万元', '2027-10-31', '开发区科技局',      ARRAY['医药','研发','医疗器械']),
('南通市教育培训机构规范补贴',      '南通市', '教育培训','资金补贴','小微', '对通过规范验收的教育培训机构给予场地租金补贴', '取得办学许可证/通过年度检查', '每年最高5万元', '2027-09-30', '南通市教育局',      ARRAY['教育','培训','规范']),
('崇川区中小企业贷款贴息',          '崇川区', '通用',   '资金补贴','小微', '对崇川区小微企业银行贷款给予利息补贴', '崇川区注册/有银行贷款/信用良好', '贴息50%，最高10万', '2027-12-31', '崇川区金融局', ARRAY['贷款','贴息','中小微']);

-- 7.2 services 种子数据 -----------------------------------------------------
INSERT INTO services (name, category, description, price_range, rating, review_count, contact, tags) VALUES
('南通正信财税咨询有限公司',   '财税', '专注中小企业代理记账、税务筹划、财务外包，10年行业经验', '500-3000元/月', 4.8, 156, '0513-8500-0001', ARRAY['代理记账','税务筹划','财务外包']),
('南通百富财务服务有限公司',   '财税', '一站式企业财税服务，含工商注册、变更、注销全流程', '300-2000元/月', 4.5, 89,  '0513-8500-0002', ARRAY['工商注册','代理记账','变更注销']),
('江苏大成(南通)律师事务所',   '法律', '全国知名律所，提供企业法律顾问、合同审查、诉讼代理', '5000-20000元/年', 4.9, 203, '0513-8500-0003', ARRAY['法律顾问','合同审查','诉讼代理']),
('南通通商律师事务所',         '法律', '本土精品律所，擅长公司法、劳动法、知识产权领域', '3000-15000元/年', 4.6, 112, '0513-8500-0004', ARRAY['公司法','劳动法','知识产权']),
('南通诚信审计事务所',         '审计', '专业财务审计、内控审计、专项审计服务', '2000-8000元/次', 4.7, 78,  '0513-8500-0005', ARRAY['财务审计','内控审计','专项审计']),
('南通公正会计师事务所',       '审计', 'AAA级会计师事务所，上市公司审计资质', '5000-30000元/次', 4.9, 134, '0513-8500-0006', ARRAY['上市公司审计','年审','验资']),
('南通金税通税务师事务所',     '税务', '税务咨询、汇算清缴、税务争议解决', '1000-5000元/次', 4.4, 67,  '0513-8500-0007', ARRAY['税务咨询','汇算清缴','争议解决']),
('南通安信税务顾问有限公司',   '税务', '提供企业全生命周期税务规划与合规管理', '800-4000元/月', 4.3, 45,  '0513-8500-0008', ARRAY['税务规划','合规管理','申报代理']),
('南通企航财务顾问有限公司',   '财税', '互联网+财税服务，线上实时查账、智能报税', '200-1500元/月', 4.6, 201, '0513-8500-0009', ARRAY['智能报税','线上查账','财税顾问']),
('南通中瑞税务师事务所',       '税务', '专注外贸企业出口退税和跨境税务服务', '2000-10000元/次', 4.7, 56,  '0513-8500-0010', ARRAY['出口退税','跨境税务','外汇管理']),
('江苏君泽(南通)律师事务所',   '法律', '专注企业并购、投融资、IPO等资本市场法律服务', '10000-50000元/年', 4.8, 89, '0513-8500-0011', ARRAY['并购','投融资','IPO']),
('南通天健会计师事务所',       '审计', '专注中小企业年审和专项审计，价格实惠', '1500-5000元/次', 4.5, 93,  '0513-8500-0012', ARRAY['年审','专项审计','验资报告']);

-- 7.3 ip_items 种子数据 -----------------------------------------------------
INSERT INTO ip_items (name, category, description, fee_range, cycle_days, process_steps, requirements) VALUES
('商标注册',       '商标',        '国内商标注册，含查询、申请、公告全流程', '300-800元/类', 270, ARRAY['商标查询','提交申请','形式审查','实质审查','初审公告','注册公告'], '自然人/法人均可申请'),
('发明专利',       '发明专利',    '发明专利申请，含实质审查', '4000-8000元', 540, ARRAY['提交申请','初步审查','公布','实质审查','授权公告'], '具有新颖性、创造性、实用性'),
('实用新型专利',   '实用新型专利','实用新型专利申请，审查周期较短', '2000-4000元', 240, ARRAY['提交申请','初步审查','授权公告'], '产品的形状、构造或其结合'),
('外观设计专利',   '外观专利',    '外观设计专利申请', '1500-3000元', 180, ARRAY['提交申请','初步审查','授权公告'], '富有美感并适于工业应用'),
('软件著作权登记', '软著',        '计算机软件著作权登记', '300-1000元', 60,  ARRAY['准备材料','提交申请','受理','审查','登记发证'], '原创软件/源代码和用户文档'),
('知识产权贯标',   '贯标',        '企业知识产权管理体系认证', '15000-30000元', 180, ARRAY['启动','诊断','体系构建','运行','内审','管理评审','认证审核'], '企业正常经营1年以上');

-- 7.4 software_list 种子数据 -------------------------------------------------
INSERT INTO software_list (name, category, subcategory, description, pricing, trial_url, features) VALUES
('钉钉',       '通用办公', 'OA',    '阿里旗下企业协作平台，含IM、审批、考勤、视频会议', '免费/专业版9800元/年', 'https://www.dingtalk.com', ARRAY['IM即时通讯','OA审批','考勤打卡','视频会议','云盘']),
('企业微信',   '通用办公', 'OA',    '腾讯企业通讯与办公平台，与微信互通', '免费/高级功能按需付费', 'https://work.weixin.qq.com', ARRAY['微信互通','客户群','审批','汇报','日程']),
('用友U8 cloud','通用办公','ERP', '用友云ERP，适合成长型企业的全面管理', '按模块按年订阅', 'https://www.yonyou.com', ARRAY['财务','供应链','生产制造','人力资源']),
('广联达',     '建筑施工', '造价',  '建筑行业工程造价软件，全国定额', '按年订阅/约6000元/年', 'https://www.glodon.com', ARRAY['土建算量','安装算量','计价','BIM']),
('客如云',     '餐饮服务', '收银',  '餐饮SaaS收银系统，含点餐、外卖、会员', '约2000元/年', 'https://www.keruyun.com', ARRAY['扫码点餐','外卖对接','会员管理','库存管理']),
('金蝶云星辰','信息技术', '财务',  '小微企业云财务软件，含税务申报', '约1000元/年起', 'https://www.kingdee.com', ARRAY['智能记账','一键报税','发票管理','经营分析']),
('管家婆',     '商贸物流', '进销存','商贸流通行业进销存管理经典软件', '约1500元/年起', 'https://www.grasp.com.cn', ARRAY['进货管理','销售管理','库存管理','财务报表']),
('飞书',       '通用办公', 'OA',    '字节跳动旗下协作平台，文档+IM+日历一体', '免费/企业版按需付费', 'https://www.feishu.cn', ARRAY['多维表格','飞书文档','视频会议','审批']),
('畅捷通T+',  '商贸物流', 'ERP',   '用友旗下小微企业云ERP', '约3000元/年起', 'https://www.chanjet.com', ARRAY['财务','进销存','生产','分销']),
('石投行',     '油气贸易', '交易',  '油气石化产品在线交易撮合平台SaaS', '按交易量付费', 'https://www.shitouxing.com', ARRAY['在线撮合','合同管理','物流跟踪','结算']),
('餐道',       '餐饮服务', '外卖',  '餐饮外卖全渠道管理，对接美团/饿了么', '约3000元/年起', 'https://www.candao.com', ARRAY['外卖接单','多平台管理','数据分析','营销']),
('明源云',     '建筑施工', 'ERP',   '地产建筑行业ERP，项目全周期管理', '按模块按年', 'https://www.mingyuanyun.com', ARRAY['成本管理','计划运营','采购招投标','质量安全']),
('法大大',     '通用办公', '合同',  '电子合同签署与管理平台', '约2000元/年起', 'https://www.fadada.com', ARRAY['电子签章','合同管理','实名认证','存证']),
('有道云笔记', '通用办公', '笔记',  '网易出品云端知识管理工具', '免费/会员198元/年', 'https://note.youdao.com', ARRAY['多端同步','Markdown','OCR','协作']),
('石墨文档',   '通用办公', '文档',  '云端Office套件，多人实时协作', '免费/企业版按需', 'https://shimo.im', ARRAY['在线文档','表格','幻灯片','表单']),
('SharePoint', '通用办公', '协作',  '微软企业内容管理与协作平台', 'Office 365套餐含', 'https://www.microsoft.com/sharepoint', ARRAY['文档管理','团队网站','工作流','搜索']),
('能源通',     '油气贸易', '交易',  '油气能源垂直领域资讯+交易平台', '免费注册/高级会员付费', 'https://www.energy.net.cn', ARRAY['行情资讯','交易撮合','行业数据','企业库']);

-- 7.5 offices 种子数据 ------------------------------------------------------
INSERT INTO offices (title, region, address, area_sqm, price_month, property_type, subsidy, tags) VALUES
('南通国际大厦A座',        '崇川区', '工农路88号',       120.0, 6000,  '写字楼', '小微首年租金补贴30%',        ARRAY['地铁口','精装','24h空调']),
('崇川科技园3号楼',        '崇川区', '世纪大道168号',    80.0,  3600,  '产业园', '科技企业房租减免50%',        ARRAY['孵化器','共享会议室','免费停车']),
('南通金融中心',           '崇川区', '青年中路256号',    200.0, 12000, '写字楼', '金融类企业税收优惠',          ARRAY['甲级写字楼','江景','食堂']),
('开发区智造园',           '开发区', '通盛大道100号',    300.0, 9000,  '产业园', '制造业租金补贴最高20万/年',  ARRAY['高标准厂房','物流便利','人才公寓']),
('通州湾科创城',           '通州区', '通州湾示范区',      150.0, 4500,  '众创空间','创业团队免租6个月',         ARRAY['众创空间','创业咖啡','路演厅']),
('海门叠石桥电商园',       '海门区', '叠石桥国际家纺城', 60.0,  1800,  '孵化器', '电商企业免租1年',             ARRAY['直播基地','仓储物流','培训']),
('南通中央商务区',         '崇川区', '工农南路128号',    150.0, 9000,  '写字楼', '总部经济奖励',                ARRAY['CBD核心','配套齐全','五星物业']),
('如东洋口港产业园',       '开发区', '洋口港临港工业区',  500.0, 12000, '产业园', '临港产业专项扶持',            ARRAY['临港','仓储','危化品许可']),
('崇川创客空间',           '崇川区', '青年东路99号',     40.0,  1200,  '众创空间','大学生创业免租12个月',       ARRAY['联合办公','咖啡吧','导师服务']);

-- 7.6 licenses 种子数据 -----------------------------------------------------
INSERT INTO licenses (name, category, conditions, materials, process, duration_days, fee, dept, apply_url) VALUES
('营业执照',           '工商', '公司名称预核准/注册地址/经营范围',            ARRAY['公司登记申请书','章程','股东身份证明','住所证明'],         ARRAY['名称预核准','网上提交','窗口递交','领取执照'],       3,   '免费',      '市场监管局', 'https://www.gsxt.gov.cn'),
('食品经营许可证',     '食药', '持有营业执照/经营场所符合卫生要求',            ARRAY['申请书','营业执照','健康证','经营场所平面图'],             ARRAY['提交申请','现场核查','审批','领证'],                 20,  '免费',      '市场监管局', ''),
('危化品经营许可证',   '安监', '持有营业执照/安全管理制度/专业人员资质',        ARRAY['申请书','安全评价报告','应急预案','人员资质'],             ARRAY['提交申请','专家评审','现场核查','审批发证'],          30,  '3000-5000','应急管理局', ''),
('建筑业企业资质',     '住建', '净资产/技术人员/工程业绩达标',                  ARRAY['资质申请表','营业执照','人员证书','社保'],                ARRAY['网上申报','窗口受理','专家审查','公示','领证'],      45,  '按级别',   '住建局',     ''),
('医疗器械经营许可证', '药监', '经营场所/仓库/质量管理人员',                    ARRAY['申请表','营业执照','人员资质','经营场所证明'],             ARRAY['提交材料','现场验收','审批','发证'],                  30,  '免费',      '药监局',     ''),
('人力资源服务许可证', '人社', '5名以上持证人员/固定经营场所/注册资本',         ARRAY['申请书','营业执照','人员证书','管理制度'],               ARRAY['提交申请','审核','现场考察','颁证'],                  20,  '免费',      '人社局',     ''),
('办学许可证',         '教育', '符合办学条件/师资/设施',                        ARRAY['申办报告','资产证明','教师资质','办学章程'],             ARRAY['筹设申请','正式设立','专家评议','审批发证'],          90,  '免费',      '教育局',     ''),
('进出口经营权',       '商务', '持有营业执照/完成海关备案',                     ARRAY['对外贸易经营者备案表','营业执照','法人身份证明'],          ARRAY['商务局备案','海关备案','外汇管理局备案','税务备案'],   15,  '免费',      '商务局',     'https://www.singlewindow.cn');

-- 7.7 guide_industries 种子数据 ---------------------------------------------
INSERT INTO guide_industries (industry, steps, timeline, dept, forms, notes) VALUES
('建筑施工', ARRAY['工商注册','建筑业资质申请','安全生产许可证','招投标备案','项目报建','施工许可'], '{"steps":[{"day":1,"task":"公司名称预核准"},{"day":3,"task":"工商注册领取营业执照"},{"day":10,"task":"办理建筑业企业资质（房建/市政/装饰等）"},{"day":30,"task":"取得安全生产许可证"}]}', '住建局/行政审批局', '{"forms":[{"name":"建筑业企业资质申请表","url":"https://jzsc.mohurd.gov.cn"},{"name":"安全生产许可证申请表","url":"https://jzsc.mohurd.gov.cn"}]}', '建筑施工企业必须取得资质证书和安全生产许可证后方可承接工程'),
('餐饮服务', ARRAY['工商注册','食品经营许可证','消防安全检查','环保备案','员工健康证','开业'], '{"steps":[{"day":1,"task":"公司核名与注册"},{"day":5,"task":"办理食品经营许可证"},{"day":15,"task":"消防安全检查合格"},{"day":20,"task":"员工办理健康证"},{"day":25,"task":"试营业与正式开业"}]}', '市场监管局/消防大队/卫健委', '{"forms":[{"name":"食品经营许可申请书","url":"http://scjgj.nantong.gov.cn"}]}', '餐饮企业须通过消防验收后方可营业，操作间面积不低于总面积的1/4'),
('信息技术', ARRAY['工商注册','软件著作权登记','高新技术企业认定（可选）','ICP许可证（如需）','等保备案'], '{"steps":[{"day":1,"task":"公司注册"},{"day":10,"task":"软著登记"},{"day":60,"task":"高新技术企业认定准备"}]}', '科技局/通管局/网信办', '{"forms":[{"name":"高新技术企业认定申请书","url":"https://www.innocom.gov.cn"}]}', '信息技术企业建议尽早申请软著和专利，为高新认定做准备'),
('商贸物流', ARRAY['工商注册','道路运输许可证','仓储消防验收','税务登记（一般纳税人）','银行开户'], '{"steps":[{"day":1,"task":"公司注册"},{"day":7,"task":"道路运输许可证办理"},{"day":15,"task":"一般纳税人资格认定"},{"day":20,"task":"仓储消防验收"}]}', '交通运输局/税务局/消防大队', '{"forms":[{"name":"道路货物运输经营申请表","url":"http://jtysj.nantong.gov.cn"}]}', '商贸物流企业办理一般纳税人后可开具增值税专用发票'),
('油气贸易', ARRAY['工商注册','危化品经营许可证','进出口经营权','税务登记','银行开户','油品经营备案'], '{"steps":[{"day":1,"task":"公司注册（含危化品经营范围的营业执照）"},{"day":5,"task":"危化品经营许可证申请"},{"day":20,"task":"进出口经营权办理"},{"day":30,"task":"油品经营备案完成"}]}', '应急管理局/商务局/海关', '{"forms":[{"name":"危险化学品经营许可证申请表","url":"http://ajj.nantong.gov.cn"}]}', '油气贸易企业必须先取得危化品经营许可证方可经营，主要负责人和安全管理人员须持证上岗');

-- 7.8 newco_tasks 种子数据 --------------------------------------------------
INSERT INTO newco_tasks (day_num, task, category, detail, action_url, sort_order) VALUES
(1,  '公司名称预核准',       '工商', '准备3-5个备选名称，登录市场监管局网站提交核名申请', 'https://www.gsxt.gov.cn', 1),
(2,  '确定注册地址',         '行政', '确认办公场所，获取房产证复印件和租赁合同', '', 2),
(3,  '提交工商注册材料',     '工商', '准备章程、股东决议、任职文件等材料线上提交', 'https://www.gsxt.gov.cn', 3),
(4,  '领取营业执照',         '工商', '带法人身份证到行政审批局窗口领取正副本', '', 4),
(5,  '刻制公章',             '行政', '到公安局指定刻章点刻制公章/财务章/法人章/发票章', '', 5),
(6,  '银行开立基本户',       '财务', '携带营业执照正副本、公章到银行开立对公账户', '', 6),
(7,  '税务登记与税种核定',   '税务', '到税务局完成税务登记，核定税种和税率', 'https://etax.chinatax.gov.cn', 7),
(8,  '社保公积金开户',       '人事', '为员工办理社保登记和公积金缴存开户', '', 8),
(9,  '发票申领',             '财务', '购买税控设备，申领增值税发票', '', 9),
(10, '建立财务制度',         '财务', '制定报销、采购、预算等财务管理制度', '', 10),
(11, '招聘核心团队',         '人事', '发布招聘信息，面试关键岗位人选', '', 11),
(12, '签订劳动合同',         '人事', '与员工签订劳动合同，办理入职手续', '', 12),
(13, '制定公司章程制度',     '行政', '完善公司基本管理制度和员工手册', '', 13),
(14, '行业资质申请评估',     '资质', '根据行业评估所需资质并着手准备材料', '', 14),
(15, '品牌VI设计',          '品牌', '设计公司Logo、名片、宣传册等视觉识别系统', '', 15),
(16, '公司网站/公众号搭建',  '品牌', '注册域名，搭建官网，开通微信公众号', '', 16),
(17, '知识产权规划',         '知产', '梳理核心商标和专利，提交注册申请', '', 17),
(18, '供应商筛选与签约',     '运营', '筛选关键供应商，签订采购协议', '', 18),
(19, '客户关系系统搭建',     '运营', '选择CRM系统，建立客户管理体系', '', 19),
(20, '产品/服务定价方案',    '运营', '完成产品定价、服务套餐设计与定价审批', '', 20),
(21, '营销推广计划',         '市场', '制定线上线下营销推广方案和预算', '', 21),
(22, '办公设备采购',         '行政', '采购电脑、打印机、办公家具等设备', '', 22),
(23, '网络安全与IT部署',    'IT',  '搭建网络环境，配置防火墙、VPN，部署杀毒软件', '', 23),
(24, '消防安全检查',         '安全', '配合消防部门完成经营场所消防安全检查', '', 24),
(25, '环保备案（如需）',     '环保', '完成环境影响登记表备案', '', 25),
(26, '试营业准备',           '运营', '完成产品/服务测试，开展内部试运行', '', 26),
(27, '开业活动策划',         '市场', '策划开业仪式和促销活动方案', '', 27),
(28, '客户预热与邀约',       '市场', '向潜在客户发送开业邀请和优惠信息', '', 28),
(29, '全面复盘检查',         '综合', '逐项核查30天任务清单，查漏补缺', '', 29),
(30, '正式开业',             '综合', '举办开业仪式，宣布公司正式运营', '', 30);
