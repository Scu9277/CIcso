<template>
  <div class="premium-sidebar" :class="{ collapsed: !is_active }">
    <el-menu 
      :collapse="!is_active" 
      :default-active="route_path" 
      router
      class="sidebar-menu" 
      :collapse-transition="false"
      background-color="#ffffff"
      text-color="#666666"
      active-text-color="#2c5aa0">
      
      <el-menu-item index="/admin/home" class="menu-item">
        <i class="el-icon-s-home menu-icon"></i>
        <span slot="title">首页</span>
      </el-menu-item>

      <el-submenu index="1">
        <template slot="title">
          <i class="el-icon-setting menu-icon"></i>
          <span>基础信息</span>
        </template>
        <el-menu-item index="/admin/set/system">系统信息</el-menu-item>
        <el-menu-item index="/admin/set/soft">软件配置</el-menu-item>
        <el-menu-item index="/admin/set/other">其他设置</el-menu-item>
        <el-menu-item index="/admin/set/audit">审计日志</el-menu-item>
      </el-submenu>

      <el-submenu index="2">
        <template slot="title">
          <i class="el-icon-user menu-icon"></i>
          <span>用户信息</span>
        </template>
        <el-menu-item index="/admin/user/list">用户列表</el-menu-item>
        <el-menu-item index="/admin/user/policy">用户策略</el-menu-item>
        <el-menu-item index="/admin/user/online">在线用户</el-menu-item>
        <el-menu-item index="/admin/user/lockmanager">锁定管理</el-menu-item>
        <el-menu-item index="/admin/user/ip_map">IP映射</el-menu-item>
      </el-submenu>

      <el-submenu index="3">
        <template slot="title">
          <i class="el-icon-s-order menu-icon"></i>
          <span>用户组信息</span>
        </template>
        <el-menu-item index="/admin/group/list">用户组列表</el-menu-item>
      </el-submenu>

      <el-submenu index="4">
        <template slot="title">
          <i class="el-icon-data-analysis menu-icon"></i>
          <span>调试信息</span>
        </template>
        <el-menu-item>
          <a href="/debug/pprof/" target="_blank">pprof</a>
        </el-menu-item>
        <el-menu-item>
          <a href="/debug/statsviz/" target="_blank">statsviz</a>
        </el-menu-item>
      </el-submenu>
    </el-menu>
  </div>
</template>

<script>
export default {
  name: "LayoutAside",
  data() {
    return {}
  },
  props: ['is_active', 'route_path'],
  mounted() {
  }
}
</script>

<style scoped>
.premium-sidebar {
  height: 100%;
  background: white;
  border-right: 1px solid #e8e8e8;
  transition: width 0.3s ease;
}

.sidebar-menu {
  height: 100%;
  border-right: none !important;
  padding: 8px 0;
}

.el-menu-item a {
  display: block;
  color: inherit;
  text-decoration: none;
}

.menu-icon {
  color: #2c5aa0;
  font-size: 18px;
  margin-right: 10px;
}

/* Menu Items */
::v-deep .el-menu-item,
::v-deep .el-submenu__title {
  height: 48px;
  line-height: 48px;
  margin: 2px 12px;
  border-radius: 8px;
  transition: all 0.2s ease;
  font-size: 14px;
}

::v-deep .el-menu-item:hover,
::v-deep .el-submenu__title:hover {
  background-color: #f5f5f5 !important;
  color: #2c5aa0 !important;
}

::v-deep .el-menu-item.is-active {
  background: #2c5aa0 !important;
  color: white !important;
  font-weight: 500;
}

::v-deep .el-menu-item.is-active .menu-icon {
  color: white !important;
}

/* Submenu Items */
::v-deep .el-submenu .el-menu-item {
  min-width: auto;
  padding-left: 56px !important;
  background-color: transparent;
  font-size: 13px;
}

::v-deep .el-submenu .el-menu-item:hover {
  background-color: #f5f5f5 !important;
}

/* Collapsed State */
.collapsed ::v-deep .el-menu-item,
.collapsed ::v-deep .el-submenu__title {
  margin: 2px 4px;
}
</style>
