// ============================================================================
// 政企通 (ZQTong) — Supabase SDK 集成文件
// 使用方式: <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
//           <script src="supabase-client.js"></script>
// ============================================================================

// ---------- Supabase 客户端初始化 -------------------------------------------
const SUPABASE_URL = 'https://rzmfqwsytwlmyfazwpmw.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_cqjmoVwWNrdXP-tQCnFoFQ_JiOxTmNF';
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ============================================================================
// 1. 核心数据查询函数
// ============================================================================

/** 查询惠企政策列表，支持多条件筛选 */
async function fetchPolicies(filters = {}) {
  let query = supabase.from('policies').select('*').eq('is_active', true);
  if (filters.region)       query = query.eq('region', filters.region);
  if (filters.industry)     query = query.eq('industry', filters.industry);
  if (filters.policy_type)  query = query.eq('policy_type', filters.policy_type);
  if (filters.enterprise_scale) query = query.eq('enterprise_scale', filters.enterprise_scale);
  if (filters.search) {
    query = query.or(`title.ilike.%${filters.search}%,description.ilike.%${filters.search}%`);
  }
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('deadline', { ascending: true });
  if (error) { console.error('fetchPolicies error:', error); return []; }
  return data;
}

/** 查询企业服务商列表 */
async function fetchServices(filters = {}) {
  let query = supabase.from('services').select('*').eq('is_active', true);
  if (filters.category) query = query.eq('category', filters.category);
  if (filters.search) {
    query = query.or(`name.ilike.%${filters.search}%,description.ilike.%${filters.search}%`);
  }
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('rating', { ascending: false });
  if (error) { console.error('fetchServices error:', error); return []; }
  return data;
}

/** 查询知识产权项目列表 */
async function fetchIpItems(filters = {}) {
  let query = supabase.from('ip_items').select('*').eq('is_active', true);
  if (filters.category) query = query.eq('category', filters.category);
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('name');
  if (error) { console.error('fetchIpItems error:', error); return []; }
  return data;
}

/** 查询企业软件推荐列表 */
async function fetchSoftware(filters = {}) {
  let query = supabase.from('software_list').select('*').eq('is_active', true);
  if (filters.category) query = query.eq('category', filters.category);
  if (filters.subcategory) query = query.eq('subcategory', filters.subcategory);
  if (filters.search) {
    query = query.or(`name.ilike.%${filters.search}%,description.ilike.%${filters.search}%`);
  }
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('name');
  if (error) { console.error('fetchSoftware error:', error); return []; }
  return data;
}

/** 查询办公房源列表 */
async function fetchOffices(filters = {}) {
  let query = supabase.from('offices').select('*').eq('is_active', true);
  if (filters.region) query = query.eq('region', filters.region);
  if (filters.property_type) query = query.eq('property_type', filters.property_type);
  if (filters.search) {
    query = query.or(`title.ilike.%${filters.search}%,address.ilike.%${filters.search}%`);
  }
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('price_month');
  if (error) { console.error('fetchOffices error:', error); return []; }
  return data;
}

/** 查询证照办理列表 */
async function fetchLicenses(filters = {}) {
  let query = supabase.from('licenses').select('*').eq('is_active', true);
  if (filters.category) query = query.eq('category', filters.category);
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('name');
  if (error) { console.error('fetchLicenses error:', error); return []; }
  return data;
}

/** 查询行业办事指南列表 */
async function fetchGuideIndustries(filters = {}) {
  let query = supabase.from('guide_industries').select('*').eq('is_active', true);
  if (filters.industry) query = query.eq('industry', filters.industry);
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('industry');
  if (error) { console.error('fetchGuideIndustries error:', error); return []; }
  return data;
}

/** 查询新公司必做任务清单 */
async function fetchNewcoTasks(filters = {}) {
  let query = supabase.from('newco_tasks').select('*').eq('is_active', true);
  if (filters.category) query = query.eq('category', filters.category);
  if (filters.day_num) query = query.eq('day_num', filters.day_num);
  if (filters.limit) query = query.limit(filters.limit);
  const { data, error } = await query.order('sort_order');
  if (error) { console.error('fetchNewcoTasks error:', error); return []; }
  return data;
}

// ============================================================================
// 2. 用户认证与档案
// ============================================================================

/** 注册 */
async function signUp(email, password, fullName) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName } }
  });
  if (error) { console.error('signUp error:', error); return { error }; }
  return { user: data.user, session: data.session };
}

/** 登录 */
async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) { console.error('signIn error:', error); return { error }; }
  return { user: data.user, session: data.session };
}

