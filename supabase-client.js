// ============================================================================
// 政企通 (ZQTong) — 纯 fetch + Supabase REST API 实现（零 CDN 依赖）
// ============================================================================

const SUPABASE_URL = 'https://rzmfqwsytwlmyfazwpmw.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_cqjmoVwWNrdXP-tQCnFoFQ_JiOxTmNF';
const REST_BASE = SUPABASE_URL + '/rest/v1/';
const AUTH_BASE = SUPABASE_URL + '/auth/v1/';
const STORAGE_KEY = 'sb-rzmfqwsytwlmyfazwpmw-auth-token';

// ============================================================================
// 0. 内部工具：Session 管理 & REST 请求封装
// ============================================================================

function getStoredSession() {
  try {
    var raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    var session = JSON.parse(raw);
    if (session.expires_at && Date.now() / 1000 > session.expires_at) {
      localStorage.removeItem(STORAGE_KEY);
      return null;
    }
    return session;
  } catch (e) { return null; }
}

function setStoredSession(data) {
  if (!data) { localStorage.removeItem(STORAGE_KEY); return; }
  var session = {
    access_token: data.access_token,
    refresh_token: data.refresh_token,
    expires_at: data.expires_at || (Date.now() / 1000 + (data.expires_in || 3600)),
    user: data.user || null
  };
  localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
  return session;
}

function getAuthHeaders() {
  var headers = {
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': 'Bearer ' + SUPABASE_ANON_KEY,
    'Content-Type': 'application/json'
  };
  var session = getStoredSession();
  if (session && session.access_token) {
    headers['Authorization'] = 'Bearer ' + session.access_token;
  }
  return headers;
}

function restFetch(path, options) {
  options = options || {};
  var headers = getAuthHeaders();
  if (options.headers) {
    for (var k in options.headers) { headers[k] = options.headers[k]; }
  }
  return fetch(REST_BASE + path, {
    method: options.method || 'GET',
    headers: headers,
    body: options.body || undefined
  });
}

// ============================================================================
// 1. 链式查询构建器 (QueryBuilder)
// ============================================================================

function QueryBuilder(table) {
  this._table = table;
  this._select = '*';
  this._filters = [];
  this._order = null;
  this._ascending = true;
  this._limit = null;
  this._rangeFrom = null;
  this._rangeTo = null;
  this._single = false;
  this._method = 'GET';
  this._body = null;
  this._countExact = false;
  this._returning = false;
}

