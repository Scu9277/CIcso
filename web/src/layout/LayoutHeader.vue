<template>
  <div class="premium-header">
    <div class="header-left">
      <i @click="toggleClick" :class="is_active ? 'el-icon-s-fold' : 'el-icon-s-unfold'" class="toggle-icon"></i>
      
      <div class="logo-badge">
        <svg viewBox="0 0 24 24" class="logo-svg">
          <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="1.5"/>
          <path d="M12 7 L12 12 L15 15" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
        </svg>
        <span>Scu SSLVPN</span>
      </div>
      
      <div class="breadcrumb-divider"></div>
      
      <el-breadcrumb separator="/" class="breadcrumb">
        <el-breadcrumb-item v-for="(item, index) in route_name" :key="index">{{ item }}</el-breadcrumb-item>
      </el-breadcrumb>
    </div>

    <div class="header-right">
      <el-dropdown trigger="click" @command="handleCommand" class="user-dropdown">
        <div class="user-section">
          <div class="user-avatar">{{ admin_user.charAt(0).toUpperCase() }}</div>
          <span class="user-name">{{ admin_user }}</span>
          <i class="el-icon-caret-bottom"></i>
        </div>
        <el-dropdown-menu slot="dropdown" class="user-menu">
          <el-dropdown-item command="logout">
            <i class="el-icon-switch-button"></i>
            <span>退出登录</span>
          </el-dropdown-item>
        </el-dropdown-menu>
      </el-dropdown>
    </div>
  </div>
</template>

<script>
import {getUser, removeToken} from "@/plugins/token";

export default {
  name: "Layoutheader",
  props: ['route_name'],
  data() {
    return {
      is_active: true
    }
  },
  computed: {
    admin_user() {
      return getUser();
    },
  },
  methods: {
    toggleClick() {
      this.is_active = !this.is_active
      this.$emit('update:is_active', this.is_active)
    },
    handleCommand() {
      removeToken()
      this.$router.push("/login");
    },
  }
}
</script>

<style scoped>
.premium-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 24px;
  height: 100%;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 20px;
}

.toggle-icon {
  font-size: 20px;
  cursor: pointer;
  padding: 8px;
  border-radius: 8px;
  transition: all 0.2s ease;
  color: #666;
}

.toggle-icon:hover {
  background: #f5f5f5;
  color: #2c5aa0;
}

.logo-badge {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 16px 6px 12px;
  background: #2c5aa0;
  border-radius: 8px;
  color: white;
  font-size: 15px;
  font-weight: 600;
}

.logo-svg {
  width: 22px;
  height: 22px;
}

.breadcrumb-divider {
  width: 1px;
  height: 24px;
  background: #e0e0e0;
}

.breadcrumb {
  font-size: 14px;
}

::v-deep .breadcrumb .el-breadcrumb__item {
  font-weight: 400;
}

::v-deep .breadcrumb .el-breadcrumb__inner {
  color: #666;
}

.header-right {
  display: flex;
  align-items: center;
}

.user-dropdown {
  cursor: pointer;
}

.user-section {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 12px;
  border-radius: 8px;
  transition: background 0.2s ease;
}

.user-section:hover {
  background: #f5f5f5;
}

.user-avatar {
  width: 32px;
  height: 32px;
  background: linear-gradient(135deg, #2c5aa0 0%, #1e4276 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 14px;
  font-weight: 600;
}

.user-name {
  font-size: 14px;
  font-weight: 500;
  color: #333;
}

::v-deep .user-menu .el-dropdown-menu__item {
  padding: 12px 20px;
  font-size: 14px;
}

::v-deep .user-menu .el-dropdown-menu__item i {
  margin-right: 8px;
  color: #2c5aa0;
}

::v-deep .user-menu .el-dropdown-menu__item span {
  color: #333;
}
</style>