/** 退出 */
async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) console.error('signOut error:', error);
}

/** 获取当前用户 profile */
async function getProfile() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;
  const { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).single();
  if (error) { console.error('getProfile error:', error); return null; }
  return data;
}

/** 获取当前会话 */
function getSession() {
  return supabase.auth.getSession();
}

/** 监听认证状态变化 */
function onAuthStateChange(callback) {
  return supabase.auth.onAuthStateChange(callback);
}

// ============================================================================
// 3. 收藏功能
// ============================================================================

/** 添加收藏 */
async function addFavorite(itemType, itemId) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: '未登录' };
  const { data, error } = await supabase.from('favorites').insert({
    user_id: user.id,
    item_type: itemType,
    item_id: itemId
  });
  if (error) { console.error('addFavorite error:', error); return { error }; }
  return { data };
}

/** 取消收藏 */
async function removeFavorite(itemType, itemId) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: '未登录' };
  const { error } = await supabase.from('favorites')
    .delete()
    .eq('user_id', user.id)
    .eq('item_type', itemType)
    .eq('item_id', itemId);
  if (error) { console.error('removeFavorite error:', error); return { error }; }
  return { success: true };
}

/** 获取用户收藏列表 */
async function getFavorites() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];
  const { data, error } = await supabase.from('favorites').select('*').eq('user_id', user.id);
  if (error) { console.error('getFavorites error:', error); return []; }
  return data;
}

// ============================================================================
// 4. 工单功能
// ============================================================================

/** 提交工单 */
async function submitTicket(title, content, category = '咨询') {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: '未登录' };
  const { data, error } = await supabase.from('tickets').insert({
    user_id: user.id,
    title,
    content,
    category
  });
  if (error) { console.error('submitTicket error:', error); return { error }; }
  return { data };
}

/** 获取我的工单 */
async function getMyTickets() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];
  const { data, error } = await supabase.from('tickets').select('*').eq('user_id', user.id).order('created_at', { ascending: false });
  if (error) { console.error('getMyTickets error:', error); return []; }
  return data;
}

// ============================================================================
// 5. 管理端辅助函数
// ============================================================================

/** 检查当前用户是否为管理员 */
async function checkIsAdmin() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return false;
  const { data, error } = await supabase.from('admin_users').select('*').eq('user_id', user.id).single();
  if (error || !data) return false;
  return true;
}

/** 管理员: 通用列表查询（带分页） */
async function adminFetchAll(tableName, options = {}) {
  let query = supabase.from(tableName).select('*', { count: 'exact' });
  if (options.page && options.pageSize) {
    const from = (options.page - 1) * options.pageSize;
    const to = from + options.pageSize - 1;
    query = query.range(from, to);
  }
  if (options.orderBy) query = query.order(options.orderBy, { ascending: options.ascending ?? true });
  const { data, error, count } = await query;
  if (error) { console.error(`adminFetchAll(${tableName}) error:`, error); return { data: [], count: 0 }; }
  return { data, count };
}

/** 管理员: 新增 */
async function adminInsert(tableName, record) {
  const { data, error } = await supabase.from(tableName).insert(record).select();
  if (error) { console.error(`adminInsert(${tableName}) error:`, error); return { error }; }
  return { data };
}

/** 管理员: 更新 */
async function adminUpdate(tableName, id, updates) {
  const { data, error } = await supabase.from(tableName).update(updates).eq('id', id).select();
  if (error) { console.error(`adminUpdate(${tableName}) error:`, error); return { error }; }
  return { data };
}

/** 管理员: 删除 (软删除) */
async function adminSoftDelete(tableName, id) {
  const { data, error } = await supabase.from(tableName).update({ is_active: false }).eq('id', id).select();
  if (error) { console.error(`adminSoftDelete(${tableName}) error:`, error); return { error }; }
  return { data };
}

// ============================================================================
// 6. 全局导出（供其他脚本使用）
// ============================================================================
if (typeof window !== 'undefined') {
  window.ZQTong = {
    supabase,
    // 核心查询
    fetchPolicies, fetchServices, fetchIpItems, fetchSoftware,
    fetchOffices, fetchLicenses, fetchGuideIndustries, fetchNewcoTasks,
    // 用户认证
    signUp, signIn, signOut, getProfile, getSession, onAuthStateChange,
    // 收藏
    addFavorite, removeFavorite, getFavorites,
    // 工单
    submitTicket, getMyTickets,
    // 管理
    checkIsAdmin, adminFetchAll, adminInsert, adminUpdate, adminSoftDelete
  };
}