QueryBuilder.prototype = {
  select: function(columns, opts) {
    this._select = columns || '*';
    if (opts && opts.count === 'exact') this._countExact = true;
    return this;
  },
  eq: function(col, val) {
    this._filters.push('and(' + col + '.eq.' + encodeURIComponent(val) + ')');
    return this;
  },
  ilike: function(col, val) {
    this._filters.push('and(' + col + '.ilike.%' + encodeURIComponent(val) + '%)');
    return this;
  },
  or: function(condition) {
    this._filters.push('or(' + condition.replace(/\.ilike\.%(.+?)%/g, '.ilike.%25$1%25') + ')');
    return this;
  },
  order: function(col, opts) {
    this._order = col;
    this._ascending = !(opts && opts.ascending === false);
    return this;
  },
  limit: function(n) {
    this._limit = n;
    return this;
  },
  range: function(from, to) {
    this._rangeFrom = from;
    this._rangeTo = to;
    return this;
  },
  single: function() {
    this._single = true;
    return this;
  },
  insert: function(records) {
    this._method = 'POST';
    this._body = JSON.stringify(Array.isArray(records) ? records : records);
    return this;
  },
  update: function(record) {
    this._method = 'PATCH';
    this._body = JSON.stringify(record);
    return this;
  },
  delete: function() {
    this._method = 'DELETE';
    return this;
  },
  _buildUrl: function() {
    var parts = [this._select ? 'select=' + encodeURIComponent(this._select) : null];
    if (this._filters.length > 0) {
      var combined = this._filters.join(',');
      parts.push(combined);
    }
    if (this._order) {
      parts.push('order=' + this._order + (this._ascending ? '.asc' : '.desc'));
    }
    if (this._limit !== null) parts.push('limit=' + this._limit);
    return this._table + '?' + parts.filter(Boolean).join('&');
  },
  _execute: function() {
    var url = this._buildUrl();
    var headers = {};
    if (this._countExact) headers['Prefer'] = 'count=exact';
    if ((this._method === 'POST' || this._method === 'PATCH') && this._select && this._select !== '*') {
      headers['Prefer'] = (headers['Prefer'] || '') + 'return=representation';
    }
    if (this._rangeFrom !== null && this._rangeTo !== null) {
      headers['Range'] = this._rangeFrom + '-' + this._rangeTo;
    }
    if (this._method === 'POST' || this._method === 'PATCH') {
      headers['Prefer'] = headers['Prefer'] ? headers['Prefer'] + ',return=representation' : 'return=representation';
    }
    return restFetch(url, {
      method: this._method,
      headers: Object.keys(headers).length > 0 ? headers : undefined,
      body: this._body
    }).then(function(res) {
      var count = res.headers.get('content-range') ? parseInt(res.headers.get('content-range').split('/')[1]) : 0;
      if (res.status === 204 || res.headers.get('content-length') === '0') {
        var result = { data: null, error: null };
        if (count) result.count = count;
        return result;
      }
      return res.json().then(function(data) {
        if (!res.ok) return { data: null, error: data, count: count };
        if (this._single && Array.isArray(data)) {
          return { data: data.length > 0 ? data[0] : null, error: null, count: count };
        }
        var result = { data: data, error: null };
        if (count) result.count = count;
        return result;
      }.bind(this)).catch(function() {
        return { data: null, error: { message: 'JSON parse error', status: res.status }, count: count };
      });
    }.bind(this)).catch(function(err) {
      return { data: null, error: { message: err.message || 'Network error' } };
    });
  },
  then: function(onFulfilled, onRejected) {
    return this._execute().then(onFulfilled, onRejected);
  }
};

// ============================================================================
// 2. Auth 模块
// ============================================================================

var authStateCallbacks = [];

function notifyAuthChange(event, session) {
  authStateCallbacks.forEach(function(cb) { try { cb(event, session); } catch(e) {} });
}

function parseAuthUser(data) {
  if (!data) return null;
  return {
    id: data.id,
    email: data.email,
    phone: data.phone,
    user_metadata: data.user_metadata || (data.raw_user_meta_data || {}),
    app_metadata: data.app_metadata || {},
    created_at: data.created_at,
    aud: data.aud || 'authenticated',
    role: data.role || 'authenticated'
  };
}

function buildSession(tokenData) {
  return {
    access_token: tokenData.access_token,
    refresh_token: tokenData.refresh_token,
    expires_at: tokenData.expires_at || (Date.now() / 1000 + (tokenData.expires_in || 3600)),
    expires_in: tokenData.expires_in || 3600,
    token_type: 'bearer',
    user: parseAuthUser(tokenData.user)
  };
}

var supabaseAuth = {
  signUp: function(params) {
    var body = {
      email: params.email,
      password: params.password
    };
    if (params.options && params.options.data) {
      body.data = params.options.data;
    }
    return fetch(AUTH_BASE + 'signup', {
      method: 'POST',
      headers: { 'apikey': SUPABASE_ANON_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(function(res) {
      return res.json().then(function(data) {
        if (!res.ok) return { data: null, error: data };
        if (data.access_token) {
          setStoredSession(data);
          var session = buildSession(data);
          notifyAuthChange('SIGNED_IN', session);
          return { data: { user: session.user, session: session }, error: null };
        }
        return { data: { user: parseAuthUser(data), session: null }, error: null };
      });
    }).catch(function(err) {
      return { data: null, error: { message: err.message || 'Network error' } };
    });
  },

  signInWithPassword: function(params) {
    return fetch(AUTH_BASE + 'token?grant_type=password', {
      method: 'POST',
      headers: { 'apikey': SUPABASE_ANON_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: params.email, password: params.password })
    }).then(function(res) {
      return res.json().then(function(data) {
        if (!res.ok) return { data: null, error: data };
        setStoredSession(data);
        var session = buildSession(data);
        notifyAuthChange('SIGNED_IN', session);
        return { data: { user: session.user, session: session }, error: null };
      });
    }).catch(function(err) {
      return { data: null, error: { message: err.message || 'Network error' } };
    });
  },

  signOut: function() {
    var session = getStoredSession();
    var token = session ? session.access_token : null;
    localStorage.removeItem(STORAGE_KEY);
    notifyAuthChange('SIGNED_OUT', null);
    if (!token) return Promise.resolve({ error: null });
    return fetch(AUTH_BASE + 'logout', {
      method: 'POST',
      headers: { 'apikey': SUPABASE_ANON_KEY, 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' }
    }).then(function() {
      return { error: null };
    }).catch(function() {
      return { error: null };
    });
  },

  getUser: function() {
    var session = getStoredSession();
    if (!session || !session.user) {
      return Promise.resolve({ data: { user: null }, error: null });
    }
    var token = session.access_token;
    return fetch(AUTH_BASE + 'user', {
      method: 'GET',
      headers: { 'apikey': SUPABASE_ANON_KEY, 'Authorization': 'Bearer ' + token }
    }).then(function(res) {
      return res.json().then(function(data) {
        if (!res.ok) return { data: { user: null }, error: data };
        return { data: { user: parseAuthUser(data) }, error: null };
      });
    }).catch(function() {
      if (session && session.user) return { data: { user: session.user }, error: null };
      return { data: { user: null }, error: { message: 'Network error' } };
    });
  },

  getSession: function() {
    var session = getStoredSession();
    if (!session) return { data: { session: null }, error: null };
    return { data: { session: session }, error: null };
  },

  onAuthStateChange: function(callback) {
    authStateCallbacks.push(callback);
    return {
      data: {
        subscription: {
          unsubscribe: function() {
            var idx = authStateCallbacks.indexOf(callback);
            if (idx >= 0) authStateCallbacks.splice(idx, 1);
          }
        }
      }
    };
  }
};

// ============================================================================
// 3. Supabase 客户端封装（兼容原 supabase.createClient 返回结构）
// ============================================================================

var supabase = {
  auth: supabaseAuth,
  from: function(table) {
    return new QueryBuilder(table);
  }
};

// ============================================================================
// 4. 核心数据查询函数
// ============================================================================

async function fetchPolicies(filters) {
  filters = filters || {};
  var q = supabase.from('policies').select('*').eq('is_active', true);
  if (filters.region)       q = q.eq('region', filters.region);
  if (filters.industry)     q = q.eq('industry', filters.industry);
  if (filters.policy_type)  q = q.eq('policy_type', filters.policy_type);
  if (filters.enterprise_scale) q = q.eq('enterprise_scale', filters.enterprise_scale);
  if (filters.search) {
    q = q.or('title.ilike.%' + filters.search + '%,description.ilike.%' + filters.search + '%');
  }
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'deadline';
  q._ascending = true;
  var result = await q;
  if (result.error) { console.error('fetchPolicies error:', result.error); return []; }
  return result.data;
}

async function fetchServices(filters) {
  filters = filters || {};
  var q = supabase.from('services').select('*').eq('is_active', true);
  if (filters.category) q = q.eq('category', filters.category);
  if (filters.search) {
    q = q.or('name.ilike.%' + filters.search + '%,description.ilike.%' + filters.search + '%');
  }
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'rating';
  q._ascending = false;
  var result = await q;
  if (result.error) { console.error('fetchServices error:', result.error); return []; }
  return result.data;
}

async function fetchIpItems(filters) {
  filters = filters || {};
  var q = supabase.from('ip_items').select('*').eq('is_active', true);
  if (filters.category) q = q.eq('category', filters.category);
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'name';
  q._ascending = true;
  var result = await q;
  if (result.error) { console.error('fetchIpItems error:', result.error); return []; }
  return result.data;
}

async function fetchSoftware(filters) {
  filters = filters || {};
  var q = supabase.from('software_list').select('*').eq('is_active', true);
  if (filters.category) q = q.eq('category', filters.category);
  if (filters.subcategory) q = q.eq('subcategory', filters.subcategory);
  if (filters.search) {
    q = q.or('name.ilike.%' + filters.search + '%,description.ilike.%' + filters.search + '%');
  }
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'name';
  q._ascending = true;
  var result = await q;
  if (result.error) { console.error('fetchSoftware error:', result.error); return []; }
  return result.data;
}

async function fetchOffices(filters) {
  filters = filters || {};
  var q = supabase.from('offices').select('*').eq('is_active', true);
  if (filters.region) q = q.eq('region', filters.region);
  if (filters.property_type) q = q.eq('property_type', filters.property_type);
  if (filters.search) {
    q = q.or('title.ilike.%' + filters.search + '%,address.ilike.%' + filters.search + '%');
  }
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'price_month';
  q._ascending = true;
  var result = await q;
  if (result.error) { console.error('fetchOffices error:', result.error); return []; }
  return result.data;
}

async function fetchLicenses(filters) {
  filters = filters || {};
  var q = supabase.from('licenses').select('*').eq('is_active', true);
  if (filters.category) q = q.eq('category', filters.category);
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'name';
  q._ascending = true;
  var result = await q;
  if (result.error) { console.error('fetchLicenses error:', result.error); return []; }
  return result.data;
}

async function fetchGuideIndustries(filters) {
  filters = filters || {};
  var q = supabase.from('guide_industries').select('*').eq('is_active', true);
  if (filters.industry) q = q.eq('industry', filters.industry);
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'industry';
  q._ascending = true;
  var result = await q;
  if (result.error) { console.error('fetchGuideIndustries error:', result.error); return []; }
  return result.data;
}

async function fetchNewcoTasks(filters) {
  filters = filters || {};
  var q = supabase.from('newco_tasks').select('*').eq('is_active', true);
  if (filters.category) q = q.eq('category', filters.category);
  if (filters.day_num) q = q.eq('day_num', filters.day_num);
  if (filters.limit) q = q.limit(filters.limit);
  q._order = 'sort_order';
  q._ascending = true;
  var result = await q;
  if (result.error) { console.error('fetchNewcoTasks error:', result.error); return []; }
  return result.data;
}

// ============================================================================
// 5. 用户认证与档案
// ============================================================================

async function signUp(email, password, fullName) {
  var result = await supabase.auth.signUp({
    email: email,
    password: password,
    options: { data: { full_name: fullName } }
  });
  if (result.error) { console.error('signUp error:', result.error); return { error: result.error }; }
  return { user: result.data.user, session: result.data.session };
}

async function signIn(email, password) {
  var result = await supabase.auth.signInWithPassword({ email: email, password: password });
  if (result.error) { console.error('signIn error:', result.error); return { error: result.error }; }
  return { user: result.data.user, session: result.data.session };
}

async function signOut() {
  var result = await supabase.auth.signOut();
  if (result.error) console.error('signOut error:', result.error);
}

async function getProfile() {
  var userResult = await supabase.auth.getUser();
  var user = userResult.data && userResult.data.user;
  if (!user) return null;
  var result = await supabase.from('profiles').select('*').eq('id', user.id).single();
  if (result.error) { console.error('getProfile error:', result.error); return null; }
  return result.data;
}

function getSession() {
  return supabase.auth.getSession();
}

function onAuthStateChange(callback) {
  return supabase.auth.onAuthStateChange(callback);
}

// ============================================================================
// 6. 收藏功能
// ============================================================================

async function addFavorite(itemType, itemId) {
  var userResult = await supabase.auth.getUser();
  var user = userResult.data && userResult.data.user;
  if (!user) return { error: '未登录' };
  var result = await supabase.from('favorites').insert({
    user_id: user.id,
    item_type: itemType,
    item_id: itemId
  });
  if (result.error) { console.error('addFavorite error:', result.error); return { error: result.error }; }
  return { data: result.data };
}

async function removeFavorite(itemType, itemId) {
  var userResult = await supabase.auth.getUser();
  var user = userResult.data && userResult.data.user;
  if (!user) return { error: '未登录' };
  var result = await supabase.from('favorites')
    .delete()
    .eq('user_id', user.id)
    .eq('item_type', itemType)
    .eq('item_id', itemId);
  if (result.error) { console.error('removeFavorite error:', result.error); return { error: result.error }; }
  return { success: true };
}

async function getFavorites() {
  var userResult = await supabase.auth.getUser();
  var user = userResult.data && userResult.data.user;
  if (!user) return [];
  var result = await supabase.from('favorites').select('*').eq('user_id', user.id);
  if (result.error) { console.error('getFavorites error:', result.error); return []; }
  return result.data;
}

// ============================================================================
// 7. 工单功能
// ============================================================================

async function submitTicket(title, content, category) {
  category = category || '咨询';
  var userResult = await supabase.auth.getUser();
  var user = userResult.data && userResult.data.user;
  if (!user) return { error: '未登录' };
  var result = await supabase.from('tickets').insert({
    user_id: user.id,
    title: title,
    content: content,
    category: category
  });
  if (result.error) { console.error('submitTicket error:', result.error); return { error: result.error }; }
  return { data: result.data };
}

async function getMyTickets() {
  var userResult = await supabase.auth.getUser();
  var user = userResult.data && userResult.data.user;
  if (!user) return [];
  var q = supabase.from('tickets').select('*').eq('user_id', user.id);
  q._order = 'created_at';
  q._ascending = false;
  var result = await q;
  if (result.error) { console.error('getMyTickets error:', result.error); return []; }
  return result.data;
}

// ============================================================================
// 8. 管理端辅助函数
// ============================================================================

async function checkIsAdmin() {
  var userResult = await supabase.auth.getUser();
  var user = userResult.data && userResult.data.user;
  if (!user) return false;
  var result = await supabase.from('admin_users').select('*').eq('user_id', user.id).single();
  if (result.error || !result.data) return false;
  return true;
}

async function adminFetchAll(tableName, options) {
  options = options || {};
  var q = supabase.from(tableName).select('*');
  if (options.countExact !== false) q._countExact = true;
  if (options.page && options.pageSize) {
    var from = (options.page - 1) * options.pageSize;
    var to = from + options.pageSize - 1;
    q = q.range(from, to);
  }
  if (options.orderBy) {
    q._order = options.orderBy;
    q._ascending = options.ascending !== undefined ? options.ascending : true;
  }
  var result = await q;
  if (result.error) { console.error('adminFetchAll(' + tableName + ') error:', result.error); return { data: [], count: 0 }; }
  return { data: result.data, count: result.count || 0 };
}

async function adminInsert(tableName, record) {
  var result = await supabase.from(tableName).insert(record);
  if (result.error) { console.error('adminInsert(' + tableName + ') error:', result.error); return { error: result.error }; }
  return { data: result.data };
}

async function adminUpdate(tableName, id, updates) {
  var result = await supabase.from(tableName).update(updates).eq('id', id);
  if (result.error) { console.error('adminUpdate(' + tableName + ') error:', result.error); return { error: result.error }; }
  return { data: result.data };
}

async function adminSoftDelete(tableName, id) {
  var result = await supabase.from(tableName).update({ is_active: false }).eq('id', id);
  if (result.error) { console.error('adminSoftDelete(' + tableName + ') error:', result.error); return { error: result.error }; }
  return { data: result.data };
}

// ============================================================================
// 9. 全局导出（供其他脚本使用）
// ============================================================================
if (typeof window !== 'undefined') {
  window.ZQTong = {
    supabase: supabase,
    fetchPolicies: fetchPolicies,
    fetchServices: fetchServices,
    fetchIpItems: fetchIpItems,
    fetchSoftware: fetchSoftware,
    fetchOffices: fetchOffices,
    fetchLicenses: fetchLicenses,
    fetchGuideIndustries: fetchGuideIndustries,
    fetchNewcoTasks: fetchNewcoTasks,
    signUp: signUp,
    signIn: signIn,
    signOut: signOut,
    getProfile: getProfile,
    getSession: getSession,
    onAuthStateChange: onAuthStateChange,
    addFavorite: addFavorite,
    removeFavorite: removeFavorite,
    getFavorites: getFavorites,
    submitTicket: submitTicket,
    getMyTickets: getMyTickets,
    checkIsAdmin: checkIsAdmin,
    adminFetchAll: adminFetchAll,
    adminInsert: adminInsert,
    adminUpdate: adminUpdate,
    adminSoftDelete: adminSoftDelete
  };
}
